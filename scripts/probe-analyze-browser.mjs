import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { access, writeFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import { chromium } from 'playwright-core';

const root = fileURLToPath(new URL('../', import.meta.url));
const server = spawn(process.execPath, ['scripts/probe-serve.mjs'], {
  cwd: root, windowsHide: true, stdio: ['ignore', 'pipe', 'pipe'],
});
let browser;
try {
  const url = await new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error('Probe server did not start')), 10000);
    server.stdout.on('data', data => {
      const match = String(data).match(/http:\/\/127\.0\.0\.1:\d+\//);
      if (match) { clearTimeout(timer); resolve(match[0]); }
    });
    server.once('error', error => { clearTimeout(timer); reject(error); });
    server.once('exit', code => { clearTimeout(timer); reject(new Error(`Server exited ${code}`)); });
    server.stderr.on('data', data => process.stderr.write(data));
  });
  const candidates = [
    process.env.MOONDIFF_BROWSER,
    'C:/Program Files/Google/Chrome/Application/chrome.exe',
    'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe',
  ].filter(Boolean);
  let executablePath;
  for (const candidate of candidates) {
    try { await access(candidate); executablePath = candidate; break; } catch {}
  }
  if (!executablePath) throw new Error('Set MOONDIFF_BROWSER to an installed Chromium browser');
  browser = await chromium.launch({ executablePath, headless: true, args: ['--disable-extensions'] });
  const page = await browser.newPage();
  const errors = [];
  page.on('pageerror', error => errors.push(error.message));
  await page.goto(url + 'analyze.html');
  // Real clock: virtual-time dump-dom can run the timeout before the Worker loads.
  await page.waitForFunction(() => /^(PASS|FAIL):/.test(document.querySelector('#result').textContent), null, { timeout: 10000 });
  const result = await page.locator('#result').textContent();
  assert.ok(result.startsWith('PASS: 15 complete analyze reports equal Node bytes'), result);
  assert.deepEqual(errors, []);
  const evidence = {
    result, node: process.version, browser: browser.version(), executablePath,
    mode: 'headless; real-time module Worker; localhost HTTP',
  };
  await writeFile(new URL('../work/probes/analyze-browser-result.json', import.meta.url), JSON.stringify(evidence, null, 2));
  await page.screenshot({ path: fileURLToPath(new URL('../work/probes/analyze-worker.png', import.meta.url)) });
  console.log(result);
} finally {
  await browser?.close();
  server.kill();
}
