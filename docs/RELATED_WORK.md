# 生态差异与边界

异步运行时和系统定时器负责等待真实时间并唤醒任务；MoonWheelKit 负责组织大量逻辑截止时间。两者是上下层关系：应用从外部时钟读取时间，再显式推进时间轮。

优先队列也可以按截止时间管理任务，但通常不提供分层槽位、固定延迟与固定频率迟到语义、generation 取消、快照恢复以及预算化 backlog 排空报告。MoonWheelKit 将这些策略组合为后端中立的确定性内核。

项目不是 cron 解析器、线程池、持久化数据库或分布式调度器，也不执行任务 payload。它只返回稳定的 `FiredTask`，由调用方决定执行、重试和持久化。

截至 2026-07-06，检索 Mooncakes 中 timing wheel、virtual time、scheduler、timer backlog 与 catch-up 等关键词，未发现覆盖上述完整范围的 MoonBit 通用库。
