# MoonDiff JSON：项目规格与条件约束

版本：1.0；编制日期：2026-10-07；目标截止：2026-10-31。

## 1. 目标、假设与成果

定位：用 MoonBit 实现的 JSON 结构化差异库，提供 CLI 和离线网页演示，帮助开发者审查配置变化、定位 API 回归、比较测试快照。

开发假设：单人或两人团队，每天 4–6 小时；先完成可靠核心，再接两个薄客户端。预计投入 70–100 人时，包含学习和工程缓冲。日期是建议安排，不是工期保证。

完成定义：第三方在干净环境中按 README 能构建、跑测试、比较两份 JSON；CLI 与网页对相同输入和选项产生同一报告；核心比较代码由 MoonBit 实现；参赛材料齐全。

项目暂名 MoonDiff JSON；仓库候选名 moondiff-json；CLI 命令名 moondiff-json。Mooncakes 包名必须使用参赛者自己的 namespace，执行时验证名称可用性。生态已有 moonbit-community/moondiff，它主要比较 MoonBit 源码，不能宣称本项目是首个 MoonBit diff 工具。

## 2. 赛事要求与项目要求

官方页面列出的验收要求：MoonBit 为主要实现语言；仓库公开并保留连续开发记录；README、运行示例、必要测试；认可的开源许可证和来源说明；已有项目须有本期实质新增；参赛者能够解释 AI 辅助下的技术选择。报名与验收截止为 2026-10-31，每队最多 3 人，需加入赛事交流群并使用 GitHub ID 昵称。执行口径以正式章程和官方通知为准。

上述为赛事信息。下文的数字规则、资源限制、任务安排、测试数量和双客户端要求均为本项目自定标准，不代表官方强制要求。发布 Mooncakes 包为建议交付，不在此认定为官方强制条件。

## 3. v1 功能边界

必做：
- 严格 JSON 输入，根节点可为任意 JSON 值；UTF-8，允许剥离开头的一个 BOM。
- 对象、数组、字符串、数字、布尔值、null 的结构化比较。
- added / removed / modified / reordered 四类变化。
- 对象成员顺序不影响结果；数组默认按位置比较。
- 指定数组通过唯一键匹配对象，默认忽略已匹配对象的相对顺序，允许显式检查顺序。
- 指定对象路径忽略整个子树。
- 标准 JSON Pointer 路径、旧新两侧路径、确定性报告、文字与 JSON 输出。
- MoonBit 公共库、Node CLI、无服务端网页、示例、CI、文档。

v1 不纳入：YAML/TOML/JSON5/JSONC；任意 JSONPath 或通配符；模糊实体匹配；LCS/最小编辑距离；自动生成或执行 JSON Patch；自动写回原文件；云端上传、登录、数据库；LLM 调用；完整源码 diff；数值容差；完整逐行高亮与 Monaco 编辑器。

CLI 与网页均调用同一个 MoonBit 入口。JS 只负责文件读取、进程参数与退出、Worker、DOM、下载。JS 不实现第二套比较算法，也不先用 JSON.parse 解析用户文档。

## 4. 比较语义：实现和测试必须遵守

### 4.1 通用规则
- 类型严格：1 与 "1" 不同，false 与 0 不同，null 与字段不存在不同。
- 空白与转义写法不影响解码后的字符串；不做 Unicode 规范化，组合字符与预组合字符可能不同。
- 对象按键集合比较；排序采用解码后字符串的 Unicode 码点顺序。报告中的对象序列化采用同一顺序。
- 同类型容器递归；整块新增或删除仅报告该子树一次，不展开其每个叶子。
- 类型变化产生一条 modified，不再同时展开子树。
- 报告顺序：对象键排序后的深度优先；位置数组按索引；唯一键数组按规范化身份排序；数组的 reordered 先于其元素变化。不得依赖 Map 的迭代次序。
- 不修改两份输入树；同输入同选项得到相同字节的 JSON 报告，报告内不嵌入耗时、日期或随机值。

