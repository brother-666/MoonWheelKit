# 生态差异与边界

异步运行时和系统定时器负责唤醒任务；MoonWheelKit 负责组织大量逻辑截止时间，
两者是上下层关系。应用可以从外部时钟读取时间，再显式推进时间轮。

优先队列可管理截止时间，但通常没有分层桶、固定延迟/固定频率迟到语义、快照
恢复和 backlog 排空报告。MoonWheelKit 将这些调度政策组合为后端中立内核。

项目不是 cron 解析器、线程池、持久化数据库或分布式调度器。它不执行 payload，
只返回确定性的 `FiredTask`，由调用方决定执行、重试和持久化。

截至 2026-07-06，检索 Mooncakes 的 timing wheel、virtual time、scheduler、
timer backlog 和 catch-up 相关项目，未发现覆盖上述完整范围的 MoonBit 通用库。
