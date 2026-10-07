import { readFileSync, writeFileSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { resolve } from 'node:path';
import assert from 'node:assert/strict';
const cases = JSON.parse(readFileSync('fixtures/reports/cases.json','utf8'));
const q = JSON.stringify;
const content = '// Generated from fixtures/reports/cases.json; input documents stay strings.\n' + cases.map(c =>
  `\n///|\ntest ${q(c.name)} {\nlet result = @bridge.analyze(${q(c.old)},${q(c.new)},${q(c.options)})\nassert_eq(result, ${q(q(c.report))})\nfor _ in 0..<3 { assert_eq(@bridge.analyze(${q(c.old)},${q(c.new)},${q(c.options)}),result) }\nassert_true(@bridge.format_text(result).length()>0)\n}\n`).join('');
const result = spawnSync(resolve('.tools/moon/bin/moonfmt.exe'),['-'],{input:content,encoding:'utf8',windowsHide:true});
if (result.error) throw result.error;
if (result.status !== 0) throw new Error(result.stderr);
const formatted = result.stdout.replaceAll('\r\n','\n');
const file = 'src/bridge/report_fixtures_test.mbt';
if (process.argv.includes('--check')) { assert.equal(readFileSync(file,'utf8').replaceAll('\r\n','\n'),formatted); console.log(`${cases.length} full report fixtures match executable assertions.`); }
else writeFileSync(file,formatted);