### 4.2 数字
- 使用原始数字 token 进行精确十进制比较，不经 Double 或 JS Number 决定相等性。
- 1、1.0、1e0 相等；0、-0、0.0 相等。
- 9007199254740992 与 9007199254740993 必须不同。
- 数字表示正规化为 sign + digits + exponent：删除系数前导零、尾随零并调整十进制指数；零采用统一表示；不展开巨大指数，不需要做任意精度加减。
- 例：1.20e2 和 120 都正规化为正号、digits="12"、exponent=1。
- 原始数字 token 最长 256 个 ASCII 字符，显式指数绝对值最多 10000；超出返回 NUMBER_LIMIT，不能近似后继续成功。
- 输入适配层必须保留 token。第一阶段验证 moonbitstack/moonjson 候选解析器的实际 API、原文保留、重复键拒绝及 JS 编译。保留数字原文不等于该类型自带精确相等，需要自行实现比较。
- 如果依赖无法提供保真 token，先记录具体阻碍；选择兼容解析器/小范围适配后重新验证。不得静默退回浮点数或完整重写解析器。

### 4.3 路径
- 使用 RFC 6901 字符串形式，根路径为 ""，空键路径为 "/"；~ 编码为 ~0，/ 编码为 ~1。
- 不支持 URI fragment 形式；畸形 ~ 转义报 INVALID_OPTIONS。
- 同一个匹配对象可能从旧索引 0 移到新索引 2，变化必须同时记录 old_path 和 new_path。
- added 的 old_path 为 null；removed 的 new_path 为 null。这里的 null 表示路径缺失，根路径仍是空字符串。
- 另外提供可读定位信息，例如 /users、identity_key=id、identity_json=1。可读标签不伪装成标准 JSON Pointer。

### 4.4 数组
- 默认 position：两侧共同索引递归，较长侧剩余项 added/removed。中间插入可能产生多条 modified，这是明确的 v1 限制。
- by_key 仅显式启用，不能自动猜测 id/name 字段。
- array_rules 的 path 必须从根经对象成员到达目标数组，根数组可使用 ""；v1 不支持定位位于其他数组内部的数组规则。
- key 是元素对象的直接属性名。数组每个元素必须是对象，且 key 存在。
- 身份仅允许字符串或精确数学整数；字符串 "1" 与整数 1 不同，1 与 1.0 为相同身份。布尔/null/小数/复合身份拒绝。
- 每侧身份必须唯一；重复/缺失/非法身份返回 INVALID_ARRAY_KEY，并说明侧别、数组路径和索引；不默默降级到位置比较。
- 相同身份递归比较内容，旧新索引分别用于两侧路径；身份改变等同删除旧元素、新增新元素。
- 身份的确定性排序键：字符串为 S: 加解码后内容；整数为 N: 加 sign、digits、exponent 的固定分隔表示，整体按 Unicode 码点排序。这是输出顺序规则，不是数字大小排序。
- check_order 默认 false；true 时，仅比较两侧共有身份的相对顺序，变化产生一条 reordered。
- 新增/删除元素造成的自然位移不单独算重排；只有相对顺序变化算重排。reordered 的旧新片段为共有身份序列。
- 规则 path 至少须在一侧解析到数组；另一侧缺失合法，另一侧存在非数组报 INVALID_OPTIONS。双方都不存在报 INVALID_OPTIONS。数组整体新增/删除时，先校验已有侧身份，再按通用规则报告整个数组一次，不展开每个身份。重叠忽略整个数组时，该规则不进行数据验证，但规则本身仍须通过配置格式验证。

