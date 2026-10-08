# 任务 9：远程 CI 与 Linux 验证准备

状态日期：2026-10-08（Asia/Shanghai）。本阶段只做本地准备。
**Linux 尚未实测；远程 GitHub Actions 尚未运行。** Windows 验证证据见 docs/validation/task9-*。
任务 9 根目录及 00a093c 源码归档的全新目录验收均通过；核心构建 SHA256 相同。
完成记录提交仅更新文档/证据，交付包随后重新生成到最终 HEAD；精确提交和包 SHA256 以
work/release/task9/delivery-manifest.json 为准。审阅记录见 [task9-review.md](validation/task9-review.md)。
本机 WSL 只有停止的 docker-desktop，没有通用发行版；Docker CLI 29.8.0 存在但 Linux daemon
不可用；无 Podman 或已连接 Linux 执行环境。未安装/启动系统组件或修改系统配置。

## Windows 本地命令

在源码根目录 PowerShell 顺序执行；每条命令失败就停止。

```powershell
.\scripts\setup-windows.ps1
.\scripts\moon.ps1 version --all
npm.cmd ci
moon.exe update
npm.cmd run acceptance
# 修改源码后按仓库约定本地提交；prepare:release 要求跟踪文件与 HEAD 一致。
npm.cmd run prepare:release
```

本地可复用已安装 Chrome/Edge；也可安装固定开发依赖的 Chromium 到用户浏览器缓存，
再设置 MOONDIFF_BROWSER。CI 自动完成此步骤。运行包不需要 npm install 或 MoonBit。

## Linux x64 本地命令（待实测）

准备有 Bash、curl、sha256sum、tar、unzip、Git 的 Linux x64 环境。工具安装到项目 .tools；
脚本不修改系统 PATH、profile 或系统组件。版本与 Windows 相同：Node 22.23.3、moon
0.1.20260920、moonc/core 0.10.14+7d59c7ec9、moonjson 0.4.0、playwright-core 1.63.0。
当前 CI 目标为 Ubuntu 24.04；其他 Linux 发行版不作已验证兼容声明。
安装脚本恢复官方 MoonBit 归档中 bin 工具的执行权限（原归档为 0664），然后才调用工具。
三个生成器使用 PATH 中的 moonfmt；Bash/JS/CI 文件固定 LF，历史日志与第三方许可保留原字节。

```bash
set -euo pipefail
bash scripts/setup-linux.sh
source scripts/moon-env.sh
moon version --all
npm ci
moon update
node node_modules/playwright-core/cli.js install chromium
export MOONDIFF_BROWSER="$(node --input-type=module -e "import {chromium} from 'playwright-core'; console.log(chromium.executablePath())")"
npm run acceptance
# 干净的已提交源码
npm run prepare:release
```

如 Chromium 提示缺少系统库，交由该 Linux 环境维护者准备，安装脚本不会自动改本机系统。
CI 仅在一次性 runner 用 `install --with-deps chromium` 准备浏览器系统库。
工具归档固定 SHA256；MoonBit Linux 归档 SHA256 为官网下载后计算值，Node 值来自官方
SHASUMS256.txt，core 与 Windows 相同。官方工具链/core 链接标示 2026-11-20 到期；到期后
应重新选定、校验和验证版本，不能将更换版本视为原版本验证。

| Linux 下载 | SHA256 |
| --- | --- |
| MoonBit x86_64 tar.gz | 9226694de9ff978db1ecf820b7710c4224e84ec7a76b19a222d96f0cd4e31b6a |
| Node 22.23.3 x64 tar.xz | df450af89261115ef9f9e3830c3eeb2cc9213b63c720b1af623cb5dcbe2e02de |
| core zip | 63e5b99991ac8fd49556b1e17bdcbdc662d797000250dd11ef090f38a2175e84 |

## CI 内容与手动触发

`.github/workflows/ci.yml` 的 `acceptance` 工作流支持 push、pull_request 和 workflow_dispatch。
Linux/Windows 从 actions/checkout 的干净检出安装工具与依赖，无构建/依赖缓存恢复，依次执行：

