import { cp, mkdir, readFile, writeFile, readdir, mkdtemp, rename, chmod } from 'node:fs/promises';
import path from 'node:path';
import { createHash } from 'node:crypto';
import { fileURLToPath } from 'node:url';
const root = fileURLToPath(new URL('../', import.meta.url));
const target = path.resolve(process.argv[2] ?? path.join(root,'work/release/moondiff-json-0.1.0'));
const relativeTarget = path.relative(path.join(root,'work/release'),target);
if (!relativeTarget || relativeTarget === '..' || relativeTarget.startsWith(`..${path.sep}`) || path.isAbsolute(relativeTarget)) throw new Error('Runtime destination must be a child of this project work/release directory.');
await mkdir(path.dirname(target),{ recursive:true });
// Fresh staging avoids including leftovers. Existing local output is preserved as a backup.
const destination = await mkdtemp(path.join(path.dirname(target),'.runtime-'));
const runtimeFiles = ['dist/moondiff-json.mjs','dist/moondiff-json-core.mjs','cli/moondiff-json.mjs',
  'web/index.html','web/styles.css',...['app','runner','worker','examples'].map(f => `web/${f}.js`),
  ...['moonbit-core-LICENSE','moonbit-core-NOTICE','moonjson-LICENSE','playwright-LICENSE','playwright-NOTICE'].map(f => `licenses/${f}.txt`),
  'LICENSE','THIRD_PARTY_NOTICES.md'];
for (const file of runtimeFiles) {
  await mkdir(path.dirname(path.join(destination,file)),{recursive:true});
  await cp(path.join(root,file),path.join(destination,file));
}
await mkdir(path.join(destination,'scripts'));
await cp(path.join(root,'scripts/serve.mjs'),path.join(destination,'scripts/serve.mjs'));
await chmod(path.join(destination,'cli/moondiff-json.mjs'),0o755);
await writeFile(path.join(destination,'package.json'),JSON.stringify({ name:'moondiff-json',version:'0.1.0',private:true,type:'module',engines:{node:'22.x'},bin:{'moondiff-json':'cli/moondiff-json.mjs'},scripts:{serve:'node scripts/serve.mjs'} },null,2) + '\n');
await writeFile(path.join(destination,'README.md'),'# MoonDiff JSON local runtime\n\nRequires Node 22.x (validated with 22.23.3). No npm install or MoonBit compiler is needed.\n\nCLI: node cli/moondiff-json.mjs old.json new.json --format json\nExit codes: 0 equal, 1 differences, 2 input/runtime error.\n\nWeb: npm run serve (or node scripts/serve.mjs). Open the printed localhost /web/ URL. Ctrl+C stops the server. Optional: npm run serve -- --port 8080.\n\nKeep web/, both dist modules, scripts/serve.mjs and licenses. No publication or deployment has occurred. Full source, validation, limits and materials are in the source project README.\n');
const manifest = [];
async function walk(dir) {
  for (const entry of await readdir(dir,{ withFileTypes:true })) {
    const file = path.join(dir,entry.name);
    if (entry.isDirectory()) await walk(file);
    else if (entry.name !== 'manifest.json') manifest.push({ path:path.relative(destination,file).replaceAll('\\','/'),sha256:createHash('sha256').update(await readFile(file)).digest('hex') });
  }
}
await walk(destination);
manifest.sort((a,b) => a.path.localeCompare(b.path));
await writeFile(path.join(destination,'manifest.json'),JSON.stringify(manifest,null,2) + '\n');
try {
  const backup = `${target}.previous-${Date.now()}`;
  await rename(target,backup);
  console.log(`Previous runtime preserved: ${backup}`);
} catch (error) { if (error.code !== 'ENOENT') throw error; }
await rename(destination,target);
console.log(`Local runtime prepared: ${target}; ${manifest.length} hashed files. Not published.`);
