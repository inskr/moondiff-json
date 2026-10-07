import { analyze, client_error } from '../dist/moondiff-json.mjs';

postMessage({ type: 'ready' });
self.onmessage = ({ data }) => {
  const { request_id } = data;
  try {
    let report_text;
    if (data.type === 'analyze') {
      report_text = analyze(data.old_text, data.new_text, data.options_text);
    } else if (data.type === 'client_error') {
      report_text = client_error(data.code, data.message, data.side);
    } else {
      throw new Error('Unknown Worker request');
    }
    postMessage({ type: 'result', request_id, report_text });
  } catch (error) {
    // Unexpected failures stay transport failures, never fake input reports.
    postMessage({ type: 'failure', request_id, message: error.message });
  }
};
