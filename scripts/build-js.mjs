import { spawnSync } from 'node:child_process';
import { copyFile, mkdir, readdir } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = fileURLToPath(new URL('../', import.meta.url));
const result = spawnSync('moon', ['build', '--target', 'js', '--release'], {
  cwd: root, stdio: 'inherit', shell: false,
});
if (result.error) throw result.error;
if (result.status !== 0) process.exit(result.status ?? 2);

// Discover the compiler artifact after a real build; reject ambiguity.
async function discover(dir) {
  const entries = await readdir(dir, { withFileTypes: true });
  const found = [];
  for (const entry of entries) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) found.push(...await discover(full));
    else if (entry.name.endsWith('.js') && path.basename(dir) === 'bridge') found.push(full);
  }
  return found;
}
const artifacts = await discover(path.join(root, '_build', 'js', 'release', 'build'));
if (artifacts.length !== 1) throw new Error(`Expected one bridge artifact, found ${artifacts.length}`);
await mkdir(path.join(root, 'dist'), { recursive: true });
await copyFile(artifacts[0], path.join(root, 'dist', 'moondiff-json-core.mjs'));
await copyFile(path.join(root, 'src', 'bridge', 'entry.mjs'), path.join(root, 'dist', 'moondiff-json.mjs'));
console.log(`Bridge artifact: ${path.relative(root, artifacts[0])} -> dist/moondiff-json-core.mjs; string facade: dist/moondiff-json.mjs`);
