import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { copyFile, mkdir, mkdtemp, readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { analyze, format_text } from '../dist/moondiff-json.mjs';

const root = fileURLToPath(new URL('../', import.meta.url));
const cli = path.join(root, 'cli', 'moondiff-json.mjs');
const work = path.join(root, 'work', 'probes');
await mkdir(work, { recursive: true });
const temp = await mkdtemp(path.join(work, 'cli smoke 中文 '));
const packageInfo = JSON.parse(await readFile(path.join(root, 'package.json'), 'utf8'));
// Only fixture metadata and returned envelopes are parsed by JS, never documents.
const reports = JSON.parse(await readFile(path.join(root, 'fixtures/reports/cases.json'), 'utf8'));
const errors = JSON.parse(await readFile(path.join(root, 'fixtures/errors/cases.json'), 'utf8'));
const tests = [];
const snapshots = new Map();
const results = [];

function test(name, run) { tests.push({ name, run }); }
async function file(name, content) {
  const location = path.join(temp, name);
  const bytes = Buffer.isBuffer(content) ? content : Buffer.from(content, 'utf8');
  await writeFile(location, bytes);
  snapshots.set(location, bytes);
  return location;
}
function invoke(args, entry = cli) {
  const result = spawnSync(process.execPath, [entry, ...args], {
    cwd: temp, encoding: 'utf8', windowsHide: true, timeout: 15000,
    maxBuffer: 32 * 1024 * 1024,
  });
  assert.ifError(result.error);
  assert.equal(result.signal, null, 'CLI must finish normally');
  return result;
}
function errorReport(result, code, side) {
  assert.equal(result.status, 2, 'Input/argument/IO error must exit 2');
  const report = JSON.parse(result.stdout);
  assert.deepEqual(Object.keys(report), ['schema_version', 'ok', 'error']);
  assert.equal(report.schema_version, '1.0');
  assert.equal(report.ok, false);
  assert.deepEqual(Object.keys(report.error), ['code', 'message', 'side', 'path', 'line', 'column']);
  assert.equal(report.error.code, code);
  assert.equal(report.error.side, side);
  assert.ok(report.error.message.length > 0);
  assert.ok(result.stderr.includes(code), 'Error diagnostic must be visible on stderr');
  return report;
}

for (const [i, c] of [...reports, ...errors].entries()) {
  const old = await file(`${i} old document.json`, c.old);
  const next = await file(`${i} new document.json`, c.new);
  const options = await file(`${i} options.json`, c.options);
  const args = [old, next, '--options', options];
  test(`golden/process: ${c.name}`, () => {
    const result = invoke([...args, '--format', 'json']);
    const expected = c.report ? JSON.stringify(c.report) : analyze(c.old, c.new, c.options);
    const envelope = JSON.parse(expected);
    assert.equal(result.status, envelope.ok ? (envelope.equal ? 0 : 1) : 2);
    assert.equal(result.stdout, expected, 'CLI must emit exact shared report bytes without logs/newline');
    if (envelope.ok) assert.equal(result.stderr, '');
    else errorReport(result, envelope.error.code, envelope.error.side);
    if (!c.report) {
      assert.equal(envelope.error.code, c.code);
      assert.equal(envelope.error.side, c.side);
      if ('path' in c) assert.equal(envelope.error.path, c.path);
    }
    assert.equal(result.stdout, analyze(c.old, c.new, c.options), 'Direct bridge/CLI parity');
    const text = invoke([...args, '--format', 'text']);
    assert.equal(text.status, result.status);
    assert.equal(text.stdout, format_text(expected), 'Text must use MoonBit formatter');
    if (envelope.ok) assert.equal(text.stderr, '');
    else assert.ok(text.stderr.includes(envelope.error.code));
    results.push({ name: c.name, report: result.stdout, text: text.stdout });
  });
}

const one = await file('equal old.json', '1');
const equal = await file('equal new.json', '1.0');
const zero = await file('different.json', '0');
const options = await file('valid options.json', '{}');
const badBytes = await file('invalid utf8.json', Buffer.from([0xc3, 0x28]));
const missing = path.join(temp, 'missing file.json');

test('default format is MoonBit text; equal exits 0', () => {
  const result = invoke([one, equal]);
  assert.equal(result.status, 0);
  assert.equal(result.stdout, 'equal: true\nadded: 0 removed: 0 modified: 0 reordered: 0 ignored_subtrees: 0\n');
  assert.equal(result.stderr, '');
});
test('default text differences exit 1 and preserve exact numbers', () => {
  const result = invoke([one, zero]);
  assert.equal(result.status, 1);
  assert.equal(result.stdout, 'equal: false\nadded: 0 removed: 0 modified: 1 reordered: 0 ignored_subtrees: 0\nmodified old="" new=""\n  before: 1\n  after: 0\n');
  assert.equal(result.stderr, '');
});
for (const side of ['old', 'new', 'options']) {
  test(`missing ${side} file exits 2 with IO_ERROR`, () => {
    const args = [side === 'old' ? missing : one, side === 'new' ? missing : equal,
      '--options', side === 'options' ? missing : options, '--format', 'json'];
    const report = errorReport(invoke(args), 'IO_ERROR', side);
    assert.equal(report.error.path, null);
    assert.equal(report.error.line, null);
    assert.equal(report.error.column, null);
  });
  test(`invalid UTF-8 on ${side} exits 2 without replacement characters`, () => {
    const args = [side === 'old' ? badBytes : one, side === 'new' ? badBytes : equal,
      '--options', side === 'options' ? badBytes : options, '--format', 'json'];
    const report = errorReport(invoke(args), 'ENCODING_ERROR', side);
    assert.equal(report.error.path, null);
    assert.equal(report.error.line, null);
    assert.equal(report.error.column, null);
  });
}
test('directory input is IO_ERROR', () => {
  errorReport(invoke([temp, equal, '--format', 'json']), 'IO_ERROR', 'old');
});
test('text IO failure emits a report plus stderr diagnostic', () => {
  const result = invoke([missing, equal]);
  assert.equal(result.status, 2);
  assert.match(result.stdout, /^error: IO_ERROR\n/);
  assert.ok(result.stderr.includes('IO_ERROR'));
});
for (const [name, bytes] of [
  ['overlong', [0xc0, 0xaf]], ['surrogate', [0xed, 0xa0, 0x80]],
  ['truncated', [0xf0, 0x9f, 0x92]], ['out of range', [0xf4, 0x90, 0x80, 0x80]],
]) {
  const invalid = await file(`utf8 ${name}.json`, Buffer.from(bytes));
  test(`strict UTF-8 rejects ${name}`, () => {
    errorReport(invoke([invalid, equal, '--format', 'json']), 'ENCODING_ERROR', 'old');
  });
}

for (const [name, args] of [
  ['unknown flag', [one, equal, '--unknown']],
  ['missing format value', [one, equal, '--format']],
  ['missing options value', [one, equal, '--options']],
  ['duplicate format', [one, equal, '--format', 'json']],
  ['duplicate options', [one, equal, '--options', options, '--options', options]],
  ['only one input', [one]], ['no input', []], ['third input', [one, equal, zero]],
  ['help mixed with inputs', [one, equal, '--help']],
]) {
  test(`argument error: ${name}`, () => {
    errorReport(invoke(['--format', 'json', ...args]), 'INVALID_OPTIONS', null);
  });
}
test('unsupported format exits 2', () => {
  const result = invoke([one, equal, '--format', 'yaml']);
  assert.equal(result.status, 2);
  assert.match(result.stdout, /^error: INVALID_OPTIONS\n/);
  assert.ok(result.stderr.includes('INVALID_OPTIONS'));
});
test('--help is usable from another cwd', () => {
  const result = invoke(['--help']);
  assert.equal(result.status, 0);
  assert.match(result.stdout, /moondiff-json/);
  assert.match(result.stdout, /--format text\|json/);
  assert.match(result.stdout, /--options/);
  assert.equal(result.stderr, '');
});
test('--version follows package metadata', () => {
  const result = invoke(['--version']);
  assert.equal(result.status, 0);
  assert.equal(result.stdout, `moondiff-json ${packageInfo.version}\n`);
  assert.equal(result.stderr, '');
});
const dashedOld = await file('-old 中文 file.json', '1');
const dashedNew = await file('-new 中文 file.json', '1e0');
test('-- terminates options for leading-dash filenames and spaces', () => {
  const result = invoke(['--format', 'json', '--', path.basename(dashedOld), path.basename(dashedNew)]);
  assert.equal(result.status, 0);
  assert.equal(result.stdout, analyze('1', '1e0'));
  assert.equal(result.stderr, '');
});

const bomOld = await file('BOM old.json', '\uFEFF1');
const bomNew = await file('BOM new.json', '\uFEFF1e0');
const bomOptions = await file('BOM options.json', '\uFEFF{}');
test('one UTF-8 BOM on each input is allowed', () => {
  const result = invoke([bomOld, bomNew, '--options', bomOptions, '--format', 'json']);
  assert.equal(result.status, 0);
  assert.equal(result.stdout, analyze('\uFEFF1', '\uFEFF1e0', '\uFEFF{}'));
  assert.equal(result.stderr, '');
});
const doubleBom = await file('double BOM.json', '\uFEFF\uFEFF1');
test('two leading BOMs are not silently stripped', () => {
  errorReport(invoke([doubleBom, equal, '--format', 'json']), 'PARSE_ERROR', 'old');
});
const limitOptions = await file('byte limit.json', '{"limits":{"max_input_bytes":3}}');
test('preserved BOM bytes count toward MoonBit byte limit', () => {
  errorReport(invoke([bomOld, one, '--options', limitOptions, '--format', 'json']), 'INPUT_LIMIT', 'old');
});
const oversized = await file('oversized document.json', '0' + ' '.repeat(2097152));
test('oversized valid JSON is rejected without truncation', () => {
  errorReport(invoke([oversized, zero, '--format', 'json']), 'INPUT_LIMIT', 'old');
});

const cleanRoot = path.join(temp, 'without build');
await mkdir(path.join(cleanRoot, 'cli'), { recursive: true });
await copyFile(cli, path.join(cleanRoot, 'cli', 'moondiff-json.mjs'));
await copyFile(path.join(root, 'package.json'), path.join(cleanRoot, 'package.json'));
const unbuiltCli = path.join(cleanRoot, 'cli', 'moondiff-json.mjs');
test('--help and --version work before build', () => {
  for (const flag of ['--help', '--version']) {
    const result = invoke([flag], unbuiltCli);
    assert.equal(result.status, 0);
    assert.ok(result.stdout.length > 0);
    assert.equal(result.stderr, '');
  }
});
test('missing build artifacts are runtime error 2 with useful stderr', () => {
  const result = invoke([one, equal], unbuiltCli);
  assert.equal(result.status, 2);
  assert.equal(result.stdout, '');
  assert.match(result.stderr, /build:js/);
});
test('all source inputs remain byte-identical', async () => {
  for (const [location, bytes] of snapshots) {
    assert.deepEqual(await readFile(location), bytes, path.basename(location));
  }
});

let failed = 0;
for (const { name, run } of tests) {
  try {
    await run();
    console.log(`PASS ${name}`);
  } catch (error) {
    failed++;
    console.error(`FAIL ${name}: ${error.message}`);
  }
}
if (failed === 0) {
  await writeFile(path.join(work, 'cli-results.json'), JSON.stringify(results));
}
console.log(`CLI smoke: ${tests.length - failed}/${tests.length} passed, ${failed} failed; Node ${process.version}, ${process.platform}/${process.arch}. Fixtures: ${temp}`);
process.exitCode = failed === 0 ? 0 : 1;
