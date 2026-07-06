# 调度语义

## 重复模式

- `Once`：触发一次后进入 Fired；
- `FixedDelay`：下一截止时间为实际观察时间加 period；
- `FixedRate`：下一截止时间为原计划时间加 period。

## 迟到处理

`advance_late_to`：

- Once 和 FixedDelay 最多补发一次；
- FixedRate 最多补发 `max_catch_up` 次，之后跳过过期周期。

`advance_late_budgeted` 在上述单任务规则之外增加全局预算：

- 所有任务按计划时间、timer id 排序；
- 每次最多返回 `max_fires` 个触发；
- 未处理到期任务保留为 Pending；
- `deferred_due` 给出仍到期的定时器数；
- `exhausted` 表示应在后续事件循环继续排空。

预算必须大于零，虚拟时间不可倒退。对同一 target 重复调用是合法的。

## 快照

快照保存中央定时器状态和统计。预算 backlog 可能包含 deadline 小于 now 的
Pending 定时器，这是合法状态；恢复后应使用 `advance_late_budgeted(now, n)`
继续排空。
