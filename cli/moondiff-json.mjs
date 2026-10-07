#!/usr/bin/env node
import { readFile } from 'node:fs/promises';

const help = `Usage: moondiff-json old.json new.json [--format text|json] [--options options.json]

Compare strict UTF-8 JSON using the MoonBit core. Default format: text.
  --format text|json    Report on stdout; JSON preserves core bytes exactly
  --options FILE        Strict JSON comparison options (default: {})
  --help                Show this help (use alone)
  --version             Show the version (use alone)
  --                    End flags; allow filenames beginning with '-'

Exit codes: 0 equal under the selected policy, 1 differences, 2 input/runtime error.
Errors also produce diagnostics on stderr. Input files are never written back.
`;

class ClientError extends Error {
  constructor(code, message, side = '') {
    super(message);
    this.code = code;
    this.side = side;
  }
}

function parseArguments(args, config) {
  const files = [];
  const seen = new Set();
  let flags = true;
  for (let i = 0; i < args.length; i++) {
    const arg = args[i];
    if (flags && arg === '--') { flags = false; continue; }
    if (flags && arg.startsWith('-')) {
      if (arg !== '--format' && arg !== '--options') {
        throw new ClientError('INVALID_OPTIONS', `Unknown or misplaced argument: ${JSON.stringify(arg)}. See --help.`);
      }
      if (seen.has(arg)) throw new ClientError('INVALID_OPTIONS', `Duplicate argument: ${arg}`);
      seen.add(arg);
      const value = args[++i];
      if (value === undefined || value.startsWith('--')) {
        throw new ClientError('INVALID_OPTIONS', `Missing value for ${arg}`);
      }
      if (arg === '--format') {
        if (value !== 'text' && value !== 'json') {
          throw new ClientError('INVALID_OPTIONS', '--format must be text or json');
        }
        config.format = value;
      } else {
        config.optionsFile = value;
      }
    } else {
      files.push(arg);
    }
  }
  if (files.length !== 2) throw new ClientError('INVALID_OPTIONS', 'Expected exactly two input filenames. See --help.');
  config.files = files;
}

async function readText(filename, side) {
  let bytes;
  try {
    bytes = await readFile(filename);
  } catch (error) {
    throw new ClientError('IO_ERROR', `Cannot read ${JSON.stringify(filename)} (${error.code ?? 'read failed'})`, side);
  }
  try {
    // Preserve the BOM for MoonBit to strip exactly one and count original bytes.
    return new TextDecoder('utf-8', { fatal: true, ignoreBOM: true }).decode(bytes);
  } catch {
    throw new ClientError('ENCODING_ERROR', `Invalid UTF-8 in ${JSON.stringify(filename)}`, side);
  }
}

function emit(core, reportText, format) {
  // Parse the envelope only; user documents remain original strings throughout.
  const report = JSON.parse(reportText);
  process.stdout.write(format === 'json' ? reportText : core.format_text(reportText));
  if (!report.ok) {
    process.stderr.write(core.format_text(reportText));
    return 2;
  }
  return report.equal ? 0 : 1;
}

async function main() {
  const args = process.argv.slice(2);
  if (args.length === 1 && args[0] === '--help') {
    process.stdout.write(help);
    return 0;
  }
  if (args.length === 1 && args[0] === '--version') {
    const metadata = JSON.parse(await readFile(new URL('../package.json', import.meta.url), 'utf8'));
    process.stdout.write(`moondiff-json ${metadata.version}\n`);
    return 0;
  }
  const config = { format: 'text' };
  let argumentError;
  try {
    parseArguments(args, config);
  } catch (error) {
    if (!(error instanceof ClientError)) throw error;
    argumentError = error;
  }

  let core;
  try {
    core = await import('../dist/moondiff-json.mjs');
  } catch (error) {
    process.stderr.write(`moondiff-json: Cannot load built core. Run npm run build:js from the project directory.\n${error.message}\n`);
    return 2;
  }
  if (argumentError) {
    return emit(core, core.client_error(argumentError.code, argumentError.message, argumentError.side), config.format);
  }
  try {
    const optionsText = config.optionsFile === undefined ? '{}' : await readText(config.optionsFile, 'options');
    const oldText = await readText(config.files[0], 'old');
    const newText = await readText(config.files[1], 'new');
    return emit(core, core.analyze(oldText, newText, optionsText), config.format);
  } catch (error) {
    if (!(error instanceof ClientError)) throw error;
    return emit(core, core.client_error(error.code, error.message, error.side), config.format);
  }
}

main().then(code => { process.exitCode = code; }, error => {
  process.stderr.write(`moondiff-json: Runtime error: ${error.message}\n`);
  process.exitCode = 2;
});
