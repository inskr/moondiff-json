# MoonDiff JSON Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox syntax for tracking. 本计划默认由当前代理顺序实施；仅在人类明确要求时使用并行子代理。用户当前请求是制作方案和 Prompt，实施授权由后续执行请求给出。

**Goal:** 在 2026-10-31 前交付可靠的 MoonBit JSON 差异库、CLI 和离线网页演示。

**Architecture:** MoonBit 负责解析适配、精确数字、差异计算及报告。Node 和浏览器共享一个字符串桥接入口，客户端负责 IO 与呈现。JS backend 是首版唯一必需后端。

**Tech Stack:** 锁定可用稳定 MoonBit、Node 22.x、原生网页；moonbitstack/moonjson 为待验证的解析依赖候选。

**Spec:** 同目录 MoonDiff-JSON-Spec.md；复制进代码仓库后放 docs/spec.md，并保留本计划为 docs/plan.md。

## Global Constraints

- JSON only；added/removed/modified/reordered；不做 Patch、YAML、自动写回、LLM。
- 数字精确十进制相等；原 token 最多 256 字符，显式指数绝对值最多 10000。
- 默认每侧 2097152 UTF-8 字节、100000 节点、深度 64（根为 0）、10000 变化。
- ignore_paths 为对象路径，by_key 规则仅定位根或经对象成员到达的数组。
- 身份仅字符串或精确整数，缺失、重复、非法身份报错；字符串和整数不同。
- 同输入同选项同字节报告，值以 present + json_text 表示，旧新 Pointer 分开。
- MoonBit 核心，Node/网页无第二套产品比较算法，用户文档不经 JS JSON.parse。
- Node CLI 退出码 0/1/2；所有源文件、依赖与参考来源公开可追溯。

## Review Focus

1. 相邻大整数在解析、比较、报告和网页展示任何一步均不合并：任务 1、2、6、7。
2. 移位数组同时修改内容必须保留旧新路径：任务 4。
3. null、空路径和不存在字段不能混为一类：任务 2、3、5。
4. 忽略规则不能穿过数组或绕过重复键和资源上限：任务 1、3、5。
5. 正常差异退出码 1 和网页过期 Worker 结果不能误判成失败/覆盖新结果：任务 6、7。

## 日期与优先级

| 建议日期 | 任务 | 独立交付 |
|---|---|---|
| 10-07～10-09 | 1 输入与桥接可行性 | 保真解析样例和真实 JS 导出 |
| 10-10～10-11 | 2 模型、数字、路径 | 稳定的数据类型与基础测试 |
| 10-12～10-14 | 3 基本差异 | 对象和位置数组库 |
| 10-15～10-17 | 4 唯一键数组 | 项目的主要演示能力 |
| 10-18～10-20 | 5 报告、选项、上限 | 核心 MVP 验收通过 |
| 10-21～10-22 | 6 CLI | 可用于 CI 的实际工具 |
| 10-23～10-25 | 7 网页 | 可交互演示，功能冻结 |
| 10-26～10-28 | 8 综合验收与材料 | 干净构建、视频、项目说明 |
| 10-29～10-31 | 缓冲和提交 | 修复、核对正式规则、完成提交 |

## 执行通用规则

每个任务按“关键失败案例 → 最小实现 → 验证 → 更新文档 → 小步提交”推进。对于核心算法和错误规则采用测试先行；页面配色、布局等低影响可逆变化采用视觉检查，不写镜像实现的测试。一个任务未通过自身门槛，不用后续 UI 掩盖问题。

以下接口名称和字段是固定契约；MoonBit 语法、构建配置和测试选择参数在任务 1 按当前工具链确定。任务中测试描述是断言规格，不是伪称已执行的代码。

### Task 1：输入适配与 JS 桥接可行性

**Files:** work/probes/（仅试验）；src/input/parser.mbt、src/input/parser_test.mbt、src/bridge/main.mbt、scripts/probe-js.mjs、docs/environment.md；工具链生成的模块和包配置。

