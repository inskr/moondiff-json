import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const root = fileURLToPath(new URL('../', import.meta.url));
const server = spawn(process.execPath, ['scripts/serve.mjs'], { cwd: root, windowsHide: true, stdio: ['ignore', 'pipe', 'pipe'] });
try {
  const base = await new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error('Server startup timeout')), 10000);
    server.stdout.on('data', data => {
      const url = String(data).match(/http:\/\/127\.0\.0\.1:\d+\/web\//)?.[0];
      if (url) { clearTimeout(timer); resolve(url); }
    });
    server.once('error', error => { clearTimeout(timer); reject(error); });
    server.once('exit', code => { clearTimeout(timer); reject(new Error(`Server exited ${code}`)); });
    server.stderr.on('data', data => process.stderr.write(data));
  });
  for (const [route, type] of [
    ['/web/', 'text/html'], ['/web/app.js', 'text/javascript'], ['/web/styles.css', 'text/css'],
    ['/web/runner.js', 'text/javascript'], ['/web/worker.js', 'text/javascript'], ['/web/examples.js', 'text/javascript'],
    ['/dist/moondiff-json.mjs', 'text/javascript'], ['/dist/moondiff-json-core.mjs', 'text/javascript'],
  ]) {
    const response = await fetch(new URL(route, base));
    assert.equal(response.status, 200, route);
    assert.ok(response.headers.get('content-type').startsWith(type), route);
    assert.ok((await response.text()).length > 0, route);
  }
  const home = await fetch(new URL('/', base));
  assert.equal(home.status, 200);
  assert.ok(home.url.endsWith('/web/'));
  for (const route of ['/.git/config', '/package.json', '/docs/spec.md', '/cli/moondiff-json.mjs', '/web/missing.js']) {
    assert.equal((await fetch(new URL(route, base))).status, 404, route);
  }
  assert.equal((await fetch(base, { method: 'POST', body: 'private JSON' })).status, 405);
  assert.equal((await fetch(base, { method: 'HEAD' })).status, 200);
  console.log('Static server: 8 assets, root redirect, private/unlisted paths denied, no upload endpoint, HEAD passed.');
} finally { server.kill(); }
