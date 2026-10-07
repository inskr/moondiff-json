# MoonDiff JSON

MoonBit JSON 结构化差异库，计划配套 Node CLI `moondiff-json` 与静态网页，
用于配置审查、API 回归和测试快照比较。当前仅完成任务 1：严格解析适配和 JS 桥接验证。
尚不能执行正式差异比较。

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

项目暂用本地模块名 `local/moondiff-json`，未发布。正式发布需替换为参赛者自己的 namespace。
项目代码使用 MIT；依赖来源和许可证见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。
