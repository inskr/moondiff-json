import { access } from 'node:fs/promises';
import { spawn } from 'node:child_process';
import { chromium } from 'playwright-core';
export async function launchBrowser() {
  for (const candidate of [process.env.MOONDIFF_BROWSER, 'C:/Program Files/Google/Chrome/Application/chrome.exe', 'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe', chromium.executablePath()].filter(Boolean)) {
    try { await access(candidate); } catch { continue; }
    return chromium.launch({ executablePath: candidate, headless: true, args: ['--disable-extensions'] });
  }
  throw new Error('Set MOONDIFF_BROWSER to installed Chromium or install pinned playwright-core Chromium.');
}
export async function startServer() {
  const server = spawn(process.execPath, ['scripts/serve.mjs'], { windowsHide: true, stdio: ['ignore', 'pipe', 'pipe'] });
  try {
    const base = await new Promise((resolve, reject) => {
      const timer = setTimeout(() => reject(new Error('Server startup timeout')), 10000);
      server.stdout.on('data', data => {
        const url = String(data).match(/http:\/\/127\.0\.0\.1:\d+\/web\//)?.[0];
        if (url) { clearTimeout(timer); resolve(url); }
      });
      server.once('error', error => { clearTimeout(timer); reject(error); });
      server.once('exit', code => { clearTimeout(timer); reject(new Error(`Server exited ${code}`)); });
      server.stderr.on('data', data => process.stderr.write(data));
    });
    return { server, base };
  } catch (error) { server.kill(); throw error; }
}