**Interfaces:** 输入 UTF-8 文本；产出经过验证的解析依赖与版本、保留数字原 token 的办法、重复键拒绝办法、深度限制办法、实际 JS 字符串导出方式。

- [ ] 检查 workspace/AGENTS.md、现有项目、moon 和 Node；只做所需环境配置，记录版本。缺少 moon 时按官方文档准备；权限/网络阻碍需具体报告。
- [ ] 写试验断言：两个相邻大整数原 token 不同；1e400 原 token 保留；重复对象键被拒绝；深度越界在解析时被拒绝；合法 emoji 接受。
- [ ] 锁定解析候选和依赖版本；试验仅调用实际文档 API，不假设旧配置格式或导出文件名。
- [ ] 导出最小字符串函数并通过 Node 调用；网页 Worker 能 import 同一模块。记录生成路径并通过脚本整理到 dist，不让 UI 猜测路径。
- [ ] 验证通过后将选定方案落实为 input 适配层；试验产物保持独立；提交环境与依赖决定。

### Task 2：数据模型、精确数字与 Pointer

**Files:** src/model/types.mbt、src/model/options.mbt、src/input/number.mbt、src/input/number_test.mbt、src/diff/pointer.mbt、src/diff/pointer_test.mbt。

**Interfaces:** 固定 Document、Side、Limits、Options、NumberKey、ValueSlot、Change、DiffReport、DiffError；产出 normalize_number(token) -> NumberKey raise DiffError，pointer_encode(tokens) -> String，pointer_decode(String) -> Array[String] raise DiffError。

- [ ] 先断言 1/1.0/1e0 等价，-0/0 等价，相邻大整数不同，1.20e2/120 等价，256/257 字符与指数 10000/10001 边界。
- [ ] 实现 sign/digits/exponent 正规化；不展开指数，不按 Double 比較，不新增任意精度算术依赖。
- [ ] 断言根 ""、空键 "/"、~ 与 / 的编码解码、非法 ~ 转义报错；实现 Pointer。
- [ ] ValueSlot 明确 absent 与 JSON null；Document 构造受控；身份的整数判断使用正规化结果。
- [ ] 执行 MoonBit JS 目标的 check/test/build，记录结果，提交。

### Task 3：对象、标量、位置数组和忽略

**Files:** src/diff/basic.mbt、src/diff/ignore.mbt、src/diff/basic_test.mbt、src/diff/ignore_test.mbt、fixtures/basic/。

**Interfaces:** 消费任务 2 类型；产出 diff_documents(Document, Document, Options) -> DiffReport raise DiffError 的基础路径，唯一键数组暂未启用。

- [ ] 保存完全相同、键换序、字段新增删除、null/缺失、类型改变、根标量和位置数组中间插入的固定夹具与预期断言。
- [ ] 实现递归和确定性键排序；整块新增删除/类型变化只报一次；旧新路径分别传递。
- [ ] 写忽略 /meta 不误伤 /metadata、忽略新增/删除子树、根忽略拒绝、数组下标忽略拒绝、父子忽略去重测试。
- [ ] 实现按 token 匹配忽略，并检查输入两侧的已有路径前缀；忽略不修改原树。
- [ ] 测试交换 old/new 的计数对称性、自比较与重复运行确定性；提交。

### Task 4：唯一键数组

**Files:** src/diff/keyed_array.mbt、src/diff/keyed_array_test.mbt、fixtures/keyed/、docs/semantics.md。

**Interfaces:** 消费 Options.array_rules 和 NumberKey；为 diff_documents 接入 keyed 匹配；Change.identity 使用规格的字段结构。

