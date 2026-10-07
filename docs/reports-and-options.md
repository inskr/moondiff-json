# 严格选项与报告（任务 5）

核心 MVP 现在通过相同的 MoonBit analyze 服务于 Node 和浏览器模块 Worker。
选项、输入校验、比较、JSON 序列化和文字呈现均在 MoonBit 内完成。

## 字符串协议

构建命令是 `scripts/build-js.mjs`（需要由 scripts/moon.ps1 设置项目工具链环境）。
`scripts/verify-task5.ps1` 会执行完整构建及验收。
入口 `dist/moondiff-json.mjs` 同目录依赖 `moondiff-json-core.mjs`；发布或复制时须保留两者。

`analyze(old_text, new_text, options_text = "{}")` 返回 JSON 报告字符串。
两份文档必须保持原始文本，不能先交给 JS JSON.parse。
JavaScript 可解析返回的 envelope；json_text 和 identity.value_json 是字符串，
其中大整数和巨大指数不会被 JS Number 改写。
预期输入错误返回错误报告，内部程序错误继续显式失败，不伪装成用户错误。

`format_text(report_text)` 读取已经产生的报告，返回以换行结尾的文字。
它检查 schema、字段、变化类型、计数、路径、present 槽位和嵌入的 JSON 片段，
不重新比较原文档。损坏报告抛 JS `MoonDiffFormatError`；
异常的 report_text 和 message 包含 MoonBit 生成的错误 envelope。
JSON 语法错误为 PARSE_ERROR，报告结构/语义错误为 INVALID_OPTIONS，side 为 null。

实际编译发现带 raise 的外部函数返回编译器内部结果对象，
因此内部 `@report.format_text` 保持 `raise DiffError`，bridge 捕获预期错误并通过极小的 JS FFI 抛异常。
FFI 只传递 MoonBit 已序列化的错误字符串，不执行解析、比较或报告格式化。
另有实际编译试验拒绝 `#export_name` 与可选参数组合；
`src/bridge/entry.mjs` 只补齐省略的第三参数为 "{}"，再调用三字符串 MoonBit 入口。
这两项适配保持规格中的 JS 字符串协议，不依赖编译器内部标签布局。

## 选项和限制

选项先于两份文档解析，自身使用默认字节、节点、深度和数字限制。
成功读取限额后再应用于 old/new，不把下调的限额施加到 options 自身。
根必须是对象；只允许 ignore_paths、array_rules、limits；
所有层次的未知字段、错误类型、缺少规则 path/key、重复规则 path 均报 INVALID_OPTIONS。
重复对象键由严格解析器拒绝。未提供字段使用默认值。

ignore_paths 为 RFC 6901 字符串数组，根忽略禁止，重复路径去重。
array_rules 为 {path,key,check_order?} 对象数组，check_order 默认为 false，
path/key 必须是字符串。具体定位、忽略重叠和身份规则见 semantics.md。

| 限额 | 默认最大值 | 最小值 |
| --- | ---: | ---: |
| max_input_bytes | 2097152 UTF-8 字节/侧 | 1 |
| max_nodes | 100000 节点/侧 | 1 |
| max_depth | 64，根为 0 | 0 |
| max_changes | 10000 条 | 1 |

限额必须是精确数学整数，只能下调。1.0、1e0 按整数 1 处理；
使用 NumberKey 有界转换为 Int，先检查上界，不借助 Double 或可能溢出的整数解析。
原始数字 token 最多 256 个 ASCII 字符，显式指数绝对值最多 10000，这两项不能配置放大。
所有输入子树均先校验，包括被忽略部分。超限返回错误，不截断成功报告。

## 输出契约

成功字段按固定顺序为 schema_version、ok、equal、summary、changes。
schema_version 为 "1.0"；equal 仅在四种变化计数全部为零时为 true。
summary 顺序为 added、removed、modified、reordered、ignored_subtrees。
change 顺序为 kind、old_path、new_path、before、after、identity。
对象片段按 Unicode 码点排序，变化顺序遵循比较策略。

不存在的槽位为 {present:false,json_text:null}，真实 null 为 {present:true,json_text:"null"}。
added 的 old_path 为 null，removed 的 new_path 为 null；根路径仍是空字符串。
身份上下文的完整结构见 semantics.md。

错误字段仅为 schema_version、ok:false、error。
error 固定字段为 code、message、side、path、line、column；
没有成功统计或部分变化。没有已知位置时使用 null，解析坐标有值时为一基。
客户端的 ENCODING_ERROR / IO_ERROR 也可由文字渲染器消费。
报告不含耗时、时钟或随机值。文字报告使用 <absent> 区分缺失与真实 null，路径按 JSON 字符串展示。

任务 6 新增字符串适配 `client_error(code, message, side)`，供客户端已知的 IO、UTF-8 和
参数失败使用同一 MoonBit 序列化器；不比较用户文档。
code 只允许 IO_ERROR、ENCODING_ERROR、INVALID_OPTIONS；side 为 old/new/options 或空字符串
（序列化为 null）。未知元数据变成 INVALID_OPTIONS，message 为 Invalid client error metadata。
这些客户端错误的 path/line/column 均为 null；文件名属于 message，不伪装成 JSON Pointer。
JSON CLI 输出与 analyze 返回的字符串逐字节相同，不额外加换行；文字和错误诊断调用 format_text。

10000 条变化的 envelope 元数据节点可超过 100000，且输出可大于单侧输入上限。
文字入口不会把文档的 2 MiB/100000 节点限额误用于完整报告；
它仍严格拒绝重复字段/尾随输入、在解析时限制深度，并验证变化条数及报告结构。

## 实测和复现

2026-10-07：Windows 11 x64 10.0.22631、i7-12700H、
moon 0.1.20260920、moonc 0.10.14+7d59c7ec9、Node 22.23.3、Chrome 154.0.8037.98。
`scripts/verify-task5.ps1` 实际退出 0，98/98 MoonBit 测试通过，JS deny-warn check 和 release build 通过。
保存的 7 个报告夹具匹配完整黄金字节；8 个错误案例检查固定错误形状和位置。
15 个 Node 和真实 Chrome Worker 的完整 JSON、文字输出逐字节一致；原 12 项解析桥接回归仍通过。

覆盖默认/下调的字节、节点、深度、数字边界、忽略不能跳过校验、
10000 条变化完整成功与 10001 条 CHANGE_LIMIT，以及三个演示场景。
没有把这一结果当作尚未实现的 CLI 或产品网页验收，也未运行任务 8 的正式性能基准。
RED、回归失败、兼容性诊断和最终结果保存在 docs/validation/task5-*.log。
完整报告夹具位于 fixtures/reports，错误案例位于 fixtures/errors。