### 4.5 忽略规则
- ignore_paths 只允许从根经对象成员定位子树，不支持数组下标、通配符、根路径 ""。
- 比较某对象成员前，若路径命中则跳过整个子树，包括新增、删除和类型变化。
- 使用解码后的 token 序列匹配；忽略 /meta 不会误伤 /metadata。
- 路径在两侧均缺失也合法；命中已有数组可整体忽略，但不能进入数组元素。
- 路径任一已有前缀遇到数组且仍有后续 token 时，返回 INVALID_OPTIONS。路径穿过标量或缺失对象时不命中，不报错。
- 重复路径去重；父子路径重复仅计最外层被跳过的子树。
- ignored_subtrees 表示实际跳过的比较节点数，不是忽略的变化条数；被忽略内容不进入变更统计。
- 忽略是比较策略，不是脱敏保证；网页仍显示用户原始输入。

## 5. 选项与报告契约

options JSON 只允许：ignore_paths（字符串数组）、array_rules（规则数组）、limits（资源上限对象）。未知字段、重复规则 path、无效类型或值均报 INVALID_OPTIONS。未提供字段使用默认值。

规则：{"path":"/users","key":"id","check_order":false}。limits 只允许 max_input_bytes、max_depth、max_nodes、max_changes；只能下调默认值，必须为正整数（max_depth 允许 0）。

调用协议：analyze(old_text, new_text, options_text) -> report_text。三个输入和返回值都是字符串；options_text 默认 "{}"。实际 MoonBit 导出方式以工具链验证结果为准，JS 外观固定不变。

文字客户端使用额外的 format_text(report_text) -> text 字符串导出：消费已经生成的报告，不重新比较文档；格式化失败显式报错，不回退到虚构结果。该接口由 MoonBit 实现。

成功示例（字段集合固定，缺失槽位不用 JSON null 代替真实值）：

```json
{
  "schema_version": "1.0",
  "ok": true,
  "equal": false,
  "summary": {"added":0,"removed":0,"modified":1,"reordered":0,"ignored_subtrees":0},
  "changes": [{
    "kind":"modified",
    "old_path":"/timeout",
    "new_path":"/timeout",
    "before":{"present":true,"json_text":"30"},
    "after":{"present":true,"json_text":"60"},
    "identity":null
  }]
}
```

不存在值统一表示 {"present":false,"json_text":null}；真实 null 表示 {"present":true,"json_text":"null"}。json_text 是保真、确定性序列化的 JSON 片段字符串，避免 JS 解析报告时将大整数改写。identity 为 null，或 {"array_old_path":路径或null,"array_new_path":路径或null,"key":"id","value_json":"1"}；它描述最近的 by_key 匹配上下文，规则禁止数组内嵌规则，故不会有多层身份歧义。

equal 仅当四种变化总数为零时为 true，表示指定策略下相等。错误报告固定为 {"schema_version":"1.0","ok":false,"error":{"code":代码,"message":说明,"side":old/new/options/null,"path":路径或null,"line":数字或null,"column":数字或null}}；不返回伪完整 summary 或部分 changes。

必要错误码：PARSE_ERROR、DUPLICATE_KEY、INVALID_OPTIONS、INVALID_ARRAY_KEY、INPUT_LIMIT、DEPTH_LIMIT、NODE_LIMIT、CHANGE_LIMIT、NUMBER_LIMIT。解析器有位置时 line/column 转为一基坐标；没有位置时保留 null，不捏造位置。UTF-8 解码失败由客户端返回同型错误，code=ENCODING_ERROR；文件读取失败 code=IO_ERROR。

## 6. 资源与性能约束

