import { spawnSync } from 'node:child_process';

if (!process.version.startsWith('v22.')) throw new Error('Task 1 verification requires Node 22.x');
const steps = [
  ['moon', ['info', '--target', 'js']],
  ['moon', ['fmt', '--check']],
  ['moon', ['check', '--target', 'js', '--deny-warn']],
  ['moon', ['test', '--target', 'js']],
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
console.log('Task 1 verification passed. This does not validate tasks 2–8.');
