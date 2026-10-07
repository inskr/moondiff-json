// Transport default only. Parsing, comparison and both renderers are MoonBit.
import { analyze as coreAnalyze, format_text, probe_document } from './moondiff-json-core.mjs';

export function analyze(oldText, newText, optionsText = '{}') {
  return coreAnalyze(oldText, newText, optionsText);
}

export { format_text, probe_document };
