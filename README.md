# MoonWheelKit

面向 MoonBit 的分层时间轮与确定性虚拟时钟调度基础库。

MoonWheelKit 服务于网关超时、缓存失效、重试队列、游戏逻辑、离散事件模拟和
测试框架等需要管理大量截止时间的场景。核心库不读取系统时钟、不创建线程、
不依赖浏览器或操作系统 API，同一组输入在 Native、JavaScript、WebAssembly
和 Wasm-GC 后端产生一致结果。

## 为什么不是普通定时器

普通 `sleep` 解决“当前任务等待多久”，MoonWheelKit 解决“如何组织大量未来
截止时间”。库内实现了：

- 可配置的多层时间轮和跨层级联；
- O(1) 表查找的取消与 generation 失效机制；
- 单次、固定延迟、固定频率三类调度语义；
- 逐 tick 精确推进与零扫描迟到跳转；
- 固定频率任务的有界追赶，避免恢复后的任务风暴；
- 稳定触发顺序、逻辑快照、确定性恢复；
- 统计、JSON 输出、不变量校验和惰性桶清理。

## 快速示例

```moonbit
let wheel = @moonwheelkit.Wheel::new()
let timer = wheel.schedule(
  @moonwheelkit.TimerSpec::fixed_rate(2, 5, "heartbeat"),
)

match wheel.advance_to(12) {
  @moonwheelkit.AdvanceResult::Advanced(report) =>
    println(report.to_json())
  @moonwheelkit.AdvanceResult::Rejected(_) =>
    println("time cannot move backwards")
}
```

迟到模式适合模拟事件循环暂停或进程恢复：

```moonbit
let report = wheel.advance_late_to(100)
```

该操作不会扫描跳过的每一个 tick，并严格限制固定频率任务一次最多补发
`max_catch_up` 个事件。

## 语义一览

| 类型 | 下一截止时间 | 迟到行为 |
| --- | --- | --- |
| `Once` | 无 | 触发一次并报告 lateness |
| `FixedDelay` | 实际观察时间 + period | 只补发一次，后续节奏顺延 |
| `FixedRate` | 原计划时间 + period | 保持节奏，有界追赶后跳过积压 |

零延迟任务可由 `advance_by(0)` 确定性排空。时间倒退会被拒绝。相同截止
时间按 timer id 稳定排序。

## 运行

```text
moon check
moon test
moon run cmd/main
moon run bench/main
```

`bench/main` 会确定性调度并触发 10,000 个任务，同时执行不变量检查。仓库不
虚构跨机器性能比，正式测量方法见
[`docs/BENCHMARK_PLAN.md`](docs/BENCHMARK_PLAN.md)。

## 文档

- [架构与复杂度](docs/ARCHITECTURE.md)
- [调度语义](docs/SEMANTICS.md)
- [生态检索与差异说明](docs/RELATED_WORK.md)
- [实现证据](docs/EVIDENCE.md)
- [基准方案](docs/BENCHMARK_PLAN.md)
- [公开协作跟踪](docs/TRACKING.md)
- [外部时钟接入示例](examples/clock_adapter.md)
- [路线图](ROADMAP.md)

## 项目边界

MoonWheelKit 不是异步运行时、cron 解析器或持久化数据库。它提供可以嵌入这些
系统的确定性调度内核。与 MoonBit 生态现有项目的逐项边界记录在
`docs/RELATED_WORK.md`，检索日期为 2026-06-30。

## License

Apache-2.0
