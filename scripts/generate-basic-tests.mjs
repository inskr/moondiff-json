// Test-only fixture reader. Documents remain strings passed to MoonBit parsing.
import { readFileSync, writeFileSync } from 'node:fs';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
const cases = JSON.parse(readFileSync('fixtures/basic/cases.json', 'utf8'));
const q = JSON.stringify;
const option = value => value === null ? 'None' : `Some(${q(value)})`;
const content = '// Generated from fixtures/basic/cases.json by scripts/generate-basic-tests.mjs.\n' + cases.map(c => {
  const rows = c.changes.map(([kind, old, next, before, after]) =>
    `(${q(kind)}, ${option(old)}, ${option(next)}, ${before !== null}, ${option(before)}, ${after !== null}, ${option(after)})`).join(',\n    ');
  return `\n///|\ntest ${q(c.name)} {\n  let (summary, changes) = basic_result(${q(c.old)}, ${q(c.new)}, @model.Options::default())\n  assert_eq(summary_counts(summary), (${c.counts.join(', ')}))\n  assert_eq(change_rows(changes), [\n    ${rows}\n  ])\n}\n`;
}).join('');
const target = 'src/diff/basic_test.mbt';
const formatter = spawnSync('moonfmt', ['-'], {
  input: content, encoding: 'utf8', windowsHide: true,
});
if (formatter.error) throw formatter.error;
if (formatter.status !== 0) throw new Error(formatter.stderr);
const formatted = formatter.stdout.replaceAll('\r\n', '\n');
if (process.argv.includes('--check')) {
  assert.equal(readFileSync(target, 'utf8').replaceAll('\r\n', '\n'), formatted,
    'Regenerate fixture tests: Node 22 scripts/generate-basic-tests.mjs');
  console.log(`${cases.length} saved basic fixtures match their executable MoonBit assertions.`);
} else writeFileSync(target, formatted);
