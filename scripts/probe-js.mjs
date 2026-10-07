import assert from 'node:assert/strict';
import { mkdir, writeFile } from 'node:fs/promises';
import { probe_document } from '../dist/moondiff-json.mjs';
import { probeCases } from './probe-cases.mjs';

// User JSON is passed verbatim to MoonBit. Only diagnostic envelopes are parsed.
const outputs = [];
for (const { name, input, json_text, code } of probeCases) {
  const output = probe_document(input);
  assert.equal(typeof output, 'string');
  assert.notEqual(output, '', 'MoonBit export must return a diagnostic');
  const result = JSON.parse(output);
  assert.equal(result.probe_version, '1');
  assert.equal(result.ok, code === undefined, name);
  if (code) {
    assert.equal(result.code, code, name);
    assert.ok(result.line >= 1 && result.column >= 1, name);
  } else {
    assert.equal(result.json_text, json_text, name);
  }
  outputs.push(output);
}
assert.equal(probe_document('1e400'), probe_document('1e400'));
await mkdir(new URL('../work/probes/', import.meta.url), { recursive: true });
await writeFile(new URL('../work/probes/node-results.json', import.meta.url), JSON.stringify(outputs));
console.log(`Node probe: ${probeCases.length} cases plus deterministic repeat passed`);