- 默认单侧输入最多 2097152 个 UTF-8 字节；单侧树最多 100000 个节点；根深度为 0，每个子值深度 +1，最大 64；变化最多 10000 条。
- 所有内容（含被忽略子树）先做输入、深度、节点、数字与重复键校验。忽略不能绕过输入校验。
- options 在两份文档之前解析；options 文本也受默认 2097152 字节、深度 64、100000 节点和数字规则限制，拒绝重复字段。限额配置成功后再应用于两份用户文档；不能由 options 自身配置放大 options 的解析上限。
- 深度限制必须在解析期间生效；适配解析器的容器深度计数，并在树遍历复核项目定义。不能先无限解析，再检查深度。
- 超出资源限额返回错误；收集第 10001 条变化时不返回成功或隐式截断。
- 目标复杂度：递归 O(N)，对象键排序额外 O(K log K)，by_key 用 Map 索引，避免全数组两两扫描。完整序列化的报告成本计入实际输出规模。
- 性能目标：在记录 CPU、操作系统、MoonBit、Node 版本的机器上，固定约 1 MiB/侧、约 10000 个记录、10 个字段变化的夹具，预热 5 次后运行 20 次，Node 端输入到 JSON 报告的中位数目标不超过 1 秒。另测反序、全变化和上限拒绝场景；如未达标，记录真实数据和原因，不编造完成。
- 网页通过 Worker 比较；单次超过 5 秒可终止 Worker 并显示 WORKER_TIMEOUT。新任务/取消任务必须使旧结果失效。Worker 超时是网页客户端保护，不改变核心同步接口。

## 7. 架构与文件责任

```text
src/model/          类型、选项、错误、报告结构
src/input/          解析依赖适配、数字正规化、输入限制
src/diff/           对象/位置数组/唯一键数组、Pointer、忽略规则
src/report/         确定性 JSON 与文字报告
src/bridge/         analyze 字符串入口和 JS 导出
cli/               Node 文件和参数适配，无比较逻辑
web/               静态网页、Worker、结果展示与报告下载
fixtures/          输入、选项、预期报告及生成器
bench/             固定场景与性能记录
scripts/           构建、JS 桥接、验收与客户端烟测
.github/workflows/  检查、测试、构建、客户端验收
docs/              语义、架构、生态对比、AI 使用、演示说明
```

内部接口契约（采用 MoonBit 当期可用语法实现，不把伪代码当已验证代码）：parse_document(String, Side, Limits) -> Document raise DiffError；parse_options(String) -> Options raise DiffError；diff_documents(Document, Document, Options) -> DiffReport raise DiffError；render_json(DiffReport) -> String；render_text(DiffReport) -> String；analyze(String, String, String) -> String；format_text(String) -> String raise DiffError。

Document 是经过限制校验且保留数字 token 的内部树，构造入口受控；NumberKey 是精确正规化表示；DiffError 与报告错误一一映射。bridge 捕获预期错误为错误报告；内部程序错误不能假装成用户输入错误，需修复并加回归测试。

采用 MoonBit JS backend 作为唯一必须交付的后端；Node 22.x 和当前稳定桌面 Chrome/Edge 为目标运行环境，实施时记录精确版本。不强制同时交付 Wasm、native、LLVM。首阶段锁定可用稳定 MoonBit 和依赖版本，遵循当期生成的配置格式，不复制过时 moon.pkg.json 模板。

解析库候选 moonbitstack/moonjson，正式采用前验证版本、许可证、JS 编译和 API。不得把网站描述当兼容性验证。前端原生 HTML/CSS/JS，避免框架、编辑器和运行时 CDN；用户内容通过文本节点展示；比较过程无上传、遥测或外部模型调用。

## 8. CLI 和网页

CLI 使用：node cli/moondiff-json.mjs old.json new.json [--format text|json] [--options options.json]；支持 --help、--version。默认 text；参数错误、缺文件、非法 UTF-8 均为错误。输出报告到 stdout，诊断到 stderr；退出码 0=策略下相等，1=有差异，2=运行或输入错误。diff 返回 1 属于正常结果，CI 烟测须断言该退出码。

网页提供：左右两个文本输入区、文件导入、显式比较按钮、取消、选项 JSON 输入、三个示例按钮、结果计数、可筛选变化列表、旧新路径和前后片段、报告下载。先列表展示，再考虑树视图。过滤只影响显示，不修改报告/统计。规则被启用时显示策略，避免把“忽略顺序”解释成全部输入相同。

网页经本地 HTTP 服务启动后可断网比较；构建产物打包全部依赖。刷新离线加载不作为 v1 PWA 目标。安装工具链/依赖和首次构建可能需要网络。

