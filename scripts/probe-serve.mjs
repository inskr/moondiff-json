import http from 'node:http';
import { readFile } from 'node:fs/promises';

// Explicit test assets only; toolchains, sources and project metadata are not served.
const routes = new Map([
  ['/', ['../work/probes/worker-probe.html', 'text/html; charset=utf-8']],
  ['/worker-probe.mjs', ['../work/probes/worker-probe.mjs', 'text/javascript; charset=utf-8']],
  ['/dist/moondiff-json.mjs', ['../dist/moondiff-json.mjs', 'text/javascript; charset=utf-8']],
  ['/scripts/probe-cases.mjs', ['./probe-cases.mjs', 'text/javascript; charset=utf-8']],
  ['/node-results.json', ['../work/probes/node-results.json', 'application/json']],
]);
const server = http.createServer(async (req, res) => {
  const route = routes.get(new URL(req.url, 'http://localhost').pathname);
  if (req.method !== 'GET' || !route) { res.writeHead(404).end(); return; }
  try {
    const bytes = await readFile(new URL(route[0], import.meta.url));
    res.writeHead(200, { 'Content-Type': route[1], 'Cache-Control': 'no-store' }).end(bytes);
  } catch {
    res.writeHead(500).end('Probe asset unavailable; build and run the Node probe first.');
  }
});
// Let the OS select a usable port: Windows may reserve ranges including 4173.
server.listen(0, '127.0.0.1', () => {
  console.log(`Worker probe: http://127.0.0.1:${server.address().port}/`);
});