- [ ] 测试 default by_key 换序零差异，check_order 换序一条 reordered，新增首项不误报重排。
- [ ] 测试旧索引 0/新索引 2 的对象字段变化，断言 old_path/new_path 都正确。
- [ ] 测试缺键、重复键、非法类型、双方不存在的规则目标、非数组目标；区分 "1" 与 1，合并整数 1 与 1.0 的身份。
- [ ] 实现每侧 Map 索引、共有身份递归和共有身份相对顺序检查；保留两侧索引。
- [ ] 验证身份变化输出新增和删除；身份排序采用带类型标签和正规化值的固定码点排序，不宣称数字大小排序。
- [ ] 规则目标数组整体新增/删除时，校验已有侧身份后仅报告整块子树一次；保存该夹具防止 keyed 分支违反通用规则。
- [ ] 运行所有核心测试与反序大数组用例，确认没有两两扫描；提交。

### Task 5：严格选项、限制和报告

**Files:** src/input/limits.mbt、src/model/options_test.mbt、src/report/json.mbt、src/report/text.mbt、src/report/report_test.mbt、src/bridge/main.mbt、fixtures/errors/。

**Interfaces:** parse_document(String, Side, Limits) -> Document raise DiffError；parse_options(String) -> Options raise DiffError；render_json(DiffReport) -> String；render_text(DiffReport) -> String；analyze(String, String, String) -> String。

- [ ] 先写未知选项、重复规则、上限非法值、限额上下边界测试；被忽略子树中的重复键/超限仍报错。
- [ ] 实现解析先验证再比较；parse_options 在文档解析前执行，且 options 文本也受 2097152 字节和解析深度/数字规则保护。单侧节点限额同样用于 options。
- [ ] 为错误输出固定 envelope；预期错误不附带成功统计或部分变化。
- [ ] 完成保真片段序列化与 present 槽位；测试大整数、真实 null、absent、根路径的完整报告。
- [ ] 报告不含运行耗时；10000 条变化成功，第 10001 条返回 CHANGE_LIMIT。
- [ ] 三个演示夹具通过同一 analyze 入口；这是核心 MVP 门槛；提交。

### Task 6：Node CLI

**Files:** cli/moondiff-json.mjs、scripts/build-js.mjs、scripts/cli-smoke.mjs、package.json、README.md。

**Interfaces:** 消费 analyze 字符串入口和 format_text(report_text) -> text 导出；CLI 语法、stdout/stderr、0/1/2 退出码遵守规格。text 渲染也通过 MoonBit 导出封装实现，不由 JS 重新计算变化。

- [ ] 写进程级断言：相等退出 0、真实变化退出 1、缺文件/非法 UTF-8/无效选项退出 2；json stdout 可解析且无日志污染。
- [ ] 实现参数和文件读取；UTF-8 使用严格解码，保留数字输入文本；不写回输入文件。
- [ ] 将构建产物整理为稳定 dist 入口，验证 --help/--version 和带空格路径。
- [ ] 将全部 smoke commands 写入 README；Windows 为必测目标，若未测 Linux 则如实说明。
- [ ] 核心测试、构建和 CLI 验收通过后提交。

### Task 7：静态网页

**Files:** web/index.html、web/styles.css、web/app.js、web/worker.js、scripts/serve.mjs、scripts/web-smoke.mjs、docs/demo.md。

**Interfaces:** 消费同一 analyze 入口；Worker 消息携带 request_id，客户端只接受当前任务结果。

- [ ] 实现双文本框、文件导入、选项输入、比较/取消、示例载入、错误提示、结果列表、筛选和下载；用户值使用文本节点显示。
- [ ] Worker 请求带递增 ID，取消/新比较使旧 ID 失效；5 秒超时 terminate 并清晰报错；恢复时重建 Worker。
- [ ] 三个浏览器 fixture 的下载报告与直接 bridge/CLI 完全一致；测试超时、取消及旧任务晚到。
- [ ] 用浏览器实际查看布局、长值、窄窗口、中文、错误输入；禁止只用静态代码检查代替网页运行。
- [ ] 本地 HTTP 服务启动后断网比较，确认无 CDN/上传请求；通过后提交并冻结功能。

