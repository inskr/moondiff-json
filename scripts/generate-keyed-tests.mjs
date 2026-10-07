// Test-only fixture metadata; input documents remain strings for MoonBit.
import { readFileSync, writeFileSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { resolve } from 'node:path';
import assert from 'node:assert/strict';
const cases = JSON.parse(readFileSync('fixtures/keyed/cases.json', 'utf8'));
const q = JSON.stringify;
const option = v => v === null ? 'None' : `Some(${q(v)})`;
const content = '// Generated from fixtures/keyed/cases.json by scripts/generate-keyed-tests.mjs.\n' + cases.map(c => {
  const rows = c.changes.map(([kind, old, next, before, after]) =>
    `(${q(kind)}, ${option(old)}, ${option(next)}, ${before !== null}, ${option(before)}, ${after !== null}, ${option(after)})`).join(',\n');
  const identities = c.identities.map(i => i === null ? 'None' :
    `Some((${option(i[0])}, ${option(i[1])}, ${q(i[2])}, ${q(i[3])}))`).join(',\n');
  return `\n///|\ntest ${q(c.name)} {\nlet (s,c) = basic_result(${q(c.old)}, ${q(c.new)}, keyed_options(${q(c.path)}, ${q(c.key)}, ${c.order}))\nassert_eq(summary_counts(s), (${c.counts.join(', ')}))\nassert_eq(change_rows(c), [${rows}])\nassert_eq(identity_rows(c), [${identities}])\n}\n`;
}).join('');
const formatter = spawnSync(resolve('.tools/moon/bin/moonfmt.exe'), ['-'], {
  input: content, encoding: 'utf8', windowsHide: true,
});
if (formatter.error) throw formatter.error;
if (formatter.status !== 0) throw new Error(formatter.stderr);
const formatted = formatter.stdout.replaceAll('\r\n', '\n');
const target = 'src/diff/keyed_array_test.mbt';
if (process.argv.includes('--check')) {
  assert.equal(readFileSync(target, 'utf8').replaceAll('\r\n', '\n'), formatted);
  console.log(`${cases.length} saved keyed fixtures match their executable MoonBit assertions.`);
} else writeFileSync(target, formatted);
