import { cp, mkdir, readFile, writeFile, readdir } from 'node:fs/promises';
import path from 'node:path';
import { createHash } from 'node:crypto';
const destination = 'work/release/moondiff-json-0.1.0';
await mkdir(destination,{ recursive:true });
for (const file of ['dist','web','cli','licenses','LICENSE','THIRD_PARTY_NOTICES.md']) await cp(file,path.join(destination,file),{ recursive:true });
await writeFile(path.join(destination,'package.json'),JSON.stringify({ name:'moondiff-json',version:'0.1.0',private:true,type:'module',engines:{node:'22.x'},bin:{'moondiff-json':'cli/moondiff-json.mjs'} },null,2) + '\n');
await writeFile(path.join(destination,'README.md'),'# MoonDiff JSON local runtime\n\nNode 22: node cli/moondiff-json.mjs old.json new.json --format json\n\nStatic host: serve web/ and dist/ under one parent over HTTP, then open web/. Keep both dist modules and licenses. No package publication or deployment has occurred. Full source, validation, limits and materials are in the source project README.\n');
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
console.log(`Local runtime prepared: ${destination}; ${manifest.length} hashed files. Not published.`);
