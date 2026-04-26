# 测试规范

> 项目使用 Vitest + React Testing Library

## 测试金字塔

| 层级     | 覆盖范围                | 工具            | 数量 |
| -------- | ----------------------- | --------------- | ---- |
| 单元测试 | 纯函数、工具函数、Hooks | Vitest          | 多   |
| 组件测试 | UI 组件渲染和交互       | Testing Library | 中   |
| 集成测试 | 多组件协作、页面流程    | Testing Library | 少   |

## 必须测试的场景

| 场景             | 原因             | 示例                         |
| ---------------- | ---------------- | ---------------------------- |
| 金融计算         | 精度问题影响资金 | 价格、数量、费用、PnL 计算   |
| 复杂业务规则     | 逻辑错误影响交易 | 订单校验、风控规则、杠杆计算 |
| 共享工具函数     | 被多处依赖       | 格式化、解析、转换函数       |
| 状态复杂的 Hooks | 状态逻辑易出错   | 表单 Hook、交易 Hook         |
| 边界条件         | 容易遗漏         | 空值、极值、异常输入         |

## 测试文件组织

```
src/
├── utils/
│   ├── format.ts
│   └── __tests__/
│       └── format.test.ts
├── hooks/
│   ├── useOrderForm.ts
│   └── __tests__/
│       └── useOrderForm.test.ts
└── components/
    ├── OrderPanel/
    │   ├── OrderPanel.tsx
    │   └── __tests__/
    │       └── OrderPanel.test.tsx
```

## 测试命名

```typescript
describe('calculateOrderFee', () => {
  it('should return zero fee for maker order', () => {});
  it('should apply discount when user has VIP level', () => {});
  it('should throw error when amount is negative', () => {});
  it('should handle decimal precision correctly', () => {});
});
```

**命名规则：** `should [expected behavior] when [condition]`

## 纯函数测试

```typescript
import { describe, it, expect } from 'vitest';
import { formatPrice, calculateFee } from '../format';

describe('formatPrice', () => {
  it('should format price with default precision', () => {
    expect(formatPrice('1234.5678')).toBe('1,234.57');
  });

  it('should handle zero', () => {
    expect(formatPrice('0')).toBe('0.00');
  });

  it('should handle undefined', () => {
    expect(formatPrice(undefined)).toBe('--');
  });
});

describe('calculateFee', () => {
  it('should calculate fee correctly', () => {
    const result = calculateFee({
      amount: '100',
      price: '50000',
      feeRate: '0.001',
    });
    expect(result).toBe('5000'); // 100 * 50000 * 0.001
  });
});
```

## Hook 测试

```typescript
import { renderHook, act } from '@testing-library/react';
import { describe, it, expect, vi } from 'vitest';
import { useCounter } from '../useCounter';

describe('useCounter', () => {
  it('should initialize with default value', () => {
    const { result } = renderHook(() => useCounter(10));
    expect(result.current.count).toBe(10);
  });

  it('should increment count', () => {
    const { result } = renderHook(() => useCounter(0));

    act(() => {
      result.current.increment();
    });

    expect(result.current.count).toBe(1);
  });

  it('should reset to initial value', () => {
    const { result } = renderHook(() => useCounter(5));

    act(() => {
      result.current.increment();
      result.current.reset();
    });

    expect(result.current.count).toBe(5);
  });
});
```

## 组件测试

```typescript
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, it, expect, vi } from 'vitest';
import { OrderButton } from '../OrderButton';

describe('OrderButton', () => {
  it('should render submit button', () => {
    render(<OrderButton onSubmit={() => {}} />);
    expect(screen.getByRole('button', { name: '提交订单' })).toBeInTheDocument();
  });

  it('should call onSubmit when clicked', async () => {
    const handleSubmit = vi.fn();
    render(<OrderButton onSubmit={handleSubmit} />);

    await userEvent.click(screen.getByRole('button', { name: '提交订单' }));

    expect(handleSubmit).toHaveBeenCalledTimes(1);
  });

  it('should be disabled when loading', () => {
    render(<OrderButton onSubmit={() => {}} loading />);
    expect(screen.getByRole('button')).toBeDisabled();
  });
});
```

## 组件测试原则

```typescript
// ✅ 测试用户行为，使用语义化查询
await userEvent.click(screen.getByRole('button', { name: '提交' }));
expect(screen.getByText('提交成功')).toBeInTheDocument();

// ✅ 查询优先级：getByRole > getByText > getByTestId
screen.getByRole('button', { name: '确认' });
screen.getByText('订单已提交');
screen.getByTestId('order-id'); // 最后手段

// ❌ 测试实现细节
expect(component.state.isSubmitted).toBe(true);

// ❌ 直接测试样式
expect(button).toHaveStyle({ backgroundColor: 'red' });
```

## Mock 使用

```typescript
import { vi } from 'vitest';

// Mock 模块
vi.mock('@/api/order', () => ({
  submitOrder: vi.fn(),
}));

// Mock 函数
const mockFn = vi.fn();
mockFn.mockReturnValue('mocked value');
mockFn.mockResolvedValue({ data: 'async value' });

// 清理
afterEach(() => {
  vi.clearAllMocks();
});
```

## 异步测试

```typescript
import { waitFor } from '@testing-library/react';

it('should show success message after submit', async () => {
  render(<OrderForm />);

  await userEvent.click(screen.getByRole('button', { name: '提交' }));

  // 等待异步结果
  await waitFor(() => {
    expect(screen.getByText('订单提交成功')).toBeInTheDocument();
  });
});
```

## 测试 Wrapper

当 Hook 或组件依赖 Provider 时，需要创建 wrapper：

```typescript
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';

// 创建测试用 QueryClient
function createTestQueryClient() {
  return new QueryClient({
    defaultOptions: {
      queries: { retry: false },
      mutations: { retry: false },
    },
  });
}

// 通用 wrapper
function createWrapper() {
  const queryClient = createTestQueryClient();
  return function Wrapper({ children }: { children: React.ReactNode }) {
    return (
      <QueryClientProvider client={queryClient}>
        {children}
      </QueryClientProvider>
    );
  };
}

// Hook 测试使用 wrapper
it('should fetch user data', async () => {
  const { result } = renderHook(() => useUserInfo('123'), {
    wrapper: createWrapper(),
  });

  await waitFor(() => {
    expect(result.current.isSuccess).toBe(true);
  });
});

// 组件测试使用 wrapper
it('should render with data', async () => {
  render(<UserProfile userId="123" />, {
    wrapper: createWrapper(),
  });

  await waitFor(() => {
    expect(screen.getByText('用户名')).toBeInTheDocument();
  });
});
```

## 运行测试

```bash
cd apps/web

pnpm test              # 运行所有测试
pnpm test:watch        # 监听模式
pnpm test:coverage     # 覆盖率报告
pnpm test -- OrderForm # 运行匹配的测试
```
