# MoonDiff JSON 本地演示与实际录像

目前核心、CLI 和静态网页均可运行；还未公开部署或报名提交。
本文件包含可复现步骤和任务 8 的真实录像；性能记录见 ../bench/results.md。

## 录像与复现

[观看 / 下载 WebM](demo/moondiff-json.webm)，1440×1080，约 2 分 31 秒，25 fps。
实际 Chrome 页面由 Playwright 自动操作，中文字幕在录制会话内叠加；无配音、无倍速。
时间和 SHA256 见 [recording.json](demo/recording.json)，字幕另存 [captions.vtt](demo/captions.vtt)。
依次展示配置忽略、唯一键与双侧路径、共有身份重排、相邻大整数、重复身份错误和复现命令。
六个下载均对照完整黄金报告字节验证。脚本或截图不是录像的替代物，WebM 为实际编码文件。

重新录制（需安装仅用于开发的固定 Playwright FFmpeg revision）：

```powershell
.\scripts\moon.ps1 version --all
$env:PLAYWRIGHT_BROWSERS_PATH = Join-Path (Get-Location) 'work/playwright-runtime'
& node.exe node_modules/playwright-core/cli.js install ffmpeg
& npm.cmd run demo:record
& node.exe scripts/verify-demo.mjs
```

recording 与 verify-demo 将生成视频、元信息和七个抽帧，现有录像文件会被替换。
原始脚本日志在 docs/validation/task8-demo-record.log；软件本身不依赖 FFmpeg。

## 启动

按 README 安装项目内的固定工具链和依赖，然后在项目根目录运行：

```powershell
.\scripts\moon.ps1 version --all
& node.exe scripts/build-js.mjs
& node.exe scripts/serve.mjs
```

打开终端实际打印的 localhost `/web/` 地址。等待“核心就绪”。
本地服务只提供八项网页／构建资源，根地址重定向至 `/web/`；只接受 GET/HEAD。
比较时原始 JSON 通过浏览器内的 Worker 消息传递，不发送到 HTTP 服务。
工具链或依赖首次安装可能需要联网；页面没有运行时 CDN。

## A：配置审查

1. 点击“配置审查”，检查旧／新文档及 options。示例载入不自动比较。
2. 点击“比较 JSON”：仅 `/timeout` 的 30 → 60 为 modified。
3. 对象换序不产生变化；`/generated_at` 被忽略，ignored_subtrees 为 1。
4. 展开“本次比较选项”，确认报告使用的原始 options。
5. 下载 JSON；清除 ignore_paths 后重新比较，看到生成时间也成为变化。

CLI 对应输入：

```powershell
& node.exe cli/moondiff-json.mjs examples/config/old.json examples/config/new.json --options examples/config/options.json --format json
# 预期退出码 1，报告只有一条 modified
$LASTEXITCODE
```

## B：API 用户数组

1. 点击“API 用户数组”并比较。显式 array_rules 按 id 匹配，只报告 b 的 quota 20 → 21。
2. 在同一行检查 OLD `/users/1/quota`、NEW `/users/2/quota`，身份为字符串 `"b"`。
3. 将选项替换为下面的原始文本，再比较，增加一条 reordered：

```json
{"array_rules":[{"path":"/users","key":"id","check_order":true}]}
```

4. 将“显示变化”设为重排或修改，确认上方统计保持不变，下载仍包含完整报告。
5. 默认 by_key 忽略共有身份的顺序；“相等”始终表示当前策略下相等。

## C：精度与错误

1. 点击“精确大整数”并比较：9007199254740992 与 9007199254740993 产生一条 modified。
2. 检查根路径为 `""`，前后片段仍是原始数字字符串；不经 JS Number 改写。
3. 点击“重复身份错误”并比较：整数身份 1 与 1.0 重复，返回 INVALID_ARRAY_KEY，
   new 侧路径为 `/users/1/id`；不降级为位置比较，不显示部分成功统计。
4. 错误报告也可下载。将输入改为非法 JSON、重复对象键或未知 options 字段，查看位置和侧别。

## 客户端保护与离线

输入变化立即使旧结果和下载失效；文件导入使用严格 UTF-8，并保留 BOM 交给核心验证。
文件读取期间不能比较；读取中的旧文件结果不能覆盖更新的文本、文件或示例。
非法 UTF-8 文件会阻止沿用旧内容成功比较，替换或编辑相应字段后恢复。

运行中可取消，或再按一次比较开始新的请求。单次 5 秒未完成则显示 WORKER_TIMEOUT，
终止该 Worker；再次比较创建新的 Worker。Worker 内部失败显示 WORKER_ERROR。
这两类运行错误没有可下载的核心 envelope。

保持本地服务运行，页面及核心载入后断开外部网络，可比较三个演示并下载。
测试还通过浏览器 network offline 模式验证了预载 Worker 中的三个报告。
取消／超时后重建 Worker 会读取本地静态资源；刷新离线加载不是 v1 PWA 目标。

## 真实验收与范围

`scripts/verify-task7.ps1` 实际退出 0：101 项核心测试、49 项 CLI、7 项 Worker 状态、
34 项产品网页测试通过。15 个网页下载报告逐字节匹配直接 bridge 和 CLI。
实际 Chrome 154.0.8037.98、Node 22.23.3、Windows 11 x64 10.0.22631、i7-12700H。
Linux 尚未验证。

Worker 超时／晚到／失败测试采用测试工具控制的实际浏览器 Worker，
并且保留相同 MoonBit analyze；不在产品代码中加测试开关。
原始记录包含一次约 5048.4 ms 的受控停顿超时；这是保护逻辑验证，未作为核心性能基准。
所有 HTTP 请求均为 localhost GET；没有 CDN、上传或遥测请求。

日志在 docs/validation/task7-*.log，原始浏览器记录在 task7-browser-result.json。
实际桌面与窄屏截图保存在本地 output/playwright/task7-*.png，已检查布局、长值、中文、
null／缺失和身份路径；该目录为可再生成的忽略产物。
任务 7 功能保持冻结。任务 8 已补统一验收、真实基准、CI 配置、干净重建和材料；
CI 尚未在远程运行。录像经 Chrome 解码验证 150.92 秒、1440×1080，七个场景均不同，
并已目视检查唯一键双侧路径、相邻大整数与错误画面。见 demo/playback-verification.json。
