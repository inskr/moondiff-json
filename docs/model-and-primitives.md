# 任务 2：受控模型、精确数字与 Pointer

日期：2026-10-07（Asia/Shanghai）。沿用任务 1 已固定的工具链和 JS backend。

## 精确数字

`normalize_number(token) -> NumberKey raise DiffError` 处理原始 ASCII 数字 token，
仅使用字符串扫描与有界 Int 运算，没有 Double、JS Number 或任意精度算术依赖。
公开的 NumberKey 是只读的 `negative + digits + exponent`，表示带符号的
`digits × 10^exponent`；正规化不展开指数。

| 原文 | negative | digits | exponent |
| --- | --- | --- | --- |
| `1`、`1.0`、`1e0` | false | `1` | 0 |
| `0`、`-0`、`-0.000e-9999` | false | `0` | 0 |
| `120`、`1.20e2` | false | `12` | 1 |
| `-0.001200` | true | `12` | -4 |
| `9007199254740992` | false | `9007199254740992` | 0 |
| `9007199254740993` | false | `9007199254740993` | 0 |

系数去除前导零和尾随零，尾随零调整指数；零统一为正号、`0`、指数 0。
NumberKey 的 Eq 是这三个精确字段的比较。原 token 另存在 Value 数字节点中，不被正规化结果替换。

token 长度含符号、点和指数，最多 256 字符；**显式指数**绝对值最多 10000。
违规返回 NUMBER_LIMIT；独立函数收到非法数字语法时返回 PARSE_ERROR。
指数逐位累积并立即检查，不能产生 Int 溢出。零也不能绕过指数限额。
正规化后的指数可以超出 ±10000，例如 `10e10000` 的指数是 10001；这符合显式指数限制。

`NumberKey::is_integer()` 依据正规化指数是否非负判断精确数学整数，不转浮点。
身份字符串与整数的类型区分和排序键属于任务 4。

## Document 与模型边界

- `src/model/base`：Side、Limits、ErrorCode、ErrorInfo、DiffError，无输入包依赖。
- `src/input`：NumberKey、Value、Document，以及严格解析/正规化实现。
- `src/model`：再导出上述公共类型，定义 Options、ArrayRule、ValueSlot、Change、Identity、Summary、DiffReport。
- `src/diff`：RFC 6901 Pointer；后续比较消费 model 的公共类型。

这个依赖方向避免 model 与 input 循环依赖。已生成实际 `.mbti` 接口供后续任务使用。

`parse_document(text, side, limits)` 是 Document 构造入口。Document 的树字段私有，
外部字面构造被编译器拒绝。入口检查 UTF-8 字节数、严格语法、重复解码键、
解析期间深度、节点数、数字限制；转换时再次核对根深度 0。
原始 parser 的 Double 被丢弃，Value 的数字节点只包含原文和 NumberKey。
依赖若丢失原 token，作为内部不变量错误终止，不能伪装成用户输入错误。

Limits 是只读结构；`Limits::new` 只允许下调默认值，depth 可为 0，其余必须为正数。
Options 默认无忽略、无身份规则，保留默认限额。options JSON 的格式验证仍在任务 5 实现。

`Document::root()` 返回深拷贝的容器快照，修改读出的 Map/Array 不影响原 Document。
字符串与 NumberKey 不可变，可以共享。后续 diff 每侧取一次快照，不能每访问一个节点再复制整树。

ValueSlot 采用只读工厂：absent 为 `(present=false,json_text=None)`；
真实 null 为 `(present=true,json_text=Some("null"))`。保真 JSON 片段以字符串保存。
Change 将旧新路径分别建模为 `String?`，`Some("")` 是根，`None` 是该侧不存在。
DiffReport 的成功与错误分支分开；正式 JSON envelope 和文字渲染仍由任务 5 实现。

## RFC 6901 Pointer

`pointer_encode(Array[String]) -> String`，`pointer_decode(String) -> Array[String] raise DiffError`。
根为 `""`，空成员名为 `"/"`；`~` 转为 `~0`，`/` 转为 `~1`。
解码逐次处理转义，`/~01` 解码为 token `~1`，不会再次把它变成 `/`。
保留空 token、中文、emoji、百分号文本；不做 URI percent 解码。
不以 `/` 起始的非空 Pointer、URI fragment、孤立 `~` 和非法 `~2` 等均报 INVALID_OPTIONS。
非法 Pointer 文本不是有效错误定位，故此入口的 error.path 保持 None；配置解析器在知道配置字段位置时可另行附加合法路径。
对象路径、数组前缀和忽略根路径限制属于后续规则验证，不放进通用 Pointer 解码器。

源码核对发现当前 String 的默认 Compare 是 shortlex，lexical_compare 使用 UTF-16 码元。
二者均不能直接承担规格的 Unicode 码点排序。任务 3/5 必须显式按码点排序；
任务 1 的 moonjson.dumps(sort=true) 仍仅用于诊断探针，不用于正式报告排序。

## 验证和范围

```powershell
.\scripts\verify-task2.ps1
```

先运行的失败测试日志见 `docs/validation/task-2-primitives-red.log` 与
`task-2-model-red.log`。错误定位回归的先失败日志见 `task-2-pointer-error-path-red.log`。
最终运行输出见 `task-2-final.log`。
验证包括全部 JS backend check/test/build、外部伪造 Document 的编译拒绝、
任务 1 的 Node 和真实 Chrome Worker 12 案例逐字节一致性回归。
类型纯数据声明不以镜像测试凑数；测试针对精度、边界、转义和封装行为。

无精度降低、功能删除或报告语义调整。尚无正式差异算法、CLI、产品网页或性能结论。
下一步任务 3：确定性对象/位置数组比较与忽略规则。
