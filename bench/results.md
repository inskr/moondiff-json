# 实测基准

记录时间：2026-10-08T01:03:48.050Z。固定 seed 539365384，每项预热 5 次、测量 20 次，取中位数。

环境：12th Gen Intel(R) Core(TM) i7-12700H；win32 x64 10.0.22631；Node v22.23.3；逻辑 CPU 20。

- moon 0.1.20260920 (914d7da 2026-09-20) F:\MOONBit\.tools\moon\bin\moon.exe
- moonc v0.10.14+7d59c7ec9 (2026-09-18) F:\MOONBit\.tools\moon\bin\moonc.exe
- moonrun 0.1.20260920 (914d7da 2026-09-20) F:\MOONBit\.tools\moon\bin\moonrun.exe
- Feature flags enabled: rr_moon_mod,rr_moon_pkg

每侧主数据约 0.998 MiB，10000 记录、50002 节点；四个标量字段含填充串。主案例只改 10 个 value 字段。包含原始 token 精确解析、比较和 JSON 报告，不含 IO、启动、生成和呈现；不强制 GC。不是 CLI 端到端或浏览器耗时，也没有与其他库竞速。

| 案例 | 旧/新字节 | 中位数 ms | 最小/最大 ms |
| --- | --- | --- | --- |
| 1MiB-10000-records-10-fields-position | 1046683/1046683 | 77.559 | 68.747/90.778 |
| 1MiB-10000-records-10-fields-by-key | 1046683/1046683 | 99.421 | 92.545/128.425 |
| 10000-keyed-reverse-default | 1046683/1046683 | 102.385 | 91.351/135.122 |
| 10000-keyed-reverse-check-order | 1046683/1046683 | 106.181 | 97.378/137.185 |
| 10000-all-fields-changed | 1046683/1046683 | 89.802 | 80.498/116.566 |
| byte-limit-rejection | 2097154/4 | 0.603 | 0.553/1.906 |
| node-limit-rejection | 200001/4 | 38.681 | 34.540/50.916 |
| depth-limit-rejection | 131/4 | 0.016 | 0.014/0.018 |
| change-limit-rejection | 20003/20003 | 6.117 | 4.863/7.545 |

主案例 ≤1 秒目标：**达到**。结果仅适用于该机器，不作为 CI 时间硬门槛。资源拒绝案例验证完整错误 envelope，未隐式截断。20 次原始数据、报告 hash、改动索引见 [results.json](results.json)。

复现：先按 README 准备并构建，再运行 npm run bench。
