import assert from 'node:assert/strict';
import { spawn, spawnSync } from 'node:child_process';
import { access, mkdir, readFile, writeFile } from 'node:fs/promises';
import { cpus, release } from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { chromium } from 'playwright-core';
import { analyze } from '../dist/moondiff-json.mjs';

const root = fileURLToPath(new URL('../', import.meta.url));
const output = path.join(root, 'output', 'playwright');
const work = path.join(root, 'work', 'web-smoke');
await mkdir(output, { recursive: true });
await mkdir(work, { recursive: true });
const reports = JSON.parse(await readFile(path.join(root, 'fixtures/reports/cases.json'), 'utf8'));
const errors = JSON.parse(await readFile(path.join(root, 'fixtures/errors/cases.json'), 'utf8'));
const server = spawn(process.execPath, ['scripts/serve.mjs'], { cwd: root, windowsHide: true, stdio: ['ignore', 'pipe', 'pipe'] });
let browser;
const tests = [], evidence = [], requests = [];
const red = process.argv.some(arg => arg.startsWith('--red'));
let base;
function test(name, run) { tests.push({ name, run }); }
async function download(page) {
  await page.waitForFunction(() => !document.querySelector('#download').disabled, null, { timeout: red ? 1500 : 8000 });
  const event = page.waitForEvent('download');
  await page.locator('#download').click();
  const file = await event;
  assert.equal(await file.failure(), null);
  return readFile(await file.path(), 'utf8');
}
async function fill(page, c) {
  await page.locator('#old-text').fill(c.old);
  await page.locator('#new-text').fill(c.new);
  await page.locator('#options-text').fill(c.options ?? '{}');
}
async function compare(page, c) {
  await fill(page, c);
  await page.locator('#compare').click();
  return download(page);
}
async function withPage(run, { source, viewport = { width: 1440, height: 1000 } } = {}) {
  const context = await browser.newContext({ viewport, acceptDownloads: true });
  context.setDefaultTimeout(red ? 1500 : 8000);
  if (source) await context.route('**/web/worker.js', async route => route.fulfill({ contentType: 'text/javascript', body: typeof source === 'function' ? source() : source }));
  const page = await context.newPage();
  const pageErrors = [];
  page.on('pageerror', error => pageErrors.push(error.message));
  context.on('request', request => requests.push({ url: request.url(), method: request.method() }));
  try {
    await page.goto(base);
    await run(page, context);
    assert.deepEqual(pageErrors, [], 'No uncaught page error');
  } finally { await context.close(); }
}
function controlledWorker(handler) {
  return `import { analyze } from '/dist/moondiff-json.mjs';\npostMessage({type:'ready'});\nonmessage = ({data:d}) => { ${handler} };`;
}
const stalledWorker = controlledWorker(`if(d.old_text==='0') return; postMessage({type:'result',request_id:d.request_id,report_text:analyze(d.old_text,d.new_text,d.options_text)});`);

