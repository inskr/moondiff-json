# MoonDiff JSON — 项目说明

**一句话：** 用 MoonBit 精确比较 JSON 结构，服务配置审查、API 回归和测试快照。CLI 名
moondiff-json，交付目标为 2026 年 10 月 31 日。

**问题与价值。** 文本 diff 混入格式和字段换序噪声；数组移位掩盖内容变化，浮点转换可能
合并相邻大整数。本项目提供 added、removed、modified、reordered，区分缺失/null、数字/字符串，
整块新增删除只报一次，并记录 RFC 6901 双侧路径。

**演示。** 配置示例忽略 generated_at，只显示 timeout；API 用户数组显式按 id 匹配，用户 b
从旧索引 1 移到新索引 2 仍只显示 quota 变化；相邻大整数保持不同，重复数值身份 1/1.0 报错。
数组默认按位置；唯一键策略需明确配置，顺序检查只比较共有身份。

**实现。** MoonBit 负责解析适配、精确 token 比较、选项、限制和确定性报告；Node 负责 IO 和
0/1/2 退出码，静态网页 Worker 调用同一 analyze 字符串入口，支持超时、取消、过期结果保护和
完整 JSON 下载。用户输入不先经 JS JSON.parse。单侧默认 2 MiB、100000 节点、深度 64，最多
10000 变化，超限报错不截断。

**验证。** Windows x64、Node 22.23.3 与固定 MoonBit 工具链；npm run acceptance 实际运行
核心、CLI、真实浏览器和固定 seed 属性测试。npm run bench 保存 5 次预热、20 次测量及环境；
主案例位置/唯一键中位数 77.559/99.421 ms，范围与原始数据见 bench/results.md。
README 提供干净重建命令，docs/demo.md 提供 2–3 分钟真实录像。

**定位。** 已有 moonbit-community/moondiff 面向 MoonBit 源码；本项目面向 JSON，不宣称首创
或跨库速度优胜。首版只要求 JS backend；不做 YAML、Patch、写回、模糊匹配、LCS 或云服务。
项目 MIT，保留运行依赖 Apache 许可与来源；AI 开发辅助见 ai-usage.md。

**交付。** 源码、测试、CI 配置、CLI、网页和本地材料已准备。公开仓库、部署、包发布与报名
需用户后续明确授权；暂用本地 namespace，远程 CI 尚未执行，Linux 尚未测试。
