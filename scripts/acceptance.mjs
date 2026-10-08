import { spawnSync } from 'node:child_process';
import { cpus,release } from 'node:os';
import { fileURLToPath } from 'node:url';
const root = fileURLToPath(new URL('../',import.meta.url));
if (process.version !== 'v22.23.3') throw new Error('Acceptance requires pinned Node v22.23.3; use the platform setup and environment scripts in README.');
console.log(`Acceptance: ${new Date().toISOString()}, Node ${process.version}, ${process.platform}/${process.arch}, OS ${release()}, CPU ${cpus()[0].model}`);
for (const [command,args] of [['moon',['version','--all']], ...['verify-task6','test-web-runner','serve-smoke','web-smoke','properties'].map(s => [process.execPath,[`scripts/${s}.mjs`]])]) {
  console.log(`> ${command} ${args.join(' ')}`);
  const result = spawnSync(command,args,{ cwd:root,stdio:'inherit',windowsHide:true });
  if (result.error) throw result.error;
  if (result.status !== 0) process.exit(result.status ?? 2);
}
console.log('Acceptance PASS: actual JS check/test/build, golden fixtures, bridge/CLI/product browser, Worker lifecycle and fixed-seed properties.');
