import { mkdir, writeFile } from 'node:fs/promises';
await mkdir('work/probes',{recursive:true});
await writeFile('work/probes/analyze-worker.mjs',`
import { analyze, format_text } from '/dist/moondiff-json.mjs';
self.onmessage = ({ data }) => {
  try {
    const reports = data.map(c => analyze(c.old,c.new,c.options));
    self.postMessage({ok:true,reports,text:reports.map(format_text)});
  } catch (error) { self.postMessage({ok:false,error:String(error)}); }
};
`);
await writeFile('work/probes/analyze.html',`<!doctype html>
<meta charset="utf-8"><title>MoonDiff JSON analyze Worker verification</title>
<h1>Shared analyze core verification</h1><pre id="result">RUNNING</pre>
<script type="module">
const out = document.querySelector('#result');
try {
  const [cases,expected,expectedText] = await Promise.all(['/analyze-cases.json','/analyze-results.json','/analyze-text-results.json'].map(url=>fetch(url).then(r=>{if(!r.ok) throw Error(url);return r.json();})));
  const worker = new Worker('/analyze-worker.mjs',{type:'module'});
  const timer = setTimeout(()=>{worker.terminate();out.textContent='FAIL: Worker timeout';},5000);
  worker.onerror = e => {clearTimeout(timer);worker.terminate();out.textContent='FAIL: '+e.message;};
  worker.onmessage = ({data}) => {
    clearTimeout(timer);worker.terminate();
    out.textContent = data.ok && JSON.stringify(data.reports)===JSON.stringify(expected) && JSON.stringify(data.text)===JSON.stringify(expectedText)
      ? 'PASS: '+expected.length+' complete analyze reports equal Node bytes' : 'FAIL: '+JSON.stringify(data);
  };
  worker.postMessage(cases);
} catch (error) {out.textContent='FAIL: '+error;}
</script>`);
