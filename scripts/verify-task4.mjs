import { spawnSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { cpus, release } from 'node:os';
import assert from 'node:assert/strict';

if (!process.version.startsWith('v22.')) throw new Error('Task 4 verification requires Node 22.x');
console.log(`Task 4 verification: Node ${process.version}, ${process.platform}/${process.arch}, OS ${release()}, CPU ${cpus()[0].model}`);
const steps = [
  [process.execPath, ['scripts/generate-basic-tests.mjs', '--check']],
  [process.execPath, ['scripts/generate-keyed-tests.mjs', '--check']],
  ['moon', ['info', '--target', 'js']],
  ['moon', ['fmt', '--check']],
  ['moon', ['check', '--target', 'js', '--deny-warn']],
  ['moon', ['test', '--target', 'js']],
  ['moon', ['test', '--target', 'js', '--filter', 'reverse ten thousand identities uses keyed matching and one reorder']],
  [process.execPath, ['scripts/check-document-boundary.mjs']],
  [process.execPath, ['scripts/build-js.mjs']],
  [process.execPath, ['scripts/probe-js.mjs']],
  [process.execPath, ['scripts/prepare-worker-probe.mjs']],
  [process.execPath, ['scripts/probe-browser.mjs']],
];
for (const [command, args] of steps) {
  console.log(`> ${command} ${args.join(' ')}`);
  const reverse = args.includes('--filter');
  const started = performance.now();
  const result = spawnSync(command, args, {
    stdio: reverse ? 'pipe' : 'inherit', encoding: 'utf8', windowsHide: true,
  });
  if (result.error) throw result.error;
  if (reverse) {
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
  }
  if (result.status !== 0) process.exit(result.status ?? 2);
  if (reverse) {
    assert.match(result.stdout, /Total tests: 1, passed: 1, failed: 0\./);
    console.log(`10000-identity reverse test command: ${(performance.now() - started).toFixed(1)} ms; includes runner, parsing, two diffs and assertions; not the task 8 benchmark.`);
  }
}
const browser = JSON.parse(readFileSync('work/probes/browser-result.json', 'utf8'));
console.log(`Verified browser: ${browser.browser}; ${browser.mode}`);
console.log('Task 4 verification passed. Final options/report envelopes and analyze remain task 5.');
