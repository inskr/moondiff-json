# 本地交付与后续公开操作

2026-10-08，任务 1–8 的本地交付完成。代码与功能验收结果见 README 和 docs/validation/task8-final.log。
实现仍使用 MoonBit JS backend；没有降低数值精度、删除核心功能或调整报告语义。

在源码根目录执行 npm run prepare:local，得到 work/release/moondiff-json-0.1.0：
CLI、web/、两份 dist 模块、许可声明和 SHA256 manifest.json。运行包不带工具链或开发依赖。
最终源码归档 work/release/moondiff-json-0.1.0-source.zip 来自 Git HEAD，含源码、测试、CI、说明和录像，
不含忽略的安装/构建输出，也不包含用户三份未跟踪补充文档。
运行归档为 work/release/moondiff-json-0.1.0-runtime.zip；外部交付清单为 work/release/delivery-manifest.json。
这些都是已授权的本地材料，尚未向他人发送。

材料：project-one-pager.md、ecosystem.md、ai-usage.md、demo.md，以及 demo/moondiff-json.webm。
README 包含从干净源码安装、acceptance、bench、CLI 和 HTTP 网页的运行命令。
真实基准主案例中位数为位置 77.559 ms、唯一键 99.421 ms；只适用于记录的机器和计时范围。

公开准备：版本候选 0.1.0，CLI 名 moondiff-json，模块暂用 local/moondiff-json，package 保持 private。
未来 Mooncakes 发布前应采用用户本人 namespace；Git remote 目前为空。暂未创建发布标签。
取得后续明确授权后，再根据用户提供的账号/仓库/站点目标进行公开推送、部署、包发布和正式报名。
当前没有公开 URL、远程 CI 成功记录或报名回执。工具链归档链接到期和未测 Linux 的限制已在 README 披露。