### Task 8：综合验收、性能和参赛材料

**Files:** scripts/acceptance.mjs、bench/run.mjs、bench/results.md、.github/workflows/ci.yml、docs/ecosystem.md、docs/ai-usage.md、docs/project-one-pager.md、docs/demo.md、LICENSE、THIRD_PARTY_NOTICES.md。

**Interfaces:** 单一 npm run acceptance（脚本在此任务定义）驱动真实构建和验收；bench 独立运行，不纳入每次 CI 的机器相关硬阈值。

- [ ] 设置 MoonBit check/test/build、JS 桥接/CLI 测试、网页 smoke 的 CI；固定属性测试 seed，保留失败样本。
- [ ] 基准生成器固定 seed；1 MiB/侧、10000 条记录、10 字段变化，预热 5 次、测 20 次，记录中位数与机器/版本；补反序、全变化和资源拒绝测试。
- [ ] 在干净目录按 README 重建，执行 acceptance；未通过项逐一修复、补回归案例。
- [ ] 完成生态对比：与已有源码 moondiff、普通文本 diff 的不同，以及 position/by_key 的能力边界；不宣称速度优胜或生态首创而无证据。
- [ ] 确认 MIT 项目许可证适用，保留依赖 Apache-2.0 等声明与参考来源；完成 AI 使用说明和技术取舍说明。
- [ ] 录制 2–3 分钟视频：配置差异、数组身份匹配、精度/错误；准备一页说明和复现命令。
- [ ] 建议发布 Mooncakes 包及打版本标签；实际发布仓库、页面、包或报名信息按后续用户授权执行，不把“准备好”写成“已提交”。

## 验证命令与状态报告

### Task 9：远程 CI 与 Linux 验证准备（2026-10-08 用户授权）

**Scope:** 本地配置、必要兼容修复、验证、交付文档和按已有约定小步提交。
不推送、不部署、不创建远程发布、不报名；保留全部用户文件和已有改动。

**Files:** .github/workflows/ci.yml、scripts/setup-linux.sh、scripts/moon-env.sh、
scripts/generate-*-tests.mjs、scripts/prepare-local.mjs、scripts/package-local.mjs、
scripts/verify-release.mjs、README.md、docs/ci-linux.md、docs/validation/task9-*。

**Interfaces:** 复用 npm run acceptance；新增 npm run prepare:release 从干净已提交 HEAD
生成源码/运行包并验证解压包，交付 manifest 记录对应提交与 SHA256。

- [ ] 读取仓库约定、计划、验收与 CI，核对 9c0d4dd / 1ca2e88 和初始 Git 状态。
- [ ] 增加 Linux CI，保留 Windows；固定版本、手动触发、失败日志和两类产物。
- [ ] 检查大小写、分隔符、Windows 命令、编码/换行/执行位、独立运行和残留依赖；最小修复。
- [ ] 探测现有 Linux 环境，可用则实测，否则明确“Linux 尚未实测”。
- [ ] 运行统一验收、运行包独立启动/三端字节检查、静态 CI/Bash 检查和源码重建。
- [ ] 更新命令、触发/下载、状态和授权后的步骤；审阅 diff、小步提交并重生成匹配 HEAD 的交付包。

MoonBit 候选命令：moon check --target js、moon test --target js、moon build --target js；执行前用实际安装版 --help 核对语法。JS 脚本定义后运行 npm run acceptance、npm run bench；不要在脚本不存在时声称已运行。

每个任务报告：完成内容、实际运行命令与结果、未通过项、下一步。错误和性能数据如实保留；不以文档存在或界面截图替代核心验收。

本计划编写时尚未实施代码、安装工具链或运行项目测试。用户可将下一份 Prompt 连同本规格和计划交给编程代理执行。
