# 架构与复杂度

## 数据路径

1. `TimerSpec` 校验后获得单调 timer id；
2. 中央表保存唯一可变定时器；
3. 桶只保存 `(timer_id, generation)` 轻量引用；
4. 取消和重排递增 generation，不扫描所有桶；
5. 桶处理忽略过期 generation；
6. 压缩可重建桶并删除失效引用。

## 分层时间轮

每层有 `S` 个槽，第 `L` 层槽宽为 `S^L` tick。定时器进入能覆盖其截止时间的
最低层；跨越层边界时，高层桶级联到低层。

## 预算化迟到排空

`advance_late_budgeted` 不扫描跳过的 tick，而从中央表中反复选择
`(deadline, timer_id)` 最小的到期任务，直到预算耗尽。固定频率任务还受
`max_catch_up` 单任务上限控制；达到上限后跳过积压周期并恢复未来节拍。

预算先耗尽时不跳过任务，截止时间仍可早于当前虚拟时间。这种 overdue Pending
状态可进入快照，恢复后继续使用预算接口排空。

## 复杂度

- 调度、重排：`O(levels)`；
- 取消：中央表查找与 generation 更新；
- 精确推进：`O(elapsed ticks + visited entries)`；
- 普通迟到推进：`O(tracked timers + emitted catch-up)`；
- 当前预算化选择：每次发射扫描中央表，`O(budget * timers)`；
- 快照：`O(timers)`。

当前预算接口优先语义清晰和确定性；后续可用到期堆优化选择而保持 API 不变。
