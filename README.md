# MoonWheelKit

MoonWheelKit 是面向 MoonBit 的分层时间轮、确定性虚拟时钟与预算化 backlog 调度基础库，适用于网关超时、缓存失效、重试队列、游戏逻辑、离散事件模拟和测试框架。

核心不读取系统时钟、不创建线程、不执行 IO。调用方显式推进时间，并接收按计划时间和任务编号稳定排序的触发结果，因此相同输入可在 Native、JavaScript、Wasm 与 Wasm-GC 上复现。

## 核心能力

- 可配置多层时间轮与跨层级联。
- 一次性、固定延迟和固定频率调度。
- generation 失效机制支持取消与重排。
- 精确逐 tick 推进和零扫描迟到跳转。
- 固定频率任务的单定时器追赶上限。
- 全局触发预算与可继续 backlog 排空。
- 快照、恢复、统计、JSON、校验和惰性清理。

## 防止恢复任务风暴

```moonbit
match wheel.advance_late_budgeted(target_tick, 256) {
  @moonwheelkit.DrainResult::Drained(report) => {
    println("fired=\{report.fired.length()}")
    println("deferred=\{report.deferred_due}")
  }
  @moonwheelkit.DrainResult::Rejected(_) => ()
}
```

预算耗尽后，到期但未处理的任务仍保持 Pending，可被快照保存并在恢复后继续排空。

## 验收

```bash
moon fmt --check
moon check --target all
moon test --target wasm
moon test --target wasm-gc
moon run cmd/main --target js
moon run bench/main --target js
```

调度语义见 [docs/SEMANTICS.md](docs/SEMANTICS.md)，验收证据见
[docs/EVIDENCE.md](docs/EVIDENCE.md)。
