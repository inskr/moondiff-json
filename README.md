# MoonDiff JSON

MoonBit JSON 结构化差异库，计划配套 Node CLI `moondiff-json` 与静态网页，
用于配置审查、API 回归和测试快照比较。当前完成任务 1–5，核心 MVP 可用：
严格解析、精确数字、对象／位置数组／唯一键数组比较、忽略规则和确定性 JSON／文字报告。
共享 JS 字符串入口 `analyze` 已通过 Node 和真实浏览器 Worker 验证。
CLI、产品网页和正式性能基准仍待任务 6–8。

生态已有 [moonbit-community/moondiff](https://mooncakes.io/docs/moonbit-community/moondiff)，
主要比较 MoonBit 源码。本项目针对 JSON 数据结构，不宣称生态首创。

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
