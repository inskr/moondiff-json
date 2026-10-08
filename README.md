# MoonDiff JSON

MoonBit 实现的 JSON 结构化差异库，提供 Node CLI 与静态网页，用于配置审查、API 回归和测试快照比较。
核心、CLI 和网页共享同一个字符串入口；支持严格 UTF-8、精确十进制数字、对象/位置数组/唯一键数组、忽略规则和确定性报告。

公开仓库：https://github.com/inskr/moondiff-json 。项目采用 MIT；依赖许可见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。
只比较 JSON，不生成 Patch、不写回输入文件、不上传用户数据。与比较 MoonBit 源码的
[moonbit-community/moondiff](https://mooncakes.io/docs/moonbit-community/moondiff) 用途不同。

## 安装与构建

固定 Node 22.23.3、moon 0.1.20260920、moonc/core 0.10.14+7d59c7ec9、moonjson 0.4.0、playwright-core 1.63.0。
工具装到项目 .tools，不修改系统 PATH 或 profile。版本下载链接标示 2026-11-20 到期；之后需重新选定并验证工具链。
详情与校验和见 [环境](docs/environment.md)。

Windows x64，在 PowerShell 中逐条执行，非零退出时先处理错误：

```powershell
.\scripts\setup-windows.ps1
.\scripts\moon.ps1 version --all
npm.cmd ci
moon.exe update
npm.cmd run build:js
```

Linux x64，在 Bash 中执行：

```bash
set -euo pipefail
bash scripts/setup-linux.sh
source scripts/moon-env.sh
npm ci
moon update
npm run build:js
```

生成 dist/moondiff-json.mjs 与 dist/moondiff-json-core.mjs，两者必须一起保留。

## CLI

```bash
node cli/moondiff-json.mjs --help
node cli/moondiff-json.mjs examples/config/old.json examples/config/new.json --options examples/config/options.json
node cli/moondiff-json.mjs examples/config/old.json examples/config/new.json --options examples/config/options.json --format json
```

语法：`node cli/moondiff-json.mjs old.json new.json [--format text|json] [--options options.json]`。
默认文字报告，选项默认 `{}`；路径有空格时加引号，以 `-` 开头的文件名放在 `--` 后。
报告写 stdout，诊断写 stderr。退出码 **0** 表示相等、**1** 表示正常差异、**2** 表示输入或运行错误。
配置示例只改变 timeout，预期退出 1。JSON 输出直接保留核心报告字节，不另加换行。

文档和 options 保持原始字符串，禁止先用 JS JSON.parse 解析用户文档；非法 UTF-8 被拒绝。
数字不转为 JS Number：相邻大整数保持不同，1、1.0、1e0 等价。缺失值与真实 null 分别表示。

## 网页

```bash
npm run serve
# 或指定端口
npm run serve -- --port 8080
```

打开终端打印的 localhost /web/ 地址；Ctrl+C 停止。页面使用模块 Worker，需要 HTTP 服务。
支持文件导入、options、取消、示例、筛选、分页与完整 JSON 下载；比较和报告仍由 MoonBit 核心完成。
服务只有本地静态 GET/HEAD，无上传端点、CDN 或遥测。页面载入并显示“核心就绪”后可离线比较；
刷新离线加载不在 v1 范围。静态托管需要保留完整 web/ 和两个 dist 模块的相对位置。

## 字符串 API 与比较规则

```javascript
import { analyze, format_text } from './dist/moondiff-json.mjs';
const report = analyze('9007199254740992', '9007199254740993', '{}');
console.log(report);
console.log(format_text(report));
```

默认数组按位置比较；唯一键规则示例：

```json
{"array_rules":[{"path":"/users","key":"id","check_order":false}],"ignore_paths":["/meta"]}
```

身份只允许字符串或精确整数，缺失、重复或非法身份报错；字符串 "1" 与整数 1 不同。
路径采用 RFC 6901，旧新路径分别记录。输入始终先严格校验，忽略不能绕过重复键或资源上限。
默认每侧 2 MiB、100000 节点、深度 64，最多 10000 条变化；超限返回完整错误，不截断成功报告。
详见 [比较语义](docs/semantics.md) 和 [选项、限制与报告](docs/reports-and-options.md)。

## 测试、CI 与打包

工具环境准备后运行 `npm run acceptance`。浏览器测试需要 Chromium；Windows 本地可使用已安装的
Chrome/Edge，Linux 或 CI 使用锁定 Playwright Chromium，安装命令见 [CI 文档](docs/ci-linux.md)。

统一验收覆盖格式、deny-warn 检查、release 构建、101 核心、49 CLI、7 Worker、34 网页与
225 固定 seed 属性案例，并逐字节比较核心、CLI、真实浏览器报告。
Windows 本地完整验收和干净重建已通过；Ubuntu 24.04 远程完整验收与打包已通过。
最新双平台结果见 [GitHub Actions](https://github.com/inskr/moondiff-json/actions/workflows/ci.yml)。
基准可用 `npm run bench` 重新测量，不作为 CI 机器相关硬门槛。

```bash
npm run prepare:local
npm run verify:release
# 跟踪文件与 HEAD 一致、无未提交新源码时
npm run prepare:release
```

源码包、运行包与对应提交/SHA256 清单生成到 work/release/task9/，CI 通过后可从 Actions Artifacts 下载。
运行包只需 Node 22，无需安装 MoonBit 或执行 npm install；解压后执行 `node cli/moondiff-json.mjs ...`
或 `npm run serve`。保留 LICENSE、THIRD_PARTY_NOTICES.md、licenses/ 和两个 dist 模块。

仓库保留运行、开发与验证所需文件。本地任务文档、过程日志、录像、基准输出及生成包均被忽略；
CI 诊断与交付产物保存在 Actions Artifacts，不作为源码文件提交。
