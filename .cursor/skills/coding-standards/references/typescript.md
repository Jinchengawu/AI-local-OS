# TypeScript 编码规范

## Import/Export 规范

**优先使用 Named Import/Export：**

```typescript
// ✅ 推荐：Named imports
import { UserService, type User } from '@/services/user';
import { formatDate, formatNumber } from '@/utils/formatters';

// ❌ 避免：Namespace imports
import * as utils from '@/utils';

// ✅ 推荐：Named exports
export function createOrder(data: CreateOrderRequest): Promise<Order> { ... }
export type { Order, CreateOrderRequest };

// ❌ 避免：Default exports（React.lazy 除外）
export default function createOrder() { ... }
```

**允许的例外：**

```typescript
// ✅ 允许：Radix UI 组件（复合组件模式）
import * as Dialog from '@radix-ui/react-dialog';
import * as DropdownMenu from '@radix-ui/react-dropdown-menu';
```

## 变量命名

```typescript
// ✅ 推荐：描述性名称
const marketSearchQuery = 'election';
const isUserAuthenticated = true;
const totalRevenue = 1000;

// ❌ 不推荐：不清楚的名称
const q = 'election';
const flag = true;
const x = 1000;
```

## 函数命名

```typescript
// ✅ 推荐：动词-名词模式
async function fetchMarketData(marketId: string) {}
function calculateSimilarity(a: number[], b: number[]) {}
function isValidEmail(email: string): boolean {}

// ❌ 不推荐：不清楚或仅名词
async function market(id: string) {}
function similarity(a, b) {}
function email(e) {}
```

## 不可变性模式 (关键)

```typescript
// ✅ 务必使用展开运算符
const updatedUser = { ...user, name: 'New Name' };
const updatedArray = [...items, newItem];

// ❌ 绝不直接变异
user.name = 'New Name'; // BAD
items.push(newItem); // BAD
```

## 错误处理

```typescript
// ✅ 推荐：全面的错误处理
async function fetchData(url: string) {
  try {
    const response = await fetch(url);
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`);
    }
    return await response.json();
  } catch (error) {
    console.error('Fetch failed:', error);
    throw new Error('Failed to fetch data');
  }
}
```

## Async/Await 最佳实践

```typescript
// ✅ 推荐：尽可能并行执行
const [users, markets, stats] = await Promise.all([fetchUsers(), fetchMarkets(), fetchStats()]);

// ❌ 不推荐：不必要的顺序执行
const users = await fetchUsers();
const markets = await fetchMarkets();
const stats = await fetchStats();
```

## 类型安全

```typescript
// ✅ 推荐：正确的类型
interface Market {
  id: string;
  name: string;
  status: 'active' | 'resolved' | 'closed';
  created_at: Date;
}

// ❌ 不推荐：使用 'any'
function getMarket(id: any): Promise<any> {}
```

## 类型定义基础

- **对象类型** — 使用 `interface`
- **联合类型/工具类型** — 使用 `type`
- **类型文件** — 使用 `.types.ts` 后缀

### 类型位置规范

| 类型          | 位置                                               |
| ------------- | -------------------------------------------------- |
| 组件 Props    | 组件文件内                                         |
| API 响应类型  | `src/types/*.types.ts` 或 `src/common/apiTypes.ts` |
| 共享/跨包类型 | `@workspace/types`                                     |

```typescript
// 组件 Props — 放在组件文件内
interface ButtonProps { variant: 'primary' | 'secondary'; }
function Button({ variant }: ButtonProps) { ... }

// API 响应 — 放在 types 目录
// src/types/order.types.ts
export interface OrderResponse { id: string; status: OrderStatus; }
```

## any 的替代方案

```typescript
// ❌ 禁止随意使用 any
function process(data: any) {}

// ✅ 替代方案
function process(data: unknown) {} // 不确定类型
function process(data: Record<string, unknown>) {} // 任意对象
```

## Type Guards（类型守卫）

用于在运行时收窄类型，处理 `unknown` 或联合类型：

```typescript
// 自定义类型守卫
interface User {
  id: string;
  name: string;
  email: string;
}

function isUser(data: unknown): data is User {
  return (
    typeof data === 'object' && data !== null && 'id' in data && 'name' in data && 'email' in data
  );
}

// 使用
function processData(data: unknown) {
  if (isUser(data)) {
    // TypeScript 知道 data 是 User 类型
    console.log(data.name);
  }
}
```

**判别联合（Discriminated Unions）：**

```typescript
type ApiResponse<T> = { status: 'success'; data: T } | { status: 'error'; error: string };

function handleResponse(response: ApiResponse<User>) {
  if (response.status === 'success') {
    // TypeScript 知道 response.data 存在
    return response.data;
  }
  // TypeScript 知道 response.error 存在
  throw new Error(response.error);
}
```

**常用类型守卫：**

```typescript
// 数组类型守卫
function isStringArray(arr: unknown): arr is string[] {
  return Array.isArray(arr) && arr.every((item) => typeof item === 'string');
}

// 非空断言
function assertNonNull<T>(value: T | null | undefined, msg?: string): asserts value is T {
  if (value === null || value === undefined) {
    throw new Error(msg ?? 'Value is null or undefined');
  }
}
```
