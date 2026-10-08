import { spawnSync } from 'node:child_process';
import { mkdir, mkdtemp, readFile, writeFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const root = fileURLToPath(new URL('../', import.meta.url));
const output = path.join(root,'work/release/task9');
function run(command,args,{ capture = false } = {}) {
  const result = spawnSync(command,args,{ cwd:root,encoding:'utf8',stdio:capture ? 'pipe' : 'inherit',windowsHide:true });
  if (result.error) throw result.error;
  if (result.status !== 0) throw new Error(`${command} ${args.join(' ')} failed (${result.status})${capture ? `: ${result.stderr}` : ''}`);
  return result.stdout?.trim();
}
if (process.version !== 'v22.23.3') throw new Error('Packaging requires pinned Node v22.23.3.');
const trackedChanges = run('git',['status','--porcelain','--untracked-files=no'],{capture:true});
if (trackedChanges) throw new Error(`Commit tracked changes before packaging; source must match the runtime. User untracked files are not archived.\n${trackedChanges}`);
const newFiles = run('git',['ls-files','--others','--exclude-standard','-z'],{capture:true}).split('\0').filter(Boolean);
if (newFiles.length) throw new Error(`Commit new project files before packaging so source and runtime agree: ${newFiles.join(', ')}`);
const commit = run('git',['rev-parse','HEAD'],{capture:true});
await mkdir(output,{recursive:true});
// Rebuild at this exact clean tracked revision; never package cached dist blindly.
run(process.execPath,['scripts/build-js.mjs']);
const stage = await mkdtemp(path.join(output,'.package-'));
const name = 'moondiff-json-0.1.0';
const bundle = path.join(stage,name);
run(process.execPath,['scripts/prepare-local.mjs',bundle]);
run(process.execPath,['scripts/verify-release.mjs',bundle]);
const source = `${name}-source.tar.gz`, runtime = `${name}-runtime.tar.gz`;
run('git',['archive','--format=tar.gz',`--prefix=${name}-source/`,`--output=${path.join(output,source)}`,commit]);
run('tar',['-czf',path.join(output,runtime),'-C',stage,name]);
const extracted = await mkdtemp(path.join(output,'.extracted-'));
run('tar',['-xzf',path.join(output,runtime),'-C',extracted]);
run(process.execPath,['scripts/verify-release.mjs',path.join(extracted,name)]);
const artifacts = [];
for (const file of [source,runtime]) {
  const bytes = await readFile(path.join(output,file));
  artifacts.push({path:file,bytes:bytes.length,sha256:createHash('sha256').update(bytes).digest('hex')});
}
await writeFile(path.join(output,'delivery-manifest.json'),JSON.stringify({source_commit:commit,prepared_at:new Date().toISOString(),platform:process.platform,node:process.version,artifacts,publicly_published:false},null,2)+'\n');
console.log(`Release preparation PASS: ${output}; source/runtime revision ${commit}. Not published.`);
