# 基于条件的等待

## 概述

不稳定的测试通常用任意延迟来猜测时间。这产生了竞态条件，测试在快速机器上通过但在负载或 CI 中失败。

**核心原则：** 等待你真正关心的条件，而非猜测它需要多长时间。

## 何时使用

```dot
digraph when_to_use {
    "测试使用 setTimeout/sleep？" [shape=diamond];
    "正在测试时序行为？" [shape=diamond];
    "记录为什么需要超时" [shape=box];
    "使用基于条件的等待" [shape=box];

    "测试使用 setTimeout/sleep？" -> "正在测试时序行为？" [label="是"];
    "正在测试时序行为？" -> "记录为什么需要超时" [label="是"];
    "正在测试时序行为？" -> "使用基于条件的等待" [label="否"];
}
```

**使用场景：**

- 测试有任意延迟（`setTimeout`、`sleep`、`time.sleep()`）
- 测试不稳定（有时通过，在负载下失败）
- 测试在并行运行时超时
- 等待异步操作完成

**不要使用：**

- 测试实际的时序行为（防抖、节流间隔）
- 如果使用任意超时，始终记录原因

## 核心模式

```typescript
// ❌ 之前：猜测时间
await new Promise((r) => setTimeout(r, 50));
const result = getResult();
expect(result).toBeDefined();

// ✅ 之后：等待条件
await waitFor(() => getResult() !== undefined);
const result = getResult();
expect(result).toBeDefined();
```

## 快速模式

| 场景     | 模式                                                 |
| -------- | ---------------------------------------------------- |
| 等待事件 | `waitFor(() => events.find(e => e.type === 'DONE'))` |
| 等待状态 | `waitFor(() => machine.state === 'ready')`           |
| 等待计数 | `waitFor(() => items.length >= 5)`                   |
| 等待文件 | `waitFor(() => fs.existsSync(path))`                 |
| 复杂条件 | `waitFor(() => obj.ready && obj.value > 10)`         |

## 实现

通用轮询函数：

```typescript
async function waitFor<T>(
  condition: () => T | undefined | null | false,
  description: string,
  timeoutMs = 5000
): Promise<T> {
  const startTime = Date.now();

  while (true) {
    const result = condition();
    if (result) return result;

    if (Date.now() - startTime > timeoutMs) {
      throw new Error(`等待 ${description} 超时，已等待 ${timeoutMs}ms`);
    }

    await new Promise((r) => setTimeout(r, 10)); // 每 10ms 轮询
  }
}
```

参见本目录下的 `condition-based-waiting-example.ts`，其中包含来自实际调试会话的完整实现和领域特定辅助函数（`waitForEvent`、`waitForEventCount`、`waitForEventMatch`）。

## 常见错误

**❌ 轮询太快：** `setTimeout(check, 1)` — 浪费 CPU
**✅ 修复：** 每 10ms 轮询

**❌ 没有超时：** 条件永远不满足时无限循环
**✅ 修复：** 始终包含带有清晰错误信息的超时

**❌ 过期数据：** 在循环前缓存了状态
**✅ 修复：** 在循环内调用 getter 获取新数据

## 何时任意超时是正确的

```typescript
// 工具每 100ms tick 一次——需要 2 次 tick 来验证部分输出
await waitForEvent(manager, 'TOOL_STARTED'); // 首先：等待条件
await new Promise((r) => setTimeout(r, 200)); // 然后：等待时序行为
// 200ms = 100ms 间隔的 2 次 tick——有记录且有理由
```

**要求：**

1. 首先等待触发条件
2. 基于已知的时序（而非猜测）
3. 注释解释原因

## 真实世界影响

来自调试会话（2025-10-03）：

- 修复了 3 个文件中的 15 个不稳定测试
- 通过率：60% → 100%
- 执行时间：快了 40%
- 不再有竞态条件
