import assert from 'node:assert/strict';
import { mkdir, writeFile } from 'node:fs/promises';
import { spawnSync } from 'node:child_process';
import { cpus, release, totalmem } from 'node:os';
import { performance } from 'node:perf_hooks';
import { createHash } from 'node:crypto';
import { analyze } from '../dist/moondiff-json.mjs';

if (process.version !== 'v22.23.3') throw new Error('Use pinned Node v22.23.3');
const seed = 0x20261008;
let state = seed;
const random = n => { state ^= state << 13; state ^= state >>> 17; state ^= state << 5; return (state >>> 0) % n; };
const records = Array.from({ length:10000 }, (_,id) => ({ id, value:random(1000000), text:`record-${id}`, padding:'x'.repeat(44) }));
const document = rows => JSON.stringify({ records:rows });
const old = document(records);
const changes = new Set();
while (changes.size < 10) changes.add(random(records.length));
const next = document(records.map((r,i) => changes.has(i) ? { ...r,value:r.value + 1 } : r));
const keyed = JSON.stringify({ array_rules:[{ path:'/records',key:'id' }] });
const checked = JSON.stringify({ array_rules:[{ path:'/records',key:'id',check_order:true }] });
const reverse = document([...records].reverse());
const all = document(records.map(r => ({ ...r,value:r.value + 1 })));
// Cases are prepared outside the timing region. About 1 MiB, 50002 nodes per side.
assert.ok(Buffer.byteLength(old) >= 950000 && Buffer.byteLength(old) <= 1150000);
const cases = [
  { name:'1MiB-10000-records-10-fields-position',old,new:next,options:'{}',modified:10 },
  { name:'1MiB-10000-records-10-fields-by-key',old,new:next,options:keyed,modified:10 },
  { name:'10000-keyed-reverse-default',old,new:reverse,options:keyed,equal:true },
  { name:'10000-keyed-reverse-check-order',old,new:reverse,options:checked,reordered:1 },
  { name:'10000-all-fields-changed',old,new:all,options:'{}',modified:10000 },
  { name:'byte-limit-rejection',old:JSON.stringify('x'.repeat(2097152)),new:'null',options:'{}',code:'INPUT_LIMIT' },
  { name:'node-limit-rejection',old:`[${Array(100000).fill('0').join(',')}]`,new:'null',options:'{}',code:'NODE_LIMIT' },
  { name:'depth-limit-rejection',old:'['.repeat(65) + '0' + ']'.repeat(65),new:'null',options:'{}',code:'DEPTH_LIMIT' },
  { name:'change-limit-rejection',old:`[${Array(10001).fill('0').join(',')}]`,new:`[${Array(10001).fill('1').join(',')}]`,options:'{}',code:'CHANGE_LIMIT' },
];
function validate(c,text) {
  const r = JSON.parse(text); // Returned envelope only, outside timing.
  if (c.code) { assert.equal(r.ok,false); assert.equal(r.error.code,c.code,c.name); assert.equal(r.changes,undefined); }
  else {
    assert.equal(r.ok,true,c.name);
    assert.equal(r.summary.modified,c.modified ?? 0,c.name);
    assert.equal(r.summary.reordered,c.reordered ?? 0,c.name);
    assert.equal(r.summary.added,0); assert.equal(r.summary.removed,0);
    assert.equal(r.equal,c.equal ?? false);
  }
}
const results = [];
for (const c of cases) {
  let expected;
  for (let i = 0; i < 5; i++) { expected = analyze(c.old,c.new,c.options); validate(c,expected); }
  const samples = [];
  for (let i = 0; i < 20; i++) {
    const start = performance.now();
    const text = analyze(c.old,c.new,c.options);
    samples.push(performance.now() - start);
    assert.equal(text,expected,'same bytes on every run'); validate(c,text);
  }
  const sorted = [...samples].sort((a,b) => a - b);
  const median = (sorted[9] + sorted[10]) / 2;
  const result = { name:c.name,old_bytes:Buffer.byteLength(c.old),new_bytes:Buffer.byteLength(c.new),options:c.options,median_ms:median,min_ms:sorted[0],max_ms:sorted[19],samples_ms:samples,report_sha256:createHash('sha256').update(expected).digest('hex') };
  results.push(result);
  console.log(`${c.name}: median ${median.toFixed(3)} ms [${sorted[0].toFixed(3)}, ${sorted[19].toFixed(3)}]`);
}
const moon = spawnSync('moon',['version','--all'],{ encoding:'utf8',windowsHide:true });
assert.ifError(moon.error); assert.equal(moon.status,0);
const evidence = { recorded_at:new Date().toISOString(),seed,warmups:5,measurements:20,node:process.version,platform:process.platform,arch:process.arch,os:release(),cpu:cpus()[0].model,logical_cpus:cpus().length,memory_bytes:totalmem(),moon:moon.stdout.trim(),changed_indices:[...changes].sort((a,b)=>a-b),timing_scope:'Synchronous analyze(raw strings), including options/input parse, validation, exact diff and JSON serialization; excludes fixture generation, IO, module load, test assertions and presentation. No forced GC; includes ordinary GC during analyze.',results };
await mkdir('bench',{ recursive:true });
await writeFile('bench/results.json',JSON.stringify(evidence,null,2) + '\n');
const passed = results.slice(0,2).every(r => r.median_ms <= 1000);
await writeFile('bench/results.md',`# 实测基准\n\n记录时间：${evidence.recorded_at}。固定 seed ${seed}，每项预热 5 次、测量 20 次，取中位数。\n\n环境：${evidence.cpu}；${evidence.platform} ${evidence.arch} ${evidence.os}；Node ${evidence.node}；逻辑 CPU ${evidence.logical_cpus}。\n\n${evidence.moon.split('\n').map(s => '- ' + s).join('\n')}\n\n每侧主数据约 ${(Buffer.byteLength(old)/1048576).toFixed(3)} MiB，10000 记录、50002 节点；四个标量字段含填充串。主案例只改 10 个 value 字段。包含原始 token 精确解析、比较和 JSON 报告，不含 IO、启动、生成和呈现；不强制 GC。不是 CLI 端到端或浏览器耗时，也没有与其他库竞速。\n\n| 案例 | 旧/新字节 | 中位数 ms | 最小/最大 ms |\n| --- | --- | --- | --- |\n${results.map(r => `| ${r.name} | ${r.old_bytes}/${r.new_bytes} | ${r.median_ms.toFixed(3)} | ${r.min_ms.toFixed(3)}/${r.max_ms.toFixed(3)} |`).join('\n')}\n\n主案例 ≤1 秒目标：**${passed ? '达到' : '未达到'}**。结果仅适用于该机器，不作为 CI 时间硬门槛。资源拒绝案例验证完整错误 envelope，未隐式截断。20 次原始数据、报告 hash、改动索引见 [results.json](results.json)。\n\n复现：先按 README 准备并构建，再运行 npm run bench。\n`);
console.log(`Benchmark recorded; main median <=1000ms: ${passed}. No CI timing gate.`);
