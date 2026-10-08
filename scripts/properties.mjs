import assert from 'node:assert/strict';
import { mkdir, readFile, writeFile } from 'node:fs/promises';
import { spawnSync } from 'node:child_process';
import { analyze } from '../dist/moondiff-json.mjs';
import { launchBrowser, startServer } from './browser-tools.mjs';

// Test metadata and returned envelopes may be parsed; product inputs stay raw strings.
const seed = 0x20261008;
let state = seed;
const random = n => { state ^= state << 13; state ^= state >>> 17; state ^= state << 5; return (state >>> 0) % n; };
const quote = JSON.stringify;
const scalars = ['null','true','false','0','-0','1e0','1.00','9007199254740992','9007199254740993','1e400',quote('中文 / ~ 😀'),quote('<img onerror=alert(1)>')];
function tree(depth = 0) {
  if (depth >= 3 || random(3) === 0) return scalars[random(scalars.length)];
  const children = Array.from({ length: random(5) }, () => tree(depth + 1));
  return random(2) ? `[${children.join(',')}]` : `{${children.map((v,i) => `${quote(['a/b','~','😀','中文'][i])}:${v}`).join(',')}}`;
}
const cases = [];
for (let i = 0; i < 128; i++) cases.push({ name:`tree-${i}`, old:tree(), new:tree(), options:'{}', property:'symmetry' });
for (let i = 0; i < 32; i++) {
  const entries = Array.from({ length:4 }, (_,j) => `${quote(['a/b','~','😀','中文'][j])}:${tree()}`);
  cases.push({ name:`object-order-${i}`, old:`{${entries.join(',')}}`, new:`{${entries.reverse().join(',')}}`, options:'{}', property:'equal' });
  const value = String(random(99999) + 1);
  cases.push({ name:`decimal-${i}`, old:value, new:`${value}.00e0`, options:'{}', property:'equal' });
  const records = Array.from({ length:10 }, (_,j) => `{"id":${j},"value":${tree()}}`);
  cases.push({ name:`keyed-order-${i}`, old:`[${records.join(',')}]`, new:`[${records.reverse().join(',')}]`, options:'{"array_rules":[{"path":"","key":"id"}]}', property:'equal' });
}
cases.push({ name:'adjacent-integers', old:'9007199254740992', new:'9007199254740993', options:'{}', property:'modified' });
const mutation = process.argv.includes('--mutate-equal');
const evaluate = mutation ? () => analyze('null','null','{}') : analyze;
const replay = process.argv.indexOf('--replay');
const selected = replay >= 0 ? [JSON.parse(await readFile(process.argv[replay + 1],'utf8'))] : cases;
await mkdir('work/property-failures',{ recursive:true });
const parity = [];
for (const [index,c] of selected.entries()) {
  try {
    const forward = evaluate(c.old,c.new,c.options), r = JSON.parse(forward);
    assert.equal(r.ok,true,c.name);
    assert.equal(forward,evaluate(c.old,c.new,c.options),'deterministic bytes');
    assert.equal(JSON.parse(evaluate(c.old,c.old,c.options)).equal,true,'self equality');
    if (c.property === 'equal') assert.equal(r.equal,true,c.name);
    if (c.property === 'modified') { assert.equal(r.equal,false); assert.equal(r.summary.modified,1); }
    const reversed = JSON.parse(evaluate(c.new,c.old,c.options));
    assert.equal(r.summary.added,reversed.summary.removed);
    assert.equal(r.summary.removed,reversed.summary.added);
    assert.equal(r.summary.modified,reversed.summary.modified);
    assert.equal(r.summary.reordered,reversed.summary.reordered);
    for (const change of r.changes) for (const p of [change.old_path,change.new_path].filter(p => p !== null)) {
      assert.ok(p === '' || p.startsWith('/'));
      assert.ok(!/~(?![01])/u.test(p),'RFC 6901 escapes');
    }
    if (index % 16 === 0 || c.property === 'modified') parity.push({ ...c,expected:forward });
  } catch (error) {
    const file = `work/property-failures/${c.name}.json`;
    await writeFile(file,JSON.stringify({ ...c,seed },null,2));
    console.error(`FAIL seed=${seed} ${c.name}: ${error.message}\nReproduce: node scripts/properties.mjs --replay ${file}${mutation ? ' --mutate-equal' : ''}`);
    process.exitCode = 1; break;
  }
}
if (process.exitCode) process.exit(process.exitCode);
await mkdir('work/properties',{ recursive:true });
let browser, server;
try {
  const started = await startServer(); server = started.server;
  browser = await launchBrowser();
  const page = await browser.newPage();
  await page.goto(started.base);
  const workerResults = await page.evaluate(async inputs => {
    const worker = new Worker('./worker.js',{ type:'module' });
    try {
      await new Promise((resolve,reject) => { worker.onerror = reject; worker.onmessage = ({data}) => data.type === 'ready' && resolve(); });
      const results = [];
      for (const [i,c] of inputs.entries()) results.push(await new Promise((resolve,reject) => {
        worker.onerror = reject;
        worker.onmessage = ({data}) => data.type === 'result' ? resolve(data.report_text) : reject(new Error(data.message));
        worker.postMessage({ type:'analyze',request_id:i,old_text:c.old,new_text:c.new,options_text:c.options });
      }));
      return results;
    } finally { worker.terminate(); }
  },parity);
  for (const [i,c] of parity.entries()) {
    const dir = `work/properties/${i}`;
    await mkdir(dir,{ recursive:true });
    for (const [name,value] of [['old',c.old],['new',c.new],['options',c.options]]) await writeFile(`${dir}/${name}.json`,value);
    const cli = spawnSync(process.execPath,['cli/moondiff-json.mjs',`${dir}/old.json`,`${dir}/new.json`,'--options',`${dir}/options.json`,'--format','json'],{ encoding:'utf8',windowsHide:true });
    try {
      assert.ifError(cli.error);
      assert.equal(cli.status,JSON.parse(c.expected).equal ? 0 : 1);
      assert.equal(cli.stdout,c.expected,c.name + ' CLI');
      assert.equal(workerResults[i],c.expected,c.name + ' Worker');
    } catch (error) {
      const file = `work/property-failures/${c.name}.json`;
      await writeFile(file,JSON.stringify({ ...c,seed },null,2));
      console.error(`Reproduce: node scripts/properties.mjs --replay ${file}`);
      throw error;
    }
  }
  const result = { seed,cases:selected.length,parity_cases:parity.length,node:process.version,browser:browser.version() };
  await writeFile('work/properties/result.json',JSON.stringify(result,null,2));
  console.log(`Properties PASS: ${selected.length} cases, seed=${seed}; ${parity.length} bridge/CLI/real Worker byte matches; Chrome ${browser.version()}.`);
} finally { await browser?.close(); server?.kill(); }
