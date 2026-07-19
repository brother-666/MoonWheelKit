# Changelog

## 0.2.2 - 2026-07-20

- Update executable package metadata for the current MoonBit toolchain.
- Remove ambiguous empty-map warnings from scheduler creation and snapshot
  validation.
- Add reproducible installation instructions and strict CI quality gates.

## 0.2.1

- 修复公开中文文档乱码。
- 补充预算化 backlog、稳定顺序与快照恢复的验收证据。
- 明确与系统定时器、异步运行时和优先队列的边界。
- 保持 27 项确定性调度测试与四后端编译通过。

All notable changes are recorded here. The project follows semantic versioning
once its first Mooncakes release is published.

## 0.2.0 - 2026-07-06

### Added

- global emission budgets for late virtual-time advancement
- resumable due-timer backlog with deterministic ordering
- structured deferred and exhaustion reporting
- snapshot restoration for overdue pending timers
- 10,000-timer simultaneous-deadline workload
- four-backend CI matrix and generated API verification

## 0.1.0 - 2026-06-30

### Added

- configurable hierarchical timing wheel
- one-shot, fixed-delay and fixed-rate scheduling
- generation-based cancellation and rescheduling
- exact virtual-time advancement and zero-scan late advancement
- bounded fixed-rate catch-up
- stable event ordering and lateness reporting
- logical snapshots and deterministic restoration
- statistics, validation, JSON reporting and compaction
- CLI scenario, 10,000-timer workload and four-backend CI
- architecture, semantics, ecosystem comparison and benchmark documentation
