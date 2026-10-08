import assert from 'node:assert/strict';
import { readFile, readdir, mkdtemp, writeFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { spawn, spawnSync } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { launchBrowser } from './browser-tools.mjs';

const root = fileURLToPath(new URL('../', import.meta.url));
const bundle = path.resolve(process.argv[2] ?? 'work/release/moondiff-json-0.1.0');
const manifest = JSON.parse(await readFile(path.join(bundle, 'manifest.json'), 'utf8'));
const files = [];
async function walk(dir) {
  for (const entry of await readdir(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) await walk(full);
    else files.push(path.relative(bundle, full).replaceAll('\\', '/'));
  }
}
await walk(bundle);
assert.deepEqual(files.filter(f => f !== 'manifest.json').sort(), manifest.map(f => f.path).sort(), 'No unmanifested runtime files');
assert.ok(!files.some(f => /^(node_modules|src|\.tools|_build)\//.test(f)), 'Runtime is independent of source and development dependencies');
for (const file of manifest) assert.equal(createHash('sha256').update(await readFile(path.join(bundle, file.path))).digest('hex'), file.sha256, file.path);
const metadata = JSON.parse(await readFile(path.join(bundle, 'package.json'), 'utf8'));
assert.equal(metadata.scripts?.serve, 'node scripts/serve.mjs', 'Runtime must include an independent npm serve command');
const { analyze, format_text } = await import(pathToFileURL(path.join(bundle, 'dist/moondiff-json.mjs')));
const cases = [...JSON.parse(await readFile(path.join(root, 'fixtures/reports/cases.json'), 'utf8')), ...JSON.parse(await readFile(path.join(root, 'fixtures/errors/cases.json'), 'utf8'))];
// Run with an unrelated working directory and Chinese/space-containing paths.
const temporary = await mkdtemp(path.join(root, 'work', 'runtime-smoke-'));
const old = path.join(temporary, '旧 文件.json'), next = path.join(temporary, '新 文件.json'), options = path.join(temporary, '选项.json');
for (const c of cases) {
  await writeFile(old, c.old); await writeFile(next, c.new); await writeFile(options, c.options);
  const report = analyze(c.old, c.new, c.options), envelope = JSON.parse(report);
  if (c.report) assert.equal(report, JSON.stringify(c.report));
  for (const format of ['json', 'text']) {
    const cli = spawnSync(process.execPath, [path.join(bundle, 'cli/moondiff-json.mjs'), old, next, '--options', options, '--format', format], { cwd: temporary, encoding: 'utf8', windowsHide: true });
    assert.ifError(cli.error);
    assert.equal(cli.status, envelope.ok ? (envelope.equal ? 0 : 1) : 2, c.name);
    assert.equal(cli.stdout, format === 'json' ? report : format_text(report), c.name);
  }
}
const server = spawn(process.execPath, [path.join(bundle, 'scripts/serve.mjs')], { cwd: temporary, windowsHide: true, stdio: ['ignore', 'pipe', 'pipe'] });
let browser;
try {
  const base = await new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error('Runtime server startup timeout')), 10000);
    server.stdout.on('data', data => { const url = String(data).match(/http:\/\/127\.0\.0\.1:\d+\/web\//)?.[0]; if (url) { clearTimeout(timer); resolve(url); } });
    server.once('error', e => { clearTimeout(timer); reject(e); });
    server.once('exit', code => { clearTimeout(timer); reject(new Error(`Runtime server exited ${code}`)); });
    server.stderr.on('data', data => process.stderr.write(data));
  });
  browser = await launchBrowser();
  const page = await browser.newPage({ acceptDownloads: true });
  await page.goto(base);
  await page.waitForFunction(() => document.querySelector('#engine').dataset.ready === 'true');
  const c = cases[3];
  await page.locator('#old-text').fill(c.old); await page.locator('#new-text').fill(c.new); await page.locator('#options-text').fill(c.options);
  await page.locator('#compare').click();
  await page.waitForFunction(() => !document.querySelector('#download').disabled);
  const event = page.waitForEvent('download');
  await page.locator('#download').click();
  const download = await event;
  assert.equal(await download.failure(), null);
  assert.equal(await readFile(await download.path(), 'utf8'), analyze(c.old, c.new, c.options), 'Packaged browser Worker preserves exact report bytes');
  console.log(`Runtime PASS: ${manifest.length} hashes; 15 JSON/text CLI cases with 0/1/2; independent HTTP/page/Worker/download on ${process.platform}/${process.arch}, Chromium ${browser.version()}.`);
} finally { await browser?.close(); server.kill(); }
