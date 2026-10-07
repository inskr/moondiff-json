# 任务 1：环境、解析依赖与 JS 桥接验证

验证日期：2026-10-07（Asia/Shanghai）。本记录仅覆盖任务 1，不是最终软件验收或性能报告。

## 实际环境与版本

| 项目 | 实测版本 |
| --- | --- |
| 操作系统 | Windows 11 家庭中文版，10.0.22631，x64 |
| CPU | 12th Gen Intel Core i7-12700H |
| moon | 0.1.20260920，914d7da，2026-09-20 |
| moonc / core | 0.10.14+7d59c7ec9，2026-09-18 |
| moonrun | 0.1.20260920，914d7da |
| 测试用 Node / npm | v22.23.3 / 10.9.9 |
| 本机原有 Node / npm | v24.19.0 / 11.17.0；未用于最终验证 |
| 实测浏览器 | Chrome 154.0.8037.92，无头模式 |
| 浏览器测试驱动 | playwright-core 1.63.0，开发依赖 |
| Git | 2.50.1.windows.1 |

工具链从官方站点下载并解压到项目 `.tools`，只修改测试进程环境；
没有运行会修改用户 PATH 的官方安装脚本。下载地址按官方页面和脚本核对。
精确版本下载链接实际返回 HTTP 200。脚本与校验和见 `scripts/setup-windows.ps1`。
官方服务器对本批工具链/core 归档标示 2026-11-20 到期；之后重建可能需重新选择并验证工具链，
不能假定版本链接永久有效。

| 归档 | SHA256 |
| --- | --- |
| MoonBit Windows x64 | `faae225a8287d0ce69e44b5b3f754af988e97f4446056d8f32ceb3ddb998fce7` |
| core | `63e5b99991ac8fd49556b1e17bdcbdc662d797000250dd11ef090f38a2175e84` |
| Node 22.23.3 Windows x64 | `2b0ff57b049cda1bbcea2240eec20467018713c1efe1f7360c2681859b90ed71` |
| moonjson 0.4.0 registry zip | `d6c5a881ede691a3fd5ffdfcd748247323eafce8819161108bbf7c84542e7774` |

工具链和 Node 哈希与官网下载的校验清单一致；core 哈希为本次下载计算值；
moonjson 哈希与 registry index 的 checksum 一致。

## 依赖决定与真实 API

采用固定 `moonbitstack/moonjson@0.4.0`，Apache-2.0。
实际运行并读取已安装源码、生成接口及 LICENSE，而非仅相信网站能力描述。

- `@moonjson.loads(StringView, Flavor) -> Json raise Malformed`。
- `@moonjson.strict`，适配为 `{ ..@moonjson.strict, duplicates: Reject, depth: max_depth }`。
- `Json::Number(Double, repr~ : String?)` 保留数字 token；本项目后续只使用 `repr` 判断数字相等。
  core `Json::Eq` 和 Double 不能承担精确比较。任务 2 会转换为受控 Document 并实现 NumberKey。
- `@moonjson.dumps(Json, sort=true)` 实测将输入数字 token 原样写回，包括 `1e400`。
  目前只用于试验诊断；正式报告和码点排序按任务 5 的契约实现。
- 重复解码键返回 `Malformed::Repeated(At, String)`；字面 `a` 与 `\u0061` 也被认定重复。
- `Reader::value(depth)` 在读值前检查 `depth > flavor.depth`，根从 0 开始，子值 +1。
  适配无须改变计数定义。未闭合的深层输入实测先报 TooDeep，未先无限解析或遍历。
- 错误 `At.line/column` 已为一基坐标，诊断原样传递，不额外加 1。
- 适配剥离一个开头 BOM，再调用严格 parser；第二个 BOM 拒绝。

无需替换依赖、重写解析器、降低数字精度或调整报告语义。
字节、节点、数字 token/指数限额及树遍历复核属于任务 2/5，当前尚未完成。

## 实际 JS 导出

本工具链 `moon new` 生成 `moon.mod` / `moon.pkg`，项目采用该配置格式。
本地模块名暂为 `local/moondiff-json`，只用于开发，未冒用发布 namespace。

bridge 为 `pkgtype(kind: "foreign_library")`；`#export_name("probe_document")` 导出
`probe_document(String) -> String`，link JS format 为 `esm`。
这是真实诊断导出，不是未实现 `analyze` 的成功占位报告。

实际 release 输出为 `_build/js/release/build/src/bridge/bridge.js`。
`scripts/build-js.mjs` 在真实构建后发现唯一 bridge JS 产物，复制为稳定
`dist/moondiff-json.mjs`；Node 和浏览器 Worker 均 import 此文件。
客户端传入原始字符串，只解析诊断 envelope；用户文档不经 JS JSON.parse。
正式 `analyze(old_text,new_text,options_text)` 与 `format_text` 在任务 5/6 接入。

## 真实测试证据

- [RED：解析适配](validation/task-1-adapter-red.log)：7 个测试全部按缺失行为失败。
- [RED：Node 导出](validation/task-1-bridge-red.log)：空导出被断言拒绝。
- [最终完整命令输出](validation/task-1-final.log)：check（deny-warn）、test、build 与客户端探针。
- [真实浏览器结果](validation/task-1-browser.json)：浏览器版本、测试方式和一致性结果。

MoonBit：7/7 测试通过，包含相邻大整数、1e400、重复解码键、根深度 0、解析期间深度保护、
合法 emoji、JSON 扩展/尾随输入拒绝、单 BOM。
Node：12 个固定案例及确定性重复通过，另包含深度 64/65 和一万个未闭合括号。
浏览器：真实 Chrome 模块 Worker 的 12 个诊断字符串与 Node 逐字节一致。
这是解析桥接探针，不是 CLI 或最终网页验收；未测 Linux，未运行性能基准。

## 复现与遇到的问题

```powershell
.\scripts\setup-windows.ps1
& .\.tools\node-v22.23.3-win-x64\npm.cmd ci
.\scripts\verify-task1.ps1
```

临时试验位于 `work/probes`（Git 忽略）；验证时生成 Node 结果、Worker 页面、浏览器证据和截图。
产品代码不依赖临时试验目录中的手工文件；脚本可重新生成试验资源。

环境问题已定位并处理：
- 普通终端及内置浏览器通道报 `helper_unknown_error: setup refresh had errors`；
  必要本地命令改用获得自动批准的执行通道，浏览器改用 Playwright 驱动本机 Chrome。
- `moon new` 的 README symlink 提示 Windows 权限不足；试验配置生成成功，项目使用普通文件。
- 固定端口 4173 属于系统 4124–4223 保留范围，服务器改为 localhost 上系统分配的端口。
- Chrome dump-dom 虚拟时间让 5 秒定时器在 Worker 加载前运行；改为真实时钟等待，保留 5 秒保护。

下一步：任务 2 的受控数据模型、精确数字正规化、数字限制和 RFC 6901 Pointer。
