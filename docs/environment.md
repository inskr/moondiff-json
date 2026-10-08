# 固定工具链与依赖

项目使用 JS backend，工具只安装到 .tools；安装脚本校验 SHA256，不修改系统 PATH/profile。

| 工具 | 固定版本 |
| --- | --- |
| Node / npm | 22.23.3 / 10.9.9 |
| moon / moonrun | 0.1.20260920，914d7da |
| moonc / core | 0.10.14+7d59c7ec9 |
| moonjson | 0.4.0 |
| playwright-core | 1.63.0 |

Windows x64 用 scripts/setup-windows.ps1 和 scripts/moon.ps1；Linux x64 用
scripts/setup-linux.sh，随后 source scripts/moon-env.sh。完整命令见 [README](../README.md)
及 [CI 与 Linux 验证](ci-linux.md)。MoonBit/core 归档链接标示 2026-11-20 到期；
到期后必须重新选择、核对并验证工具链，不能假定固定链接永久有效。

| 归档 | SHA256 |
| --- | --- |
| MoonBit Windows x64 | faae225a8287d0ce69e44b5b3f754af988e97f4446056d8f32ceb3ddb998fce7 |
| MoonBit Linux x64 | 9226694de9ff978db1ecf820b7710c4224e84ec7a76b19a222d96f0cd4e31b6a |
| core | 63e5b99991ac8fd49556b1e17bdcbdc662d797000250dd11ef090f38a2175e84 |
| Node Windows x64 | 2b0ff57b049cda1bbcea2240eec20467018713c1efe1f7360c2681859b90ed71 |
| Node Linux x64 | df450af89261115ef9f9e3830c3eeb2cc9213b63c720b1af623cb5dcbe2e02de |
| moonjson registry zip | d6c5a881ede691a3fd5ffdfcd748247323eafce8819161108bbf7c84542e7774 |

Node 校验值来自官方 SHASUMS256.txt；MoonBit/core 值为官方归档下载后核验值，
moonjson 值与 registry index 一致。Linux 归档 bin 工具缺少执行位，安装脚本会恢复执行权限。

解析适配调用 moonjson 的严格 API，拒绝重复解码键并在解析期间限制深度；数字原始 token 被保留。
Document 转换丢弃 Double 数据，所有后续数字比较使用精确 NumberKey。
JS 构建从实际编译输出发现唯一 bridge 文件，再复制为 dist/moondiff-json-core.mjs；
src/bridge/entry.mjs 为同目录字符串 facade。CLI/浏览器不另实现比较算法。
