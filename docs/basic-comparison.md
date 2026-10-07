# 基础比较和忽略（任务 3）

MoonBit 内部接口 `@diff.diff_documents(old, new, options)` 消费受控 Document，
返回 `DiffReport::Success(summary, changes)`，预期错误抛出 `DiffError`。
调用者先用同一 `options.limits` 构造两份 Document；正式 analyze 捕获错误的入口属于任务 5。

对象按解码后的 Unicode 码点字典序、深度优先比较；数组按共享索引比较，再报告尾部新增/删除。
标量严格区分类型，数字只比较 NumberKey，字符串按解码后内容比较，不做 Unicode 规范化。
整体新增、删除和类型变化各只产生一条变化，保留两个独立路径。
`null` 的片段为 `{present:true,json_text:"null"}`，缺失为 `{present:false,json_text:null}`。

`src/report/fragment.mbt` 当前只实现片段序列化及共享码点比较器：
递归排序对象键，保留数字的原始 token，使用已验证依赖引用字符串。
没有把输入交给 JS JSON.parse 或把数字转回 Double。
短键和长键、U+E000 与 emoji 的夹具同时防止 shortlex 与 UTF-16 排序误用。
完整 JSON/text 报告 envelope 留到任务 5。

ignore_paths 存放已解码的 Pointer token。先在两个完整快照上校验每条路径，
之后才构建前缀树供比较使用。根忽略报 INVALID_OPTIONS；任一侧的已有前缀
遇到数组且仍需继续定位时报错，即便父忽略会覆盖该规则也不能跳过校验。
标量或不存在的前缀不命中。整个数组可被忽略，但数组内成员路径不能被忽略。
重复和父子路径只计实际跳过的最外层比较节点；双方不存在的路径计零。
整块新增/删除/类型变化遵循一次报告规则，不为其内部未走到的忽略路径额外递归。

每侧只取一次 Document 快照，比较及序列化不修改 Document 或 Options。
忽略发生在输入校验之后，因此被忽略子树中的重复键、数字超限仍然报错。
收集变化时执行 max_changes，超过上限抛错，不返回部分成功。
任务 3 对任何非空 array_rules 明确报 INVALID_OPTIONS；任务 4 将接入唯一键匹配。

## 保存的夹具和验证

`fixtures/basic/cases.json` 保存输入文本、人工推导的计数和完整变化断言。
`scripts/generate-basic-tests.mjs` 是测试生成工具：只读取夹具表，保留输入为字符串，
生成 MoonBit 断言并调用实际 moonfmt 格式化。`--check` 验证保存夹具与可执行测试一致。
修改夹具后可运行以下命令重新生成：

```powershell
& .\.tools\node-v22.23.3-win-x64\node.exe scripts/generate-basic-tests.mjs
.\scripts\moon.ps1 fmt
.\scripts\verify-task3.ps1
```

2026-10-07 实测：Windows x64，MoonBit 0.10.14+7d59c7ec9、moon 0.1.20260920、
Node 22.23.3、Chrome 154.0.8037.98（本次运行的实际版本）。工具链环境细节见 environment.md。
RED：51 项中 25 项失败、26 项通过。GREEN：51/51 通过。
JS deny-warn check、格式校验、受控 Document 编译边界和 release build 通过。
已有解析桥接回归：12 项 Node 输出与 12 项真实 Chrome 模块 Worker 输出逐字节一致。
以上字节比较是解析诊断，不是尚未实现的最终差异报告。
重复比较验证相同结构和片段字符串；最终 envelope 的字节确定性由任务 5 验证。

真实日志保存在 `docs/validation/task3-red.log`、`task3-final.log`。
本阶段未运行性能基准，不作性能达标声明。
