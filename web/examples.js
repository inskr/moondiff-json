// Raw demonstration strings only; no precomputed reports or JS input parsing.
export const examples = {
  config: {
    old: '{\n  "timeout": 30,\n  "generated_at": "old",\n  "stable": true\n}',
    new: '{\n  "stable": true,\n  "generated_at": "new",\n  "timeout": 60\n}',
    options: '{"ignore_paths":["/generated_at"]}',
  },
  api: {
    old: '{"users":[{"id":"a","quota":10},{"id":"b","quota":20},{"id":"c","quota":30}]}',
    new: '{"users":[{"id":"c","quota":30},{"id":"a","quota":10},{"id":"b","quota":21}]}',
    options: '{"array_rules":[{"path":"/users","key":"id"}]}',
  },
  precision: { old: '9007199254740992', new: '9007199254740993', options: '{}' },
  'identity-error': {
    old: '{"users":[]}', new: '{"users":[{"id":1},{"id":1.0}]}',
    options: '{"array_rules":[{"path":"/users","key":"id"}]}',
  },
};
