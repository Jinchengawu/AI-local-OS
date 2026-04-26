# 错误处理与可靠性

## Error Boundary

页面级别必须包裹 Error Boundary，防止白屏：

```typescript
import { ErrorBoundary, type FallbackProps } from 'react-error-boundary';

function ErrorFallback({ error, resetErrorBoundary }: FallbackProps) {
  return (
    <div className="flex flex-col items-center justify-center p-8">
      <h2 className="text-xl font-bold">出错了</h2>
      <pre className="text-sm text-red-500">{error.message}</pre>
      <button onClick={resetErrorBoundary}>重试</button>
    </div>
  );
}

// 页面使用
<ErrorBoundary FallbackComponent={ErrorFallback}>
  <TradePage />
</ErrorBoundary>
```

**使用场景：**

- 路由页面组件
- 独立功能模块（如图表、交易面板）
- 第三方组件包裹

## 边界条件处理

### 空状态

```typescript
// ✅ 正确 - 处理所有状态
function OrderList({ orders }: { orders?: Order[] }) {
  if (!orders) return <Skeleton />;           // loading
  if (orders.length === 0) return <Empty />;  // 空
  return <List items={orders} />;             // 正常
}

// ❌ 错误 - 假设数据总是存在
function OrderList({ orders }: { orders: Order[] }) {
  return <List items={orders} />;  // 调用方传 undefined 会崩溃
}
```

### 可选链与空值合并

```typescript
// ✅ 安全访问
const userName = user?.profile?.name ?? 'Anonymous';
const items = data?.list ?? [];
const balance = account?.balance ?? '0';

// ❌ 危险访问
const userName = user.profile.name; // 可能崩溃
```

### 数组操作防御

```typescript
// ✅ 防御性处理
const firstItem = items?.[0];
const mapped = (items ?? []).map(transform);
const filtered = (items ?? []).filter(predicate);

// ❌ 假设非空
const firstItem = items[0]; // items 为 undefined 时崩溃
```

## 异步错误处理

```typescript
// ✅ 完整的错误处理
async function fetchData() {
  try {
    const response = await api.getData();
    return response.data;
  } catch (error) {
    if (error instanceof NetworkError) {
      toast.show({ type: 'error', title: 'Error', txt: '网络连接失败' });
    } else if (error instanceof AuthError) {
      redirectToLogin();
    } else {
      toast.show({ type: 'error', title: 'Error', txt: '操作失败，请稍后重试' });
      console.error('Unexpected error:', error);
    }
    throw error; // 根据需要决定是否继续抛出
  }
}
```

## 类型收窄（Exhaustive Check）

```typescript
// ✅ 处理联合类型的所有情况
type OrderStatus = 'pending' | 'filled' | 'cancelled' | 'rejected';

function getStatusColor(status: OrderStatus): string {
  switch (status) {
    case 'pending':
      return 'text-yellow-500';
    case 'filled':
      return 'text-green-500';
    case 'cancelled':
      return 'text-gray-500';
    case 'rejected':
      return 'text-red-500';
    default:
      // exhaustive check - 如果新增状态忘记处理，TypeScript 会报错
      const _exhaustive: never = status;
      return _exhaustive;
  }
}
```

## React Query 错误处理

```typescript
// ✅ 统一的错误处理模式
const { data, isLoading, error } = useQuery({
  queryKey: ['orders'],
  queryFn: fetchOrders,
});

// 组件中处理
if (isLoading) return <Skeleton />;
if (error) return <ErrorMessage error={error} onRetry={refetch} />;
return <OrderList orders={data} />;
```

## 禁止事项

| 模式                       | 问题               | 替代方案                                     |
| -------------------------- | ------------------ | -------------------------------------------- |
| `try {} catch {}` 空 catch | 吞掉错误，难以排查 | 至少 `console.error`                         |
| `as any` 强转              | 绕过类型检查       | 正确的类型定义或 `unknown`                   |
| 忽略 Promise rejection     | 未处理的异常       | `.catch()` 或 `try/await`                    |
| `!` 非空断言滥用           | 运行时可能为空     | 条件检查或可选链                             |
| `// @ts-ignore`            | 隐藏类型问题       | 修复类型或使用 `@ts-expect-error` + 注释原因 |

## 错误日志规范

```typescript
// ✅ 有上下文的错误日志
console.error('[OrderService] Failed to submit order:', {
  orderId,
  error: error.message,
  stack: error.stack,
});

// ❌ 无意义的日志
console.error(error); // 缺少上下文
console.error('error'); // 没有实际信息
```
