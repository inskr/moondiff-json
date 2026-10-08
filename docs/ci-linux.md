# CI 与平台验证

公开仓库：https://github.com/inskr/moondiff-json 。工作流为 .github/workflows/ci.yml。

2026-10-08：Windows 本地统一验收与源码包干净重建通过；Ubuntu 24.04 远程统一验收、
运行包解压验证和源码/运行包生成已通过。首次 Windows CI 的安装日志相对路径问题已修复。
最新作业结果以 [Actions](https://github.com/inskr/moondiff-json/actions/workflows/ci.yml) 为准；
首个 Linux 实测证据为 [运行 37749721428](https://github.com/inskr/moondiff-json/actions/runs/37749721428/job/113219693323)。

## 本地执行

Windows PowerShell，在仓库根目录逐条执行，非零退出时停止：

```powershell
.\scripts\setup-windows.ps1
.\scripts\moon.ps1 version --all
npm.cmd ci
moon.exe update
npm.cmd run acceptance
npm.cmd run prepare:release
```

Linux x64 需 Bash、curl、sha256sum、tar、unzip、Git。安装脚本只处理项目工具，不安装系统组件。

```bash
set -euo pipefail
bash scripts/setup-linux.sh
source scripts/moon-env.sh
npm ci
moon update
node node_modules/playwright-core/cli.js install chromium
export MOONDIFF_BROWSER="$(node --input-type=module -e "import {chromium} from 'playwright-core'; console.log(chromium.executablePath())")"
npm run acceptance
npm run prepare:release
```

本机 Chromium 缺失系统库时由环境维护者准备；CI 用 install --with-deps chromium
在一次性 runner 中安装。Windows 本地可用 Chrome/Edge，也可通过 MOONDIFF_BROWSER 指定浏览器。
版本与校验和见 [环境](environment.md)。

## CI 和手动触发

工作流支持 push、pull_request、workflow_dispatch；覆盖 ubuntu-24.04 和 windows-2022。
从干净检出安装固定工具、npm ci、moon update 和锁定 Chromium，然后运行 npm run acceptance
和 npm run prepare:release。验收包括 101 核心、49 CLI、7 Worker、34 网页、225 属性案例，
黄金和生成报告在核心/CLI/真实浏览器 Worker 间逐字节一致。基准不作机器相关硬门槛。

在 GitHub Actions → acceptance → Run workflow 选择分支，或执行：

```powershell
$taskBranch = git branch --show-current
gh workflow run ci.yml --ref $taskBranch
gh run list --workflow ci.yml --limit 5
```

首次手动触发要求默认分支已有 workflow_dispatch 配置、Actions 已启用且账号有写权限。
当前默认分支为 task-1-input-bridge。

## 产物和失败日志

Actions 运行 Summary → Artifacts，保留 14 天：

- acceptance-evidence-linux / acceptance-evidence-windows：安装、依赖、浏览器、验收、打包日志，
  失败属性样本和重放信息、浏览器结果与截图。if: always() 保留失败前已生成的诊断。
- release-linux / release-windows：仅成功验证后上传源码和运行 tar.gz、delivery-manifest.json。
  清单记录源码提交、生成平台、Node 版本、字节数与 SHA256。

本地生成到 work/release/task9/。源码用 git archive HEAD 生成；运行包重新构建并在打包前和
解压后验证。打包拒绝未提交跟踪改动和未跟踪新源码。被 .gitignore 排除的本地记录不进入源码包。
prepare:local 使用全新 staging，旧运行目录留存为 .previous-时间戳备份，不将残留文件合并进新包。

生成的 `.mbti` 接口文件固定使用 LF，确保 Windows 的 CRLF 检出配置不会让 `moon info`
产生仅换行变化的脏工作区。打包检查仍拒绝真实改动，并在失败日志中列出改动文件。

运行包解压后无需 npm install 或 MoonBit，使用 Node 22：

```bash
node cli/moondiff-json.mjs --version
node cli/moondiff-json.mjs old.json new.json --format json
npm run serve
```

CLI 退出 1 为正常差异；2 为输入/运行错误。网页打开打印的 localhost /web/ URL。
包内须保留 web/、两个 dist 模块、scripts/serve.mjs 与许可文件。
