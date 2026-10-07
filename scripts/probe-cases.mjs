// These are raw input strings, never JS-parsed user documents.
export const probeCases = [
  { name: 'large integer A', input: '9007199254740992', json_text: '9007199254740992' },
  { name: 'large integer B', input: '9007199254740993', json_text: '9007199254740993' },
  { name: 'huge exponent', input: '1e400', json_text: '1e400' },
  { name: 'emoji', input: '"🌙"', json_text: '"🌙"' },
  { name: 'numeric spellings', input: '[1,1.0,1e0,-0]', json_text: '[1,1.0,1e0,-0]' },
  { name: 'BOM', input: '\uFEFF1', json_text: '1' },
  { name: 'duplicate key', input: '{"a":1,"a":2}', code: 'DUPLICATE_KEY' },
  { name: 'duplicate decoded key', input: '{"a":1,"\\u0061":2}', code: 'DUPLICATE_KEY' },
  { name: 'depth 64', input: '['.repeat(64) + '0' + ']'.repeat(64), json_text: '['.repeat(64) + '0' + ']'.repeat(64) },
  { name: 'depth 65', input: '['.repeat(65) + '0' + ']'.repeat(65), code: 'DEPTH_LIMIT' },
  { name: 'parse-time guard', input: '['.repeat(10000), code: 'DEPTH_LIMIT' },
  { name: 'trailing document', input: '1 2', code: 'PARSE_ERROR' },
];