## 9. 验收案例与完成门槛

必须覆盖的语义案例：
1. 完全相同，报告零变化；对象换序和排版变化零变化。
2. 字段新增/删除/值修改；null 对缺失；类型变化一条 modified。
3. 1 对 1.0/1e0 相等；相邻大整数不同；负零、极小小数、指数边界。
4. 根标量、根数组、空对象、空数组、空字段名、~/ 转义键、中文、emoji、转义等价字符串。
5. position 中间插入按明确规则输出；by_key 纯换序默认零变化。
6. by_key 纯换序 + check_order 一条 reordered；新增开头元素不误报 reordered；换序同时改字段保留两个正确路径。
7. 缺失/重复/非法身份报错；整数 1 与字符串 "1" 分离；身份变化变成新增+删除。
8. 忽略新增子树、删除子树、类型变化；/meta 不误伤 /metadata；忽略数组元素路径拒绝。
9. 重复 JSON 对象键、非法 JSON、尾随输入、BOM、非法 UTF-8、无效配置均有可见错误。
10. 字节/深度/节点/变化/数字限制分别测“等于上限”与“超过上限”；包含忽略不能绕过校验。
11. 固定 seed 生成 JSON 对：自比较相等；重复运行相同字节；交换两侧后 added/removed 对换、modified/reordered 计数一致；排除无效配置和超限输入。
12. 至少三个客户端 fixture 的 bridge / CLI / 浏览器报告一致；CLI 0/1/2 退出码；网页旧任务结果不覆盖新任务。

测试设计以以上不同语义和失败模式为依据，不用“达到某个测试数量”代替覆盖。夹具保存预期结果；属性测试保存 seed、失败样本和复现命令。可用独立 JS 小参考比较器检查普通对象和 position 模式，但它只存在于测试工具中，不能进入产品路径或验证大整数模式。

提交门槛：MoonBit check/test/build 通过；客户端验收通过；干净目录重建成功；三个演示案例稳定；README 和语义说明与实测一致；无 TODO 核心功能/假数据；真实性能记录；许可证与来源；公开仓库完整历史；一页项目说明；2–3 分钟演示视频与重现命令。

## 10. 三个演示案例与风险应对

案例 A 配置审查：字段换序、/generated_at 改动和 /timeout 修改；忽略 generated_at 后只剩 timeout 一条变化。

案例 B API 用户数组：身份 a/b/c 重新排序，只有 b 的 quota 改动；by_key 默认只报告 quota。再打开 check_order，出现一条 reordered。

案例 C 边界可靠性：相邻大整数差异能检出；重复身份报清晰错误。演示时解释为何不能先转 Double。

风险处理：前两天若数字保真或 JS 导出不通过，优先解决输入/桥接；10-20 前核心落后则先减网页树视图、额外主题和包发布；不删精确数字、错误、基本测试或确定性。位置数组误报较多属于已披露能力边界；不临时加入 LCS。性能落后先测解析/排序/报告的耗时分布，再优化可定位瓶颈。

## 11. 来源与有效性

- [2026 MoonBit 十月黑客松](https://moonbitlang.github.io/Hackathon2026/)
- [已有 MoonBit 源码差异工具](https://mooncakes.io/docs/moonbit-community/moondiff)
- [moonjson 解析库候选](https://mooncakes.io/docs/moonbitstack/moonjson)
- [MoonBit FFI 与后端](https://docs.moonbitlang.com/en/stable/language/ffi.html)
- [moon 命令说明](https://docs.moonbitlang.com/en/latest/toolchain/moon/commands.html)
- [RFC 6901 JSON Pointer](https://www.rfc-editor.org/rfc/rfc6901)

资料核查日期为 2026-10-07。本文件是可执行规格，尚未证明依赖与工具链在本机兼容；此项由执行计划任务 1 验证。当前规划会话未发现 PATH 中的 moon 命令，不能把文档编写视作编译或运行成功。
