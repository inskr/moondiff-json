import http from 'node:http';
import { readFile } from 'node:fs/promises';

const args = process.argv.slice(2);
let port = 0;
if (args.length > 0) {
  if (args.length !== 2 || args[0] !== '--port' || !/^\d+$/.test(args[1]) || Number(args[1]) > 65535) {
    console.error('Usage: node scripts/serve.mjs [--port 0..65535]');
    process.exit(2);
  }
  port = Number(args[1]);
}
// Exact public assets only. Never serve source trees, user inputs or project metadata.
const routes = new Map([
  ['/web/', ['../web/index.html', 'text/html; charset=utf-8']],
  ['/web/styles.css', ['../web/styles.css', 'text/css; charset=utf-8']],
  ...['app', 'runner', 'worker', 'examples'].map(name => [`/web/${name}.js`, [`../web/${name}.js`, 'text/javascript; charset=utf-8']]),
  ...['moondiff-json', 'moondiff-json-core'].map(name => [`/dist/${name}.mjs`, [`../dist/${name}.mjs`, 'text/javascript; charset=utf-8']]),
]);
const server = http.createServer(async (req, res) => {
  if (req.method !== 'GET' && req.method !== 'HEAD') {
    res.writeHead(405, { Allow: 'GET, HEAD' }).end('Read-only static server');
    return;
  }
  let pathname;
  try { pathname = new URL(req.url, 'http://localhost').pathname; }
  catch { res.writeHead(400).end('Invalid URL'); return; }
  if (pathname === '/') { res.writeHead(302, { Location: '/web/' }).end(); return; }
  const route = routes.get(pathname);
  if (!route) { res.writeHead(404).end('Not found'); return; }
  try {
    const bytes = await readFile(new URL(route[0], import.meta.url));
    res.writeHead(200, {
      'Content-Type': route[1], 'Content-Length': bytes.length,
      'Cache-Control': 'no-cache', 'X-Content-Type-Options': 'nosniff',
      'Content-Security-Policy': "default-src 'none'; script-src 'self'; style-src 'self'; worker-src 'self'; img-src 'self' data:; connect-src 'none'; base-uri 'none'; form-action 'none'; frame-ancestors 'none'",
    }).end(req.method === 'HEAD' ? undefined : bytes);
  } catch {
    res.writeHead(503).end('Static asset unavailable. Build first: npm run build:js');
  }
});
server.on('error', error => { console.error(`Local server: ${error.message}`); process.exitCode = 2; });
server.listen(port, '127.0.0.1', () => console.log(`MoonDiff JSON: http://127.0.0.1:${server.address().port}/web/`));
for (const signal of ['SIGINT', 'SIGTERM']) process.on(signal, () => server.close());
