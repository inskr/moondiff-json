import assert from 'node:assert/strict';
import { AnalysisRunner } from '../web/runner.js';

// The worker boundary is controlled; all request state, timers and acceptance run
// in the actual production runner. Late callbacks deliberately survive terminate.
class ControlledWorker {
  listeners = new Map();
  sent = [];
  terminated = false;
  addEventListener(type, callback) { this.listeners.set(type, callback); }
  postMessage(message) { this.sent.push(message); }
  terminate() { this.terminated = true; }
  emit(data) { this.listeners.get('message')?.({ data }); }
  crash() { this.listeners.get('error')?.({ message: 'controlled worker crash', preventDefault() {} }); }
}
const tests = [];
function test(name, run) { tests.push({ name, run }); }
function setup(timeoutMs = 5000) {
  const workers = [], states = [], reports = [], readiness = [];
  const runner = new AnalysisRunner({
    createWorker: () => { const w = new ControlledWorker(); workers.push(w); return w; },
    timeoutMs,
    onState: s => states.push(s),
    onReport: (text, id) => reports.push({ text, id }),
    onReady: ready => readiness.push(ready),
  });
  assert.equal(workers.length, 1, 'Core should preload in one worker');
  return { runner, workers, states, reports, readiness };
}
const input = { type: 'analyze', old_text: '9007199254740992', new_text: '9007199254740993', options_text: '{}' };
test('original strings reach the worker; only current ID is accepted', () => {
  const h = setup();
  try {
    const id = h.runner.start(input);
    assert.deepEqual(h.workers[0].sent[0], { ...input, request_id: id });
    h.workers[0].emit({ type: 'result', request_id: id - 1, report_text: 'stale' });
    assert.equal(h.reports.length, 0);
    assert.equal(h.states.at(-1).status, 'running');
    h.workers[0].emit({ type: 'result', request_id: id, report_text: 'exact report bytes' });
    assert.deepEqual(h.reports, [{ text: 'exact report bytes', id }]);
    assert.equal(h.states.at(-1).status, 'complete');
  } finally { h.runner.close(); }
});
test('superseded worker cannot publish even with the current ID', () => {
  const h = setup();
  try {
    const old = h.runner.start(input);
    const next = h.runner.start({ ...input, new_text: '1' });
    assert.ok(next > old);
    assert.equal(h.workers[0].terminated, true);
    h.workers[0].emit({ type: 'result', request_id: next, report_text: 'wrong worker' });
    h.workers[0].emit({ type: 'result', request_id: old, report_text: 'late old result' });
    assert.equal(h.reports.length, 0);
    h.workers[1].emit({ type: 'result', request_id: next, report_text: 'new result' });
    assert.deepEqual(h.reports, [{ text: 'new result', id: next }]);
  } finally { h.runner.close(); }
});
test('cancel terminates work, rejects late callbacks and rebuilds on next run', () => {
  const h = setup();
  try {
    const id = h.runner.start(input);
    h.runner.cancel();
    assert.equal(h.workers[0].terminated, true);
    assert.equal(h.states.at(-1).status, 'cancelled');
    h.workers[0].emit({ type: 'result', request_id: id, report_text: 'late' });
    assert.equal(h.reports.length, 0);
    const next = h.runner.start(input);
    assert.ok(next > id);
    h.workers[1].emit({ type: 'result', request_id: next, report_text: 'recovered' });
    assert.equal(h.reports.at(-1).text, 'recovered');
  } finally { h.runner.close(); }
});
test('timeout terminates work and does not manufacture a core report', async () => {
  const h = setup(25);
  try {
    const id = h.runner.start(input);
    await new Promise(resolve => setTimeout(resolve, 60));
    assert.equal(h.states.at(-1).code, 'WORKER_TIMEOUT');
    assert.equal(h.workers[0].terminated, true);
    assert.equal(h.reports.length, 0);
    h.workers[0].emit({ type: 'result', request_id: id, report_text: 'late after timeout' });
    assert.equal(h.reports.length, 0);
    const next = h.runner.start(input);
    h.workers[1].emit({ type: 'result', request_id: next, report_text: 'recovered' });
    assert.equal(h.reports.at(-1).text, 'recovered');
  } finally { h.runner.close(); }
});
test('worker failure stays a visible runtime error and permits recovery', () => {
  const h = setup();
  try {
    h.runner.start(input);
    h.workers[0].crash();
    assert.equal(h.states.at(-1).code, 'WORKER_ERROR');
    assert.equal(h.reports.length, 0);
    const id = h.runner.start(input);
    h.workers[1].emit({ type: 'result', request_id: id, report_text: 'recovered' });
    assert.equal(h.reports.at(-1).text, 'recovered');
  } finally { h.runner.close(); }
});
test('idle worker is reused for offline comparisons and stale error callbacks are ignored', async () => {
  const h = setup(25);
  try {
    h.workers[0].emit({ type: 'ready' });
    assert.equal(h.readiness.at(-1), true);
    const first = h.runner.start(input);
    h.workers[0].emit({ type: 'result', request_id: first, report_text: 'one' });
    h.runner.cancel(); // Draft edit while idle must keep the loaded worker.
    const next = h.runner.start(input);
    assert.equal(h.workers.length, 1);
    h.workers[0].emit({ type: 'failure', request_id: first, message: 'stale error' });
    assert.equal(h.states.at(-1).status, 'running');
    h.workers[0].emit({ type: 'result', request_id: next, report_text: 'two' });
    await new Promise(resolve => setTimeout(resolve, 60));
    assert.equal(h.states.at(-1).status, 'complete');
    assert.deepEqual(h.reports.map(r => r.text), ['one', 'two']);
  } finally { h.runner.close(); }
});
test('closing the page invalidates work and closes its worker', () => {
  const h = setup();
  const id = h.runner.start(input);
  h.runner.close();
  assert.equal(h.workers[0].terminated, true);
  h.workers[0].emit({ type: 'result', request_id: id, report_text: 'after page close' });
  assert.equal(h.reports.length, 0);
});
let failed = 0;
for (const { name, run } of tests) {
  try { await run(); console.log(`PASS ${name}`); }
  catch (error) { failed++; console.error(`FAIL ${name}: ${error.message}`); }
}
console.log(`Worker runner: ${tests.length - failed}/${tests.length} passed, ${failed} failed (${process.version}).`);
process.exitCode = failed === 0 ? 0 : 1;