for (const [i, c] of [...reports, ...errors].entries()) {
  test(`golden download/bridge/CLI: ${c.name}`, () => withPage(async page => {
    const actual = await compare(page, c);
    const expected = c.report ? JSON.stringify(c.report) : analyze(c.old, c.new, c.options);
    assert.equal(actual, expected, 'Download must preserve the entire raw report, including exact numbers');
    const old = path.join(work, `${i}-old.json`), next = path.join(work, `${i}-new.json`), options = path.join(work, `${i}-options.json`);
    await writeFile(old, c.old); await writeFile(next, c.new); await writeFile(options, c.options);
    const cli = spawnSync(process.execPath, [path.join(root, 'cli/moondiff-json.mjs'), old, next, '--options', options, '--format', 'json'], { encoding: 'utf8', windowsHide: true });
    assert.ifError(cli.error);
    const envelope = JSON.parse(expected);
    assert.equal(cli.status, envelope.ok ? (envelope.equal ? 0 : 1) : 2);
    assert.equal(actual, cli.stdout);
    if (!envelope.ok) {
      assert.equal(await page.locator('#error-panel').isVisible(), true);
      assert.ok((await page.locator('#error-title').textContent()).includes(envelope.error.code));
    }
    evidence.push({ name: c.name, report: actual });
  }));
}
for (const [name, index] of [['config', 0], ['api', 1], ['precision', 3], ['identity-error', 6]]) {
  test(`demonstration button: ${name}`, () => withPage(async page => {
    await page.locator(`[data-example="${name}"]`).click();
    assert.equal(await page.locator('#download').isDisabled(), true, 'Loading a sample must not compare implicitly');
    await page.locator('#compare').click();
    assert.equal(await download(page), JSON.stringify(reports[index].report));
    if (name === 'config' || name === 'api') {
      await page.screenshot({ path: path.join(output, `task7-${name}-desktop.png`), fullPage: true });
    }
    if (name === 'api') {
      assert.ok((await page.locator('#changes').textContent()).includes('/users/1/quota'));
      assert.ok((await page.locator('#changes').textContent()).includes('/users/2/quota'));
      assert.ok((await page.locator('#applied-options').textContent()).includes('array_rules'));
    }
  }));
}
test('filter changes only the view; absent and null remain distinct', () => withPage(async page => {
  const report = await compare(page, reports[4]);
  assert.equal(await page.locator('#changes > li').count(), 2);
  assert.ok((await page.locator('#changes').textContent()).includes('<absent>'));
  assert.ok((await page.locator('#changes').textContent()).includes('null'));
  await page.locator('#filter-kind').selectOption('removed');
  assert.equal(await page.locator('#changes > li').count(), 1);
  assert.equal(await page.locator('#count-added').textContent(), '1');
  assert.equal(await page.locator('#count-removed').textContent(), '1');
  assert.equal(await download(page), report);
  await page.locator('#filter-kind').selectOption('modified');
  assert.equal(await page.locator('#changes > li').count(), 0);
  assert.equal(await page.locator('#empty-result').isVisible(), true);
}));
test('editing any draft invalidates old report and download', () => withPage(async page => {
  await compare(page, reports[3]);
  await page.locator('#options-text').fill('{"ignore_paths":[]}');
  assert.equal(await page.locator('#download').isDisabled(), true);
  assert.equal(await page.locator('#results').isVisible(), false);
  assert.equal(await page.locator('#status').getAttribute('data-state'), 'dirty');
}));
test('pagination labels its range and downloads all changes', () => withPage(async page => {
  const old = '[' + Array(101).fill('0').join(',') + ']';
  const next = '[' + Array(101).fill('1').join(',') + ']';
  const report = await compare(page, { old, new: next });
  assert.equal(await page.locator('#count-modified').textContent(), '101');
  assert.equal(await page.locator('#changes > li').count(), 100);
  assert.ok((await page.locator('#visible-count').textContent()).includes('101'));
  await page.locator('#next').click();
  assert.equal(await page.locator('#changes > li').count(), 1);
  assert.ok((await page.locator('#changes').textContent()).includes('/100'));
  assert.equal(await download(page), report);
  assert.equal(JSON.parse(report).changes.length, 101);
}));
test('long Chinese values render as text at a narrow viewport', () => withPage(async page => {
  const value = '</pre><img src=x onerror="window.injected=1">中文🌙' + '长'.repeat(5000);
  const c = { old: 'null', new: JSON.stringify(value) };
  const report = await compare(page, c);
  assert.equal(report, analyze(c.old, c.new));
  assert.equal(await page.locator('#changes img').count(), 0);
  assert.equal(await page.evaluate(() => window.injected), undefined);
  assert.ok((await page.locator('#changes').textContent()).includes(value.slice(-500)));
  assert.equal(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth + 1), true, 'No horizontal page overflow at 390 px');
  await page.screenshot({ path: path.join(output, 'task7-narrow.png'), fullPage: true });
}, { viewport: { width: 390, height: 844 } }));
test('file imports preserve UTF-8, one BOM and large numeric tokens', () => withPage(async page => {
  const c = { old: '\uFEFF9007199254740992', new: '\uFEFF9007199254740993', options: '\uFEFF{}' };
  for (const side of ['old', 'new', 'options']) {
    await page.locator(`#${side}-file`).setInputFiles({ name: `${side} 中文.json`, mimeType: 'application/json', buffer: Buffer.from(c[side]) });
    await page.waitForFunction(({ side, text }) => document.querySelector(`#${side}-text`).value === text, { side, text: c[side] });
  }
  await page.locator('#compare').click();
  assert.equal(await download(page), analyze(c.old, c.new, c.options));
}));
for (const side of ['old', 'new', 'options']) {
  test(`invalid UTF-8 ${side} file stays an error until replaced`, () => withPage(async page => {
    await fill(page, { old: '1', new: '1' });
    await page.locator(`#${side}-file`).setInputFiles({ name: 'invalid.json', mimeType: 'application/json', buffer: Buffer.from([0xc3, 0x28]) });
    const report = JSON.parse(await download(page));
    assert.equal(report.ok, false);
    assert.equal(report.error.code, 'ENCODING_ERROR');
    assert.equal(report.error.side, side);
    assert.equal(report.error.path, null);
    await page.locator('#compare').click();
    assert.equal(JSON.parse(await download(page)).error.code, 'ENCODING_ERROR');
    await page.locator(`#${side}-text`).fill(side === 'options' ? '{}' : '1');
    await page.locator('#compare').click();
    assert.equal(JSON.parse(await download(page)).equal, true);
  }));
}
test('a late file read cannot overwrite a newer text edit', () => withPage(async page => {
  await page.evaluate(() => {
    const read = File.prototype.arrayBuffer;
    File.prototype.arrayBuffer = async function () {
      const bytes = await read.call(this);
      if (this.name === 'slow.json') await new Promise(resolve => setTimeout(resolve, 200));
      return bytes;
    };
  });
  await page.locator('#old-file').setInputFiles({ name: 'slow.json', mimeType: 'application/json', buffer: Buffer.from('0') });
  assert.equal(await page.locator('#compare').isDisabled(), true, 'Pending file read must block comparison');
  await page.locator('#old-text').fill('2');
  await page.waitForTimeout(300);
  assert.equal(await page.locator('#old-text').inputValue(), '2');
  assert.equal(await page.locator('#compare').isDisabled(), false);
}));
test('stale same-worker ID is ignored before the valid result arrives', () => withPage(async page => {
  await page.waitForFunction(() => document.querySelector('#engine').dataset.ready === 'true');
  await fill(page, { old: '1', new: '1' });
  await page.locator('#compare').click();
  await page.waitForTimeout(100);
  assert.equal(await page.locator('#status').getAttribute('data-state'), 'busy');
  assert.equal(await page.locator('#error-panel').isVisible(), false);
  assert.equal(await page.locator('#download').isDisabled(), true);
  assert.equal(JSON.parse(await download(page)).equal, true);
}, { source: controlledWorker(`postMessage({type:'result',request_id:d.request_id-1,report_text:'not JSON'}); setTimeout(()=>postMessage({type:'result',request_id:d.request_id,report_text:analyze(d.old_text,d.new_text,d.options_text)}),400);`) }));
test('new comparison terminates old work and accepts only its replacement', async () => {
  let count = 0;
  await withPage(async page => {
    await page.waitForFunction(() => document.querySelector('#engine').dataset.ready === 'true');
    const original = page.workers()[0];
    let closed = false; original.on('close', () => { closed = true; });
    await fill(page, { old: '0', new: '0' });
    await page.locator('#compare').click();
    await page.locator('#compare').click();
    assert.equal(JSON.parse(await download(page)).equal, true);
    assert.equal(closed, true);
  }, { source: () => ++count === 1 ? stalledWorker : controlledWorker(`postMessage({type:'result',request_id:d.request_id,report_text:analyze(d.old_text,d.new_text,d.options_text)});`) });
});
test('cancel terminates a real Worker and permits a new comparison', () => withPage(async page => {
  await page.waitForFunction(() => document.querySelector('#engine').dataset.ready === 'true');
  const original = page.workers()[0];
  let closed = false; original.on('close', () => { closed = true; });
  await fill(page, { old: '0', new: '0' });
  await page.locator('#compare').click();
  await page.locator('#cancel').click();
  await page.waitForTimeout(50);
  assert.equal(closed, true);
  assert.equal(await page.locator('#status').getAttribute('data-state'), 'cancelled');
  assert.equal(await page.locator('#download').isDisabled(), true);
  assert.equal(JSON.parse(await compare(page, { old: '1', new: '1' })).equal, true);
}, { source: stalledWorker }));
test('real 5-second timeout terminates work, shows a runtime error, then recovers', () => withPage(async page => {
  await page.waitForFunction(() => document.querySelector('#engine').dataset.ready === 'true');
  const original = page.workers()[0];
  let closed = false; original.on('close', () => { closed = true; });
  await fill(page, { old: '0', new: '0' });
  const start = performance.now();
  await page.locator('#compare').click();
  await page.waitForFunction(() => document.querySelector('#error-title').textContent.includes('WORKER_TIMEOUT'), null, { timeout: 8500 });
  const elapsed = performance.now() - start;
  assert.ok(elapsed >= 4900 && elapsed < 8500, `Actual timeout elapsed ${elapsed} ms`);
  assert.equal(closed, true);
  assert.equal(await page.locator('#download').isDisabled(), true, 'Timeout is not a core report');
  assert.equal(JSON.parse(await compare(page, { old: '1', new: '1' })).equal, true);
  evidence.push({ name: 'real timeout', elapsed_ms: elapsed, controlled_worker: true });
}, { source: stalledWorker }));
test('unexpected Worker failure is visible and can recover', () => withPage(async page => {
  await fill(page, { old: '0', new: '0' });
  await page.locator('#compare').click();
  await page.waitForFunction(() => document.querySelector('#error-title').textContent.includes('WORKER_ERROR'));
  assert.equal(await page.locator('#download').isDisabled(), true);
  assert.equal(JSON.parse(await compare(page, { old: '1', new: '1' })).equal, true);
}, { source: controlledWorker(`if(d.old_text==='0') {postMessage({type:'failure',request_id:d.request_id,message:'controlled internal failure'});return;} postMessage({type:'result',request_id:d.request_id,report_text:analyze(d.old_text,d.new_text,d.options_text)});`) }));
test('three demo reports compare and download while browser networking is offline', () => withPage(async (page, context) => {
  await page.waitForFunction(() => document.querySelector('#engine').dataset.ready === 'true');
  await context.setOffline(true);
  for (const i of [0, 1, 3]) {
    const report = await compare(page, reports[i]);
    assert.equal(report, JSON.stringify(reports[i].report));
  }
  evidence.push({ name: 'offline', reports: 3, browser_network_offline: true });
}));