1. 固定版本工具安装及 SHA256 校验、core JS bundle。
2. npm ci、moon update、锁定 Playwright Chromium revision。
3. npm run acceptance：格式、deny-warn 检查、101 核心、49 CLI、7 Worker、34 网页、225 属性案例；
   15 黄金报告/文字与 15 生成报告在核心、CLI、真实浏览器 Worker 间逐字节一致。
4. npm run prepare:release：重新构建、全新 staging、独立运行验收、源码/运行 tar.gz、
   解压运行包后再次检查 CLI 与网页 Worker 的报告字节。

基准不作 CI 的机器相关门槛，本阶段未重测基准或修改任务 8 视频。

**推送需另外取得授权。** 工作流进入远程仓库默认分支后，在 GitHub 的 Actions → acceptance →
Run workflow 选择要验证的分支；若按钮未出现，检查默认分支是否包含 workflow_dispatch 配置、
仓库 Actions 是否启用及账号写权限。仅在其他分支新增此文件不足以使首次手动触发可用。

已有远程且 CLI 已登录时可执行（也是远程操作，需授权）：

```powershell
$taskBranch = git branch --show-current
gh workflow run ci.yml --ref $taskBranch
gh run list --workflow ci.yml --limit 5
```

## 产物与日志

Actions → 对应运行 → Summary → Artifacts：

- `acceptance-evidence-linux` / `acceptance-evidence-windows`：work/ci 安装、依赖、浏览器、
  acceptance、release 日志；work/property-failures 的失败样本和重放命令；probes、网页结果、截图。
  `if: always()` 保留失败时已生成的证据，保留 14 天；若检出前失败，只能查看 Actions 原始日志。
- `release-linux` / `release-windows`：只有验收、打包及解压验证成功才上传；保留 14 天。
  包含 `moondiff-json-0.1.0-source.tar.gz`、`moondiff-json-0.1.0-runtime.tar.gz`、delivery-manifest.json。
  清单记录 source_commit、生成平台、Node 版本、字节数和 SHA256。

本地对应目录为 `work/release/task9/`。源码归档由 git archive HEAD 生成，排除未跟踪用户
补充文档与机器产物；运行包由同一干净提交重新构建。打包拒绝其他未跟踪文件，防止新源码只
进入构建却不进入 git archive。三份已知用户补充 Markdown 保持未跟踪且不入包。修改跟踪文件后必须先提交，再重新执行
prepare:release。历史根目录 ZIP 和 delivery-manifest.json 对应任务 8 的 1ca2e88，已被任务 9
tar.gz 交付取代，保留用于追溯；不应用历史 ZIP 代表当前源码。
prepare:local 每次建立全新 staging，旧同名运行目录改名为 `.previous-时间戳` 留存，不将旧文件合并入新包。

运行包解压后在 moondiff-json-0.1.0 目录：

```bash
node cli/moondiff-json.mjs --version
node cli/moondiff-json.mjs old.json new.json --format json
npm run serve
```

CLI 退出 1 表示正常差异，退出 2 才是输入/运行错误。网页打开终端打印的 localhost /web/ URL；
保留 web、两个 dist 模块、scripts/serve.mjs 和许可。Linux 包保留 CLI 执行位，也可统一通过 node 调用。

## 推送获授权后的最短步骤

当前分支是 task-1-input-bridge，仓库尚未配置 remote。本地准备已完成后，还需要用户指定
已授权的 GitHub 仓库地址；不据此新建远程仓库或公开任何内容。

```powershell
# 仅在获授权并确认仓库地址后执行
$taskRepoUrl = Read-Host '已授权的 GitHub 仓库 URL'
git remote add origin $taskRepoUrl
git push -u origin HEAD
gh workflow run ci.yml --ref task-1-input-bridge
gh run list --workflow ci.yml --limit 5
```

push 本身会自动触发 acceptance。首次手动触发的默认分支条件见上文；若工作流尚未进入默认
分支，先审阅自动触发的运行，按该远程仓库约定将配置纳入默认分支。本阶段没有执行这些命令。
下载 Linux 运行证据并核对任务计数/字节比较后，才可更新“Linux 尚未实测”的状态。
