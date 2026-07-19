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

## 安装与最小接入

在你的 MoonBit 项目根目录执行：

```bash
moon add brother-666/moonwheelkit
```

在包中导入并由应用显式推进虚拟时间：

```moonbit
import "brother-666/moonwheelkit" @wheel

let scheduler = @wheel.Wheel::new()
ignore(scheduler.schedule(@wheel.TimerSpec::once(3, "expire")))

match scheduler.advance_to(3) {
  @wheel.AdvanceResult::Advanced(report) =>
    println("fired=\{report.fired.length()}")
  @wheel.AdvanceResult::Rejected(_) =>
    fail("invalid virtual-time advance")
}
```

MoonWheelKit 不读取系统时钟，也不执行 payload；宿主负责读取现实时间、推进
`Wheel`，并处理返回的 `FiredTask`。

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
moon build --target all
moon test --target all
moon info && git diff --exit-code -- '*.mbti'
moon run cmd/main --target js
moon run bench/main --target js
```

如当前工具链支持 `--deny-warn`，可使用 `moon fmt --deny-warn` 与
`moon info --deny-warn`。MoonBit 0.10.4 使用上面等价的格式检查和
元数据差异检查命令。

调度语义见 [docs/SEMANTICS.md](docs/SEMANTICS.md)，验收证据见
[docs/EVIDENCE.md](docs/EVIDENCE.md)。
