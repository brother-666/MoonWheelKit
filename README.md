# MoonWheelKit

面向 MoonBit 的分层时间轮、确定性虚拟时钟与预算化 backlog 调度基础库。

MoonWheelKit 适用于网关超时、缓存失效、重试队列、游戏逻辑、离散事件模拟和
测试框架。核心不读取系统时钟、不创建线程、不执行 IO，同一输入在 Native、
JavaScript、Wasm 和 Wasm-GC 上产生一致结果。

## 核心能力

- 可配置多层时间轮与跨层级联；
- 一次性、固定延迟和固定频率调度；
- generation 失效机制支持取消与重排；
- 精确逐 tick 推进与零扫描迟到跳转；
- 固定频率任务的单定时器追赶上限；
- 全局触发预算与可续 backlog 排空；
- 按计划时间和 timer id 稳定触发；
- 快照、恢复、统计、JSON、校验和惰性清理。

## 防止恢复任务风暴

```moonbit
match wheel.advance_late_budgeted(target_tick, 256) {
  @moonwheelkit.DrainResult::Drained(report) => {
    println("fired=\{report.fired.length()}")
    println("deferred=\{report.deferred_due}")
    // report.exhausted 时，可在同一 target_tick 再次调用继续排空。
  }
  @moonwheelkit.DrainResult::Rejected(_) => ()
}
```

该接口把一次虚拟时间跳转的总触发量限制在预算内。预算用尽后，到期但未处理的
任务保持 Pending，可被快照保存并在恢复后继续排空。

## 三种推进方式

- `advance_to`：逐 tick 精确处理，适合仿真和测试；
- `advance_late_to`：零扫描跳转，适合任务量可控的暂停恢复；
- `advance_late_budgeted`：零扫描、全局限量、可续排空，适合任务风暴风险。

## 验证

```bash
moon fmt --check
moon check --target all
moon test --target js
moon test --target wasm
moon test --target wasm-gc
moon run cmd/main --target js
moon run bench/main --target js
```

## License

Apache-2.0
