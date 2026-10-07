import { spawnSync } from 'node:child_process';
import { readFileSync } from 'node:fs';

if (!process.version.startsWith('v22.')) throw new Error('Task 3 verification requires Node 22.x');
console.log(`Task 3 verification: Node ${process.version}, ${process.platform}/${process.arch}`);
const steps = [
  [process.execPath, ['scripts/generate-basic-tests.mjs', '--check']],
  ['moon', ['info', '--target', 'js']],
  ['moon', ['fmt', '--check']],
  ['moon', ['check', '--target', 'js', '--deny-warn']],
  ['moon', ['test', '--target', 'js']],
  [process.execPath, ['scripts/check-document-boundary.mjs']],
  [process.execPath, ['scripts/build-js.mjs']],
  [process.execPath, ['scripts/probe-js.mjs']],
  [process.execPath, ['scripts/prepare-worker-probe.mjs']],
  [process.execPath, ['scripts/probe-browser.mjs']],
];
for (const [command, args] of steps) {
  console.log(`> ${command} ${args.join(' ')}`);
  const result = spawnSync(command, args, { stdio: 'inherit', windowsHide: true });
  if (result.error) throw result.error;
  if (result.status !== 0) process.exit(result.status ?? 2);
}
const browserEvidence = JSON.parse(readFileSync('work/probes/browser-result.json', 'utf8'));
console.log(`Verified browser: ${browserEvidence.browser}; ${browserEvidence.mode}`);
console.log('Task 3 verification passed. Keyed arrays and final report envelopes remain tasks 4–5.');
