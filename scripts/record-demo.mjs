import assert from 'node:assert/strict';
import { mkdir, readFile, writeFile } from 'node:fs/promises';
import { performance } from 'node:perf_hooks';
import { createHash } from 'node:crypto';
import { launchBrowser, startServer } from './browser-tools.mjs';

const fixtures = JSON.parse(await readFile('fixtures/reports/cases.json','utf8'));
await mkdir('output/playwright',{ recursive:true });
await mkdir('docs/demo',{ recursive:true });
let browser, server, context;
const evidence = [], captions = [];
try {
  const started = await startServer(); server = started.server;
  browser = await launchBrowser();
  // Caption overlay belongs only to the recorded browser session, not product code.
  context = await browser.newContext({ viewport:{ width:1440,height:1080 }, acceptDownloads:true, bypassCSP:true, recordVideo:{ dir:'output/playwright',size:{ width:1440,height:1080 } } });
  const page = await context.newPage();
  const video = page.video();
  await page.goto(started.base);
  await page.waitForFunction(() => document.querySelector('#engine').dataset.ready === 'true');
  await page.evaluate(() => {
    const caption = document.createElement('div'); caption.id = 'recording-caption';
    Object.assign(caption.style,{ position:'fixed',bottom:'20px',left:'6%',width:'88%',padding:'18px',boxSizing:'border-box',background:'#0b1424',color:'#fff',border:'1px solid #4dc9c0',borderRadius:'12px',font:'22px/1.5 "Segoe UI", sans-serif',zIndex:'999',whiteSpace:'pre-line',boxShadow:'0 8px 32px #0009' });
    document.body.append(caption);
  });
  const start = performance.now();
  async function caption(text, seconds, placement = 'bottom') {
    const at = (performance.now() - start)/1000;
    captions.push({ start:at,end:at + seconds,text });
    await page.locator('#recording-caption').evaluate((node,{ text,placement }) => {
      node.textContent = text;
      node.style.top = placement === 'top' ? '20px' : 'auto';
      node.style.bottom = placement === 'bottom' ? '20px' : 'auto';
    },{ text,placement });
    console.log(`Recording ${at.toFixed(1)}s: ${text.split('\n')[0]}`);
    await page.screenshot({ path:`output/playwright/task8-demo-${captions.length}.png` });
    await new Promise(resolve => setTimeout(resolve,seconds*1000));
  }
  async function download(expected,name) {
    await page.locator('#compare').click();
    await page.waitForFunction(() => !document.querySelector('#download').disabled);
    const event = page.waitForEvent('download'); await page.locator('#download').click();
    const file = await event; assert.equal(await file.failure(),null);
    const text = await readFile(await file.path(),'utf8');
    assert.equal(text,JSON.stringify(expected));
    evidence.push({ name,report_sha256:createHash('sha256').update(text).digest('hex') });
  }
  await caption('MoonDiff JSON · MoonBit 结构化差异\n配置审查、API 回归、测试快照；同一核心驱动 CLI 与网页 Worker。',18);
  await page.locator('[data-example="config"]').click();
  await caption('01 配置审查\nignore_paths 显式忽略 /generated_at；对象字段换序不产生差异。',10);
  await download(fixtures[0].report,'config');
  await page.locator('#changes').scrollIntoViewIfNeeded();
  await caption('只报告 timeout: 30 → 60；ignored_subtrees = 1。\n下载的是 MoonBit 完整报告，筛选和分页不会改写报告。',18,'top');
  await page.locator('[data-example="api"]').click();
  await page.locator('#options-text').scrollIntoViewIfNeeded();
  await caption('02 API 用户数组\n显式配置 /users 按 id 匹配；默认忽略身份数组顺序。',10);
  await download(fixtures[1].report,'keyed');
  await page.locator('#changes').scrollIntoViewIfNeeded();
  await caption('用户 b 的 quota: 20 → 21。\nold_path /users/1/quota，new_path /users/2/quota；保留身份与双侧位置。',19,'top');
  await page.locator('#old-text').fill(fixtures[2].old);
  await page.locator('#new-text').fill(fixtures[2].new);
  await page.locator('#options-text').fill(fixtures[2].options);
  await download(fixtures[2].report,'checked-order');
  await page.locator('#changes').scrollIntoViewIfNeeded();
  await caption('check_order: true 时报告一条 reordered。\n只比较共有身份的相对顺序；新增或删除本身不构成重排。',19,'top');
  await page.locator('[data-example="precision"]').click();
  await download(fixtures[3].report,'precision');
  await page.locator('#changes').scrollIntoViewIfNeeded();
  assert.ok((await page.locator('#changes').textContent()).includes('9007199254740993'));
  await caption('03 精确数字\n9007199254740992 与 9007199254740993 不同。原始 token 比较与 json_text 展示；1、1.0、1e0 相等。',20,'top');
  await page.locator('[data-example="identity-error"]').click();
  await download(fixtures[6].report,'duplicate-identity');
  await page.locator('#error-panel').scrollIntoViewIfNeeded();
  await caption('身份 1 与 1.0 数值相同，报 INVALID_ARRAY_KEY。\n缺失、重复、非法身份均报错；不会自动退回位置比较。',20,'top');
  await page.locator('header').scrollIntoViewIfNeeded();
  await caption('本地复现：npm run acceptance / npm run bench / npm run serve\nMIT；已有 moondiff 面向 MoonBit 源码，本项目面向 JSON。仓库、部署、发布及报名待明确授权。',14);
  const elapsed = (performance.now() - start)/1000;
  assert.ok(elapsed >= 120 && elapsed <= 180,`Recording duration ${elapsed}`);
  const version = browser.version();
  await context.close(); context = undefined;
  await video.saveAs('docs/demo/moondiff-json.webm');
  const bytes = await readFile('docs/demo/moondiff-json.webm');
  assert.ok(bytes.length > 100000,'Real encoded video must exist');
  const timestamp = s => { const ms = Math.round(s*1000); return `${String(Math.floor(ms/3600000)).padStart(2,'0')}:${String(Math.floor(ms/60000)%60).padStart(2,'0')}:${String(Math.floor(ms/1000)%60).padStart(2,'0')}.${String(ms%1000).padStart(3,'0')}`; };
  await writeFile('docs/demo/captions.vtt','WEBVTT\n\n' + captions.map((c,i) => `${i+1}\n${timestamp(c.start)} --> ${timestamp(c.end)}\n${c.text}\n`).join('\n'));
  await writeFile('docs/demo/recording.json',JSON.stringify({ recorded_at:new Date().toISOString(),browser:version,node:process.version,duration_wall_seconds:elapsed,width:1440,height:1080,mode:'Real automated browser recording with Chinese caption overlay, no voiceover; no accelerated playback.',bytes:bytes.length,sha256:createHash('sha256').update(bytes).digest('hex'),download_checks:evidence,captions },null,2) + '\n');
  console.log(`Recorded ${elapsed.toFixed(2)}s, ${bytes.length} bytes, six exact golden downloads; docs/demo/moondiff-json.webm`);
} finally { await context?.close(); await browser?.close(); server?.kill(); }
