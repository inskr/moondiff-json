import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { readFile } from 'node:fs/promises';
import { cpus, release } from 'node:os';
import { fileURLToPath } from 'node:url';

const root = fileURLToPath(new URL('../', import.meta.url));
if (!process.version.startsWith('v22.')) throw new Error('Task 6 verification requires Node 22.x');
console.log(`Task 6 verification: Node ${process.version}, ${process.platform}/${process.arch}, OS ${release()}, CPU ${cpus()[0].model}`);
for (const script of ['scripts/verify-task5.mjs', 'scripts/cli-smoke.mjs']) {
  console.log(`> ${process.execPath} ${script}`);
  const result = spawnSync(process.execPath, [script], { cwd: root, stdio: 'inherit', windowsHide: true });
  if (result.error) throw result.error;
  if (result.status !== 0) process.exit(result.status ?? 2);
}
const load = async name => JSON.parse(await readFile(new URL(`../work/probes/${name}`, import.meta.url), 'utf8'));
const cli = await load('cli-results.json');
const node = await load('analyze-results.json');
const text = await load('analyze-text-results.json');
const browser = await load('analyze-browser-result.json');
assert.equal(cli.length, 15);
assert.deepEqual(cli.map(c => c.report), node);
assert.deepEqual(cli.map(c => c.text), text);
// The just-run real browser probe compared its Worker outputs to these same bytes.
assert.match(browser.result, /^PASS: 15 complete analyze reports equal Node bytes/);
console.log(`Parity: ${cli.length} reports and text outputs byte-identical across direct bridge, CLI and Chrome ${browser.browser} module Worker.`);
console.log('Task 6 verification passed on Windows. Linux is untested; product website and formal benchmarks remain tasks 7–8.');