try {
  base = await new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error('Static server did not start')), 10000);
    server.stdout.on('data', data => {
      const url = String(data).match(/http:\/\/127\.0\.0\.1:\d+\/web\//)?.[0];
      if (url) { clearTimeout(timer); resolve(url); }
    });
    server.once('error', error => { clearTimeout(timer); reject(error); });
    server.once('exit', code => { clearTimeout(timer); reject(new Error(`Server exited ${code}`)); });
    server.stderr.on('data', data => process.stderr.write(data));
  });
  let executablePath;
  for (const candidate of [process.env.MOONDIFF_BROWSER, 'C:/Program Files/Google/Chrome/Application/chrome.exe', 'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe'].filter(Boolean)) {
    try { await access(candidate); executablePath = candidate; break; } catch {}
  }
  if (!executablePath) throw new Error('Set MOONDIFF_BROWSER to an installed Chromium executable');
  browser = await chromium.launch({ executablePath, headless: true, args: ['--disable-extensions'] });
  console.log(`Web smoke: Node ${process.version}, Chrome ${browser.version()}, ${process.platform}/${process.arch}, OS ${release()}, CPU ${cpus()[0].model}`);
  let failed = 0;
  const selected = process.argv.includes('--red-race') ? tests.filter(t => t.name.startsWith('a late file read')) : process.argv.includes('--red') ? tests.slice(0, 1) : tests;
  for (const { name, run } of selected) {
    try { await run(); console.log(`PASS ${name}`); }
    catch (error) { failed++; console.error(`FAIL ${name}: ${error.message}`); }
  }
  const network = requests.filter(r => /^https?:/.test(r.url));
  assert.ok(network.every(r => new URL(r.url).hostname === '127.0.0.1' && r.method === 'GET'), 'Only local GET asset requests; no CDN/upload/telemetry');
  const summary = { node: process.version, browser: browser.version(), platform: process.platform, os: release(), cpu: cpus()[0].model, passed: selected.length - failed, total: selected.length, local_get_requests: network.length, remote_requests: 0, upload_requests: 0, evidence };
  await writeFile(path.join(work, 'result.json'), JSON.stringify(summary, null, 2));
  console.log(`Web smoke: ${summary.passed}/${summary.total} passed, ${failed} failed; ${network.length} local GET requests, zero remote/upload requests.`);
  process.exitCode = failed === 0 ? 0 : 1;
} finally {
  await browser?.close();
  server.kill();
}
