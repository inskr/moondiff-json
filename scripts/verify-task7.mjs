import { spawnSync } from 'node:child_process';
import { cpus, release } from 'node:os';
import { fileURLToPath } from 'node:url';

const root = fileURLToPath(new URL('../', import.meta.url));
if (!process.version.startsWith('v22.')) throw new Error('Task 7 verification requires Node 22.x');
console.log(`Task 7 verification: Node ${process.version}, ${process.platform}/${process.arch}, OS ${release()}, CPU ${cpus()[0].model}`);
for (const script of ['scripts/verify-task6.mjs', 'scripts/test-web-runner.mjs', 'scripts/serve-smoke.mjs', 'scripts/web-smoke.mjs']) {
  console.log(`> ${process.execPath} ${script}`);
  const result = spawnSync(process.execPath, [script], { cwd: root, stdio: 'inherit', windowsHide: true });
  if (result.error) throw result.error;
  if (result.status !== 0) process.exit(result.status ?? 2);
}
console.log('Task 7 passed: shared core/CLI, Worker lifecycle, read-only static server and real product-page browser smoke. Functional scope frozen; formal benchmarks, CI and final materials remain task 8.');
