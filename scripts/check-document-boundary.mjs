import assert from 'node:assert/strict';
import { mkdtemp, mkdir, writeFile, unlink, rmdir } from 'node:fs/promises';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const root = fileURLToPath(new URL('../', import.meta.url));
const work = path.join(root, 'work', 'probes');
await mkdir(work, { recursive: true });
const dir = await mkdtemp(path.join(work, 'document-boundary-'));
const config = path.join(dir, 'moon.pkg');
const source = path.join(dir, 'forge.mbt');
try {
  await writeFile(config, 'import { "local/moondiff-json/src/input" @input, }\n');
  await writeFile(source, 'pub fn forge() -> @input.Document { { node_count: 1 } }\n');
  const result = spawnSync('moon', ['check', '--target', 'js', dir], { cwd: root, encoding: 'utf8', windowsHide: true });
  if (result.error) throw result.error;
  const output = result.stdout + result.stderr;
  assert.notEqual(result.status, 0, 'An external caller must not construct an unchecked Document');
  assert.match(output, /Cannot create values of the read-only type: [^\n]*\bDocument\./);
  console.log('Document boundary: unchecked external construction rejected by the compiler');
} finally {
  // Only delete the two files in the newly created test directory; no recursive removal.
  await unlink(source).catch(() => {});
  await unlink(config).catch(() => {});
  await rmdir(dir);
}
