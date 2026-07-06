# 验收证据

当前 27 项确定性测试覆盖：

- 精确截止、零延迟与相同截止时间的稳定顺序。
- 取消、重排和 generation 失效。
- 多层级联、固定延迟与固定频率。
- 迟到报告和固定频率追赶上限。
- 全局预算、分批续排与 deadline/id 顺序。
- 重复任务与一次性任务交错。
- 非法预算、时间倒退和快照 backlog 恢复。
- 统计、校验、压缩和快照。

万级任务风暴负载创建 10,000 个同时到期任务，以每批 256 的预算完成 40 批排空，最终触发 10,000、`deferred=0`、校验问题 0。该负载验证规模、稳定顺序与排空完整性，不用单机耗时宣称跨平台性能。

## 可复现命令

```bash
moon fmt --check
moon check --target all
moon test --target wasm
moon test --target wasm-gc
moon run cmd/main --target js
moon run bench/main --target js
moon info
git diff --check
```
