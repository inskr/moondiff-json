import assert from 'node:assert/strict';
import { readFile, writeFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { launchBrowser } from './browser-tools.mjs';
const bytes = await readFile('docs/demo/moondiff-json.webm');
const recorded = JSON.parse(await readFile('docs/demo/recording.json','utf8'));
assert.equal(createHash('sha256').update(bytes).digest('hex'),recorded.sha256);
const browser = await launchBrowser();
try {
  const context = await browser.newContext({ viewport:{ width:1440,height:1080 } });
  await context.route('http://demo.local/**',route => {
    if (!route.request().url().endsWith('.webm')) return route.fulfill({ contentType:'text/html',body:'<style>body{margin:0;background:#000}video{width:1440px;height:1080px}</style><video preload="auto" src="/video.webm"></video>' });
    const range = route.request().headers().range?.match(/^bytes=(\d+)-(\d*)$/);
    const start = range ? Number(range[1]) : 0;
    const end = range?.[2] ? Math.min(Number(range[2]),bytes.length-1) : bytes.length-1;
    return route.fulfill({ status:range ? 206 : 200,contentType:'video/webm',body:bytes.subarray(start,end+1),headers:{ 'Accept-Ranges':'bytes', ...(range ? { 'Content-Range':`bytes ${start}-${end}/${bytes.length}` } : {}) } });
  });
  const page = await context.newPage();
  await page.goto('http://demo.local/');
  await page.waitForFunction(() => document.querySelector('video').readyState >= 2);
  await page.locator('video').evaluate(async v => { v.muted = true; await v.play(); v.pause(); });
  const metadata = await page.locator('video').evaluate(v => ({ duration:v.duration,width:v.videoWidth,height:v.videoHeight }));
  assert.ok(metadata.duration >= 120 && metadata.duration <= 180,JSON.stringify(metadata));
  assert.equal(metadata.width,1440); assert.equal(metadata.height,1080);
  const frames = [];
  for (const time of [5,39,65,88,108,129,144]) {
    await page.locator('video').evaluate((v,time) => new Promise((resolve,reject) => {
      const timer = setTimeout(() => reject(new Error('Video seek timeout')),10000);
      v.addEventListener('seeked',async () => {
        await v.play();
        v.requestVideoFrameCallback(() => { v.pause(); clearTimeout(timer); resolve(); });
      },{ once:true });
      v.currentTime = time;
    }),time);
    const path = `output/playwright/task8-video-review-${time}.png`;
    // Compare actual decoded pixels, independent of the browser page layout.
    const data = await page.locator('video').evaluate(v => {
      const canvas = document.createElement('canvas');
      canvas.width = v.videoWidth; canvas.height = v.videoHeight;
      canvas.getContext('2d').drawImage(v,0,0);
      return canvas.toDataURL('image/png');
    });
    const frame = Buffer.from(data.split(',')[1],'base64');
    await writeFile(path,frame);
    frames.push({ time,path,sha256:createHash('sha256').update(frame).digest('hex') });
  }
  assert.equal(new Set(frames.map(f => f.sha256)).size,frames.length,'Real video must contain changing scenes');
  await writeFile('docs/demo/playback-verification.json',JSON.stringify({ node:process.version,browser:browser.version(),metadata,frames },null,2) + '\n');
  console.log(`Video playback verified: ${metadata.duration}s, ${metadata.width}x${metadata.height}, seven distinct seek frames decoded by Chrome.`);
} finally { await browser.close(); }
