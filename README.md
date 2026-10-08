# MoonDiff JSON

MoonBit JSON 结构化差异库，配套 Node CLI `moondiff-json` 与静态网页，
用于配置审查、API 回归和测试快照比较。核心、CLI 和网页可用：
严格解析、精确数字、对象／位置数组／唯一键数组比较、忽略规则和确定性 JSON／文字报告。
共享 JS 字符串入口 `analyze` 已通过 Node 和真实浏览器 Worker 验证。
统一验收、真实性能记录和参赛材料见下文；公开仓库、站点、包和报名尚未提交。

生态已有 [moonbit-community/moondiff](https://mooncakes.io/docs/moonbit-community/moondiff)，
主要比较 MoonBit 源码。本项目针对 JSON 数据结构，不宣称生态首创。

## 从干净源码重建（Windows x64）

在源码根目录、PowerShell 中顺序执行。首次需要网络以及已安装的 Chrome 或 Edge。
不要复制 dist、_build、node_modules 或 .mooncakes；它们由命令重新生成。

```powershell
.\scripts\setup-windows.ps1
.\scripts\moon.ps1 version --all
& npm.cmd ci
& moon.exe update
& npm.cmd run acceptance
& npm.cmd run bench
& npm.cmd run prepare:local
& npm.cmd run serve
```

每条命令退出非零时先解决错误再继续。setup 只安装到本项目 .tools，不改用户 PATH 或执行策略；
moon.ps1 只设置当前进程环境。固定 Node 22.23.3、moon 0.1.20260920、moonc/core 0.10.14+7d59c7ec9、
moonjson 0.4.0 和 playwright-core 1.63.0。官方 MoonBit/core 归档链接标示 2026-11-20 到期；
之后需重新选择并验证工具链，见 [环境与 SHA256](docs/environment.md)。Linux 尚未测试。

acceptance 运行 MoonBit 格式、deny-warn 检查、101 项测试、release JS 构建、黄金夹具和 Document
编译边界、49 项 CLI（含退出码 0/1/2）、7 项 Worker、34 项真实网页，以及 seed 539365384 的
225 个属性案例。三端黄金报告和 15 个生成案例逐字节一致。失败样本保存到 work/property-failures，
终端给出 --replay 命令，CI 保留样本。--mutate-equal 仅用于证明断言拒绝错误适配器，不进入产品。

bench 独立运行，每项预热 5 次、测量 20 次，包含解析、校验、精确比较和 JSON 报告，
排除 IO、启动和呈现，不作为 CI 机器相关硬门槛。
主案例每侧约 1 MiB、10000 记录、10 字段变化：位置中位数 77.559 ms，唯一键中位数 99.421 ms。
完整结果、版本和原始样本见 [bench/results.md](bench/results.md) 与 [bench/results.json](bench/results.json)。
2026-10-08 本机统一验收通过，见 [日志](docs/validation/task8-acceptance.log)。
从提交 9c0d4dd 的源码归档在新目录重建并再次完整验收通过，
只复用会重新校验 SHA256 的工具下载归档，没有复制任何构建或依赖安装输出；
见 [干净重建日志](docs/validation/task8-clean-rebuild.log)。两目录生成的核心 JS SHA256 相同。

[CI 配置](.github/workflows/ci.yml) 覆盖 ubuntu-24.04 和 windows-2022，固定工具/依赖和 action SHA；
浏览器用 Playwright 固定 Chromium revision。远程 CI 尚未运行，**Linux 尚未实测**。
任务 9 的本地/CI 命令、手动触发、日志与产物下载、推送授权后的步骤见
[远程 CI 与 Linux 验证](docs/ci-linux.md)。
prepare:local 在 work/release/moondiff-json-0.1.0 准备 CLI、网页、许可文本与 SHA256 清单，不执行发布。
运行分发须保留 LICENSE、THIRD_PARTY_NOTICES.md 与 licenses/，以及两个 dist 模块。
任务 9 运行包另含独立服务器，解压后用 Node 22 执行 `npm run serve` 即可打开网页。
`npm run prepare:release` 从干净的已提交源码重新构建、检查运行包、打包并解压再验，
输出到 `work/release/task9/`；任务 8 的根目录 ZIP 为历史交付，不代表任务 9 源码。

参赛材料：[一页说明](docs/project-one-pager.md)、[生态对比与边界](docs/ecosystem.md)、
[AI 使用说明](docs/ai-usage.md)、[演示步骤与录像](docs/demo.md)。下面保留历史阶段说明；
阶段结果以各自日期与日志为准。

## CLI 运行与验证（Windows x64）

已按下面的环境准备步骤安装工具链后，在项目根目录运行：

```powershell
# 设置当前进程的固定 MoonBit / Node 22 工具路径，再构建
.\scripts\moon.ps1 version --all
& node.exe scripts/build-js.mjs

& node.exe cli/moondiff-json.mjs --help
& node.exe cli/moondiff-json.mjs --version
& node.exe cli/moondiff-json.mjs examples/config/old.json examples/config/new.json --options examples/config/options.json
# 上面的配置审查示例只有 timeout 变化，预期退出码 1
$LASTEXITCODE
& node.exe cli/moondiff-json.mjs examples/config/old.json examples/config/new.json --options examples/config/options.json --format json
```

语法：`node cli/moondiff-json.mjs old.json new.json [--format text|json] [--options options.json]`。
默认文字输出；选项默认 `{}`。`--help`、`--version` 单独使用。
路径有空格时加引号；以 `-` 开头的输入文件名可放在 `--` 后：

```powershell
& node.exe cli/moondiff-json.mjs 'C:\data\old config.json' 'C:\data\new config.json' --format json
& node.exe cli/moondiff-json.mjs --format json -- '-old.json' '-new.json'
```

报告写 stdout，错误诊断写 stderr。JSON 模式直接输出核心报告字节，末尾不额外加换行，
可单独保存 stdout；错误报告没有 summary 或部分 changes。
退出码 **0** 表示指定策略下相等，**1** 表示有变化，**2** 表示参数、输入、IO 或运行错误。
CI 应分别处理 0 和 1；1 是正常差异结果。构建产物缺失时退出 2，stderr 提示构建命令；
此时无法调用核心生成报告，stdout 为空。

文件均严格按 UTF-8 解码，包含两份文档和 options；拒绝非法字节序列。
保留 BOM 交给核心只剥离开头的一个，原始字节仍计入限额。
文档和 options 的原始字符串直接传给 analyze，不经过 JS JSON.parse，不写回输入文件。
所有比较、选项校验、JSON 和文字报告由 MoonBit 生成；JS 只读取报告 envelope 确定退出码。
资源上限和唯一键规则见 [docs/reports-and-options.md](docs/reports-and-options.md)。

完整验收及独立 CLI 烟测命令：

```powershell
.\scripts\verify-task6.ps1
# 已构建后，可只运行进程级烟测；也可 npm run cli:smoke
& node.exe scripts/cli-smoke.mjs
```

烟测覆盖 0/1/2、7 个黄金报告和 8 个错误夹具、默认/显式文字和 JSON、缺文件、目录输入、
三侧非法 UTF-8、未知/重复/缺值参数、带空格及中文路径、`--`、BOM、字节上限、
无构建时的帮助与版本，以及输入文件字节保持不变。
完整验收另运行全部核心测试、JS 检查与 release build、真实浏览器模块 Worker。
实际结果：**101/101 核心测试、49/49 CLI 烟测**；15 项报告和文字在 bridge、CLI 与
Chrome 154.0.8037.98 Worker 间逐字节一致。
环境为 Windows 11 x64、Node 22.23.3；**Linux 尚未测试**。
原始记录见 [docs/validation/task6-final.log](docs/validation/task6-final.log)。
当前 package 保持 private，仅注册 bin 名称，未发布到 npm。

## 静态网页（任务 7）

在完成环境准备后，在项目根目录运行：

```powershell
.\scripts\moon.ps1 version --all
& node.exe scripts/build-js.mjs
& node.exe scripts/serve.mjs
```

浏览器打开终端打印的 `http://127.0.0.1:<端口>/web/`；默认由系统选择端口。
也可运行 `npm run serve`，或通过 `npm run serve -- --port 8080` 指定端口。
按 Ctrl+C 停止服务。网页使用模块 Worker，需要 HTTP 服务。
静态部署所需文件为完整 `web/` 和两个 `dist/*.mjs`，保持目录相对位置；目前仅本地准备，未部署。

页面支持旧／新 JSON、options 输入与 UTF-8 文件导入，显式比较、取消、示例载入、
四类计数、双侧路径、身份上下文、保真片段、筛选、分页和完整 JSON 下载。
每页最多显示 100 条并标明范围；筛选和分页不改变统计或下载报告。
输入修改后旧报告失效；非法 UTF-8 文件保持错误状态，直到替换或重新编辑该侧。
`present` 与原始 `json_text` 区分缺失、真实 null 和大整数；用户值通过文本节点显示。

比较及报告由相同 MoonBit analyze 完成。Worker 请求带递增 ID；新比较、输入修改、取消或
5 秒超时会使旧请求失效，必要时终止 Worker，下一次比较重建。
WORKER_TIMEOUT／WORKER_ERROR 是页面运行错误，不伪造核心报告；核心输入错误可下载固定错误 envelope。
载入页面并等待“核心就绪”后可离线比较、下载；取消或超时后的 Worker 重建从本地服务读取资源。
刷新离线加载不属于 v1 范围。服务仅绑定 localhost，提供静态资源，没有上传端点、CDN 或遥测。

完整验收和独立网页烟测：

```powershell
.\scripts\verify-task7.ps1
# 已构建且工具路径就绪后，也可 npm run web:smoke
& node.exe scripts/web-smoke.mjs
```

2026-10-07 实测：101/101 核心、49/49 CLI、7/7 Worker 状态、34/34 真实 Chrome 网页用例通过。
15 项网页下载报告与 bridge、CLI 逐字节一致；实际验证取消、旧结果、5 秒超时、恢复、
文件读取竞态、非法 UTF-8、中文长值、390px 窄屏和浏览器断网后的三个演示。
网络记录只有本地静态 GET，无上传或外部请求。
Windows 11 x64、Node 22.23.3、Chrome 154.0.8037.98；Linux 尚未测试。
见 [完整日志](docs/validation/task7-final.log)、[原始浏览器记录](docs/validation/task7-browser-result.json)
和 [演示步骤](docs/demo.md)。本阶段功能范围已冻结；未将超时保护测试当作正式性能基准。

## 任务 1 复现（Windows x64）

```powershell
.\scripts\setup-windows.ps1
& .\.tools\node-v22.23.3-win-x64\npm.cmd ci
.\scripts\verify-task1.ps1
```

需要首次联网下载依赖及一个已安装的 Chrome/Edge。
可设置 `$env:MOONDIFF_BROWSER` 为 Chromium 可执行文件的绝对路径。
工具链只装到本项目 `.tools`；不用修改用户 PATH 或执行策略。
如果系统拒绝运行本地 PowerShell 脚本，应按自己的执行策略处理。

验证运行 MoonBit check/test/build、Node 字符串桥接和浏览器模块 Worker，
将 Node 与 Worker 的 12 个解析诊断逐字节比较。
诊断导出 `probe_document(String) -> String` 专供任务 1，
它不是 `analyze` 的最终报告格式。JS 不解析输入文档，只解析诊断 envelope。

环境、依赖选择、真实结果与当前限制见 [docs/environment.md](docs/environment.md)。
实施基线见 [docs/spec.md](docs/spec.md)、[docs/plan.md](docs/plan.md)，
进度见 [docs/progress.md](docs/progress.md)。

## 任务 2 验证

```powershell
.\scripts\verify-task2.ps1
```

在上述环境准备后运行，覆盖全部 MoonBit 核心测试、受控 Document 编译边界、
JS 构建，以及任务 1 的 Node/浏览器 Worker 回归。
数字、Pointer 和模型说明见 [docs/model-and-primitives.md](docs/model-and-primitives.md)。

## 任务 3 验证

```powershell
.\scripts\verify-task3.ps1
```

覆盖 15 个保存的基础夹具、忽略校验、对称性、确定性和不修改输入，运行全部
MoonBit 测试及 JS check/build，并复跑 Node/Chrome Worker 解析桥接；任务 3 完成时为 51 项核心测试。
用法和阶段边界见 [docs/basic-comparison.md](docs/basic-comparison.md)。
正式报告的字节契约由任务 5 实现，三端差异报告一致性由后续客户端任务验收。

## 任务 4 验证

```powershell
.\scripts\verify-task4.ps1
```

验证 15 个唯一键夹具、身份错误与资源边界，以及全部核心测试；任务 4 完成时为 76 项。
10000 身份反序用例默认报告零变化，开启顺序检查报告一条 reordered。
完整 JS 检查、构建和 Node/Chrome Worker 解析桥接回归一并执行。
比较策略和身份排序见 [docs/semantics.md](docs/semantics.md)。

## 核心 MVP（任务 5）

```powershell
.\scripts\verify-task5.ps1
```

构建生成 `dist/moondiff-json.mjs` 和其依赖 `dist/moondiff-json-core.mjs`，两者必须同时保留。
Node 22 或浏览器模块 Worker 可使用相同接口：

```javascript
import { analyze, format_text } from './dist/moondiff-json.mjs';

const report = analyze('9007199254740992', '9007199254740993', '{}');
console.log(report);            // 完整 JSON 报告字符串
console.log(format_text(report));
```

传入原始文档字符串；不要先用 JS JSON.parse 解析文档。
省略第三参数时默认 `{}`；输入或配置错误由 analyze 返回固定错误 envelope。
format_text 对损坏报告抛 `MoonDiffFormatError`，其 report_text 是 MoonBit 生成的错误报告。
严格选项、资源上限与报告契约见 [docs/reports-and-options.md](docs/reports-and-options.md)。

实测：98/98 核心测试、7 个完整报告黄金夹具、8 个错误案例通过；
Node 和真实 Chrome Worker 的 15 项完整报告及文字输出逐字节相同。
包含三组演示：配置审查、API 用户数组、精确大整数及重复身份错误。

项目暂用本地模块名 `local/moondiff-json`，未发布。正式发布需替换为参赛者自己的 namespace。
项目代码使用 MIT；依赖来源和许可证见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。
