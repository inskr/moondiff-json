import assert from 'node:assert/strict';
import { readFile, writeFile, mkdir } from 'node:fs/promises';
import * as core from '../dist/moondiff-json.mjs';

assert.equal(typeof core.analyze, 'function', 'Actual ESM build must export analyze');
assert.equal(typeof core.format_text, 'function', 'Actual ESM build must export format_text');
// Parse only test fixture metadata and returned report envelopes, never documents.
const reports = JSON.parse(await readFile('fixtures/reports/cases.json','utf8'));
const errors = JSON.parse(await readFile('fixtures/errors/cases.json','utf8'));
assert.equal(core.analyze('1','1'),JSON.stringify(reports[5].report),'Omitted options default to {}');
const cases = [...reports,...errors];
const results = [];
for (const c of cases) {
  const actual = core.analyze(c.old,c.new,c.options);
  assert.equal(typeof actual,'string');
  assert.equal(actual,core.analyze(c.old,c.new,c.options),c.name+' deterministic bytes');
  if (c.report) assert.equal(actual,JSON.stringify(c.report),c.name);
  else {
    const r = JSON.parse(actual);
    assert.deepEqual(Object.keys(r),['schema_version','ok','error']);
    assert.equal(r.schema_version,'1.0');
    assert.equal(r.ok,false);
    assert.deepEqual(Object.keys(r.error),['code','message','side','path','line','column']);
    assert.equal(r.error.code,c.code,c.name);
    assert.equal(r.error.side,c.side,c.name);
    if ('path' in c) assert.equal(r.error.path,c.path);
    if (c.position) { assert.ok(r.error.line>=1); assert.ok(r.error.column>=1); }
  }
  assert.ok(core.format_text(actual).length>0);
  results.push(actual);
}
assert.equal(core.format_text(results[0]),'equal: false\nadded: 0 removed: 0 modified: 1 reordered: 0 ignored_subtrees: 1\nmodified old="/timeout" new="/timeout"\n  before: 30\n  after: 60\n');
assert.throws(()=>core.format_text('{}'),error=>{
  assert.equal(error.name,'MoonDiffFormatError');
  assert.equal(error.report_text,error.message);
  const report = JSON.parse(error.report_text);
  assert.equal(report.ok,false);
  assert.equal(report.error.code,'INVALID_OPTIONS');
  return true;
},'Invalid report must raise through actual JS export');
await mkdir('work/probes',{recursive:true});
await writeFile('work/probes/analyze-cases.json',JSON.stringify(cases.map(c=>({old:c.old,new:c.new,options:c.options}))));
await writeFile('work/probes/analyze-results.json',JSON.stringify(results));
await writeFile('work/probes/analyze-text-results.json',JSON.stringify(results.map(core.format_text)));
console.log(`Node analyze: ${cases.length} complete success/error reports; exact golden bytes, repeat and MoonBit format_text passed (${process.version}).`);
