import { mkdir, writeFile } from 'node:fs/promises';

// Generated into the isolated experiment directory, outside the product website.
const dir = new URL('../work/probes/', import.meta.url);
await mkdir(dir, { recursive: true });
await writeFile(new URL('worker-probe.mjs', dir), `
import { probe_document } from '/dist/moondiff-json.mjs';
import { probeCases } from '/scripts/probe-cases.mjs';
self.onmessage = () => {
  try { self.postMessage({ ok: true, outputs: probeCases.map(c => probe_document(c.input)) }); }
  catch (error) { self.postMessage({ ok: false, error: String(error) }); }
};
`);
await writeFile(new URL('worker-probe.html', dir), `<!doctype html>
<meta charset="utf-8"><title>MoonDiff JSON — Task 1 Worker probe</title>
<h1>Task 1: browser module Worker</h1>
<p>This page tests parsing and the string bridge. It is not the product demo.</p>
<pre id="result">RUNNING</pre>
<script type="module">
const out = document.querySelector('#result');
try {
  const expected = await fetch('/node-results.json').then(r => { if (!r.ok) throw Error('Missing Node results'); return r.json(); });
  const worker = new Worker('/worker-probe.mjs', { type: 'module' });
  const timer = setTimeout(() => { worker.terminate(); out.textContent = 'FAIL: Worker timeout'; }, 5000);
  worker.onerror = event => { clearTimeout(timer); worker.terminate(); out.textContent = 'FAIL: ' + event.message; };
  worker.onmessage = ({ data }) => {
    clearTimeout(timer); worker.terminate();
    const same = data.ok && JSON.stringify(data.outputs) === JSON.stringify(expected);
    out.textContent = same ? 'PASS: ' + data.outputs.length + ' browser Worker outputs equal Node bytes\\n' + navigator.userAgent : 'FAIL: ' + JSON.stringify(data);
  };
  worker.postMessage('run');
} catch (error) { out.textContent = 'FAIL: ' + error; }
</script>`);
