import { spawnSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { cpus, release } from 'node:os';

if (!process.version.startsWith('v22.')) throw new Error('Task 5 verification requires Node 22.x');
console.log(`Task 5 verification: Node ${process.version}, ${process.platform}/${process.arch}, OS ${release()}, CPU ${cpus()[0].model}`);
const steps = [
  [process.execPath, ['scripts/generate-basic-tests.mjs', '--check']],
  [process.execPath, ['scripts/generate-keyed-tests.mjs', '--check']],
  [process.execPath, ['scripts/generate-report-tests.mjs', '--check']],
  ['moon', ['info', '--target', 'js']],
  ['moon', ['fmt', '--check']],
  ['moon', ['check', '--target', 'js', '--deny-warn']],
  ['moon', ['test', '--target', 'js']],
  [process.execPath, ['scripts/check-document-boundary.mjs']],
  [process.execPath, ['scripts/build-js.mjs']],
  [process.execPath, ['scripts/probe-js.mjs']],
  [process.execPath, ['scripts/prepare-worker-probe.mjs']],
  [process.execPath, ['scripts/probe-browser.mjs']],
  [process.execPath, ['scripts/probe-analyze.mjs']],
  [process.execPath, ['scripts/prepare-analyze-worker.mjs']],
  [process.execPath, ['scripts/probe-analyze-browser.mjs']],
];
for (const [command,args] of steps) {
  console.log(`> ${command} ${args.join(' ')}`);
  const result = spawnSync(command,args,{stdio:'inherit',windowsHide:true});
  if (result.error) throw result.error;
  if (result.status !== 0) process.exit(result.status??2);
}
const evidence = JSON.parse(readFileSync('work/probes/analyze-browser-result.json','utf8'));
console.log(`Verified browser: ${evidence.browser}; ${evidence.mode}; report and formatted text bytes identical to Node.`);
console.log('Task 5 core MVP verification passed. CLI, product website and formal benchmarks remain tasks 6–8.');
