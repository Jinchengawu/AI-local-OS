# React 编码规范

## 组件设计原则

1. 使用**函数式组件 + hooks**，不要新增 class 组件
2. 保持单一职责，一个组件只负责一个清晰目的
3. 优先使用组合（composition），而不是层层继承
4. props 尽量精简，避免"上帝组件"
5. 表现层组件（UI）不要直接发起 API 请求
6. **优先使用 Named Export**（`React.lazy()` 动态导入除外）

## 组件文件组织

根据复杂度选择合适的文件结构：

**简单组件** — 单文件

```
components/
├── Button.tsx
├── Chip.tsx
└── Spinner.tsx
```

**中等复杂组件** — 目录 + 平铺子组件

```
SymbolPopover/
├── index.tsx              # 导出入口
├── SymbolPopover.tsx      # 主组件
├── SymbolFilterBar.tsx    # 子组件
├── SymbolInfoCell.tsx     # 子组件
└── hooks/                 # 组件专属 hooks（如有）
```

**复杂组件** — 完整目录结构

```
Orderbook/
├── index.tsx          # 导出入口
├── types.ts           # 类型定义
├── components/        # 子组件
├── hooks/             # 组件专属 hooks
└── utils/             # 工具函数
```

**选择原则：**

- 无子组件、逻辑简单 → 单文件
- 有几个相关子组件 → 目录 + 平铺
- 子组件多、需要 types/utils 拆分 → 完整目录结构

### Next.js App Router 页面组织

App Router 下只有 `page.tsx`、`layout.tsx`、`loading.tsx` 等[特殊文件](https://nextjs.org/docs/app/getting-started/project-structure#routing-files)会被识别为路由，其他文件可以安全地 colocate 在同一目录下。

**简单页面** — 逻辑少、无子组件

```
app/(dashboard)/settings/
├── page.tsx           # 页面入口，直接包含 UI
└── utils.ts           # 页面专用工具函数（如有）
```

**复杂页面** — 多个子组件 + hooks + 工具函数

```
app/(dashboard)/playboard/manual-control/
├── page.tsx           # 页面入口，只做布局壳（import 主视图组件）
├── types.ts           # 类型定义
├── constants.ts       # 常量
├── utils.ts           # 工具函数（单文件够用时不必建 utils/ 目录）
├── api.ts             # API 请求函数
├── components/        # 子组件
│   ├── manual-control-view.tsx
│   ├── round-tile.tsx
│   └── right-panel.tsx
└── hooks/             # 页面专属 hooks
    ├── use-countdown.ts
    └── use-manual-control.ts
```

**规则：**

- **不使用 `_components` 前缀** — `_` 前缀是 App Router 的 [Private Folder](https://nextjs.org/docs/app/getting-started/project-structure#private-folders) 约定，语义是"将该文件夹及其子文件夹排除在路由之外"，不应仅作为组件目录的命名习惯
- **`page.tsx` 本身充当入口** — 无需额外的 `index.tsx` 导出文件
- **按复杂度升级结构** — 初始可以平铺文件，当组件/hooks 超过 3 个时再建子目录

## 组件代码结构

```typescript
interface DialogTransferProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  accountId?: string;
}

export function DialogTransfer({
  open,
  onOpenChange,
  accountId,
}: DialogTransferProps) {
  const t = useTranslation();
  const { transfer, isPending } = useTransfer();

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogTitle>{t("transfer.title")}</DialogTitle>
        {/* 内容 */}
      </DialogContent>
    </Dialog>
  );
}
```

## 组件职责分离

**核心原则**：组件只负责 UI 渲染，业务逻辑抽离到自定义 Hook。

```
组件目录结构：
modules/
└── trade/
    ├── components/
    │   └── LeverageDialog.tsx    # UI 渲染
    └── hooks/
        └── useUpdateLeverage.ts  # 业务逻辑
```

**避免的坏味道**：

| 坏味道             | 解决方案               |
| ------------------ | ---------------------- |
| 组件中有业务逻辑   | 抽离到自定义 Hook      |
| 组件中直接调用 API | 封装到自定义 Hook      |
| 多个 useEffect     | 抽离到独立 Hook        |
| 重复逻辑           | 提取到 Hook 或工具函数 |
| JSX 中写复杂逻辑   | 提取到变量或函数       |

## 提取纯函数

将复杂计算逻辑提取为纯函数（无副作用、可独立测试）：

```tsx
// ❌ 计算逻辑内嵌在组件中
function OrderPanel({ items, discount }) {
  const subtotal = items.reduce((sum, item) => sum + item.price * item.qty, 0);
  const discountAmount =
    discount.type === 'percent' ? (subtotal * discount.value) / 100 : discount.value;
  const tax = (subtotal - discountAmount) * 0.1;
  const total = subtotal - discountAmount + tax;

  return <div>Total: {total}</div>;
}

// ✅ 提取为纯函数
function calculateOrderTotal(items: OrderItem[], discount: Discount) {
  const subtotal = items.reduce((sum, item) => sum + item.price * item.qty, 0);
  const discountAmount = calculateDiscount(subtotal, discount);
  const tax = calculateTax(subtotal - discountAmount);
  return { subtotal, discountAmount, tax, total: subtotal - discountAmount + tax };
}

function OrderPanel({ items, discount }) {
  const { total } = calculateOrderTotal(items, discount);
  return <div>Total: {total}</div>;
}
```

**提取信号：**

- 计算逻辑超过 5 行
- 逻辑可能被复用
- 需要单独测试的业务规则

## 状态管理

```typescript
// ✅ 基于先前状态的功能性更新
setCount((prev) => prev + 1);

// ❌ 直接状态引用（在异步场景中可能过时）
setCount(count + 1);
```

## 条件渲染

```typescript
// ✅ 清晰的条件渲染
{isLoading && <Spinner />}
{error && <ErrorMessage error={error} />}
{data && <DataDisplay data={data} />}

// ❌ 三元地狱
{isLoading ? <Spinner /> : error ? <ErrorMessage /> : data ? <DataDisplay /> : null}
```

## 事件类型

```typescript
const handleClick = (e: React.MouseEvent<HTMLButtonElement>) => {};
const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {};
const handleSubmit = (e: React.FormEvent<HTMLFormElement>) => {};
```

## 组合模式

```typescript
// 复合组件
const TabsContext = createContext<TabsContextValue | undefined>(undefined)

export function Tabs({ children, defaultTab }: { children: React.ReactNode; defaultTab: string }) {
  const [activeTab, setActiveTab] = useState(defaultTab)
  return (
    <TabsContext.Provider value={{ activeTab, setActiveTab }}>
      {children}
    </TabsContext.Provider>
  )
}

export function Tab({ id, children }: { id: string; children: React.ReactNode }) {
  const context = useContext(TabsContext)
  if (!context) throw new Error('Tab must be used within Tabs')
  return (
    <button
      className={context.activeTab === id ? 'active' : ''}
      onClick={() => context.setActiveTab(id)}
    >
      {children}
    </button>
  )
}
```

---

## 自定义 Hooks 模式

优先使用 `ahooks` 提供的 Hook，避免重复造轮子：

```typescript
// ✅ 使用 ahooks
import { useToggle, useDebounce, useRequest, useInterval } from "ahooks";

// ❌ 不要自己实现已有的 Hook
function useMyToggle() { ... }  // BAD
```

### 业务 Hook 命名与职责

| 类型     | 命名模式              | 示例                                    |
| -------- | --------------------- | --------------------------------------- |
| 数据获取 | `use<Entity>`         | `useMarketData`, `useUserInfo`          |
| 数据修改 | `use<Action><Entity>` | `useUpdateLeverage`, `useCreateOrder`   |
| 表单逻辑 | `use<Entity>Form`     | `useTransferForm`, `useLoginForm`       |
| UI 状态  | `use<Feature>`        | `useSymbolPopover`, `useResizableWidth` |

---

## Props 设计

### 命名规范

- **数据 props** — 使用名词：`user`, `items`, `value`
- **布尔 props** — 使用 `is`/`has`/`can`/`show` 前缀：`isOpen`, `hasError`, `canEdit`, `showHeader`
- **回调 props** — 使用 `on` 前缀：`onClick`, `onChange`, `onSubmit`
- **渲染 props** — 使用 `render` 前缀或名词：`renderHeader`, `header`

### 必选 vs 可选

```tsx
interface DialogProps {
  // 必选 — 组件核心功能必需的
  title: string;
  onClose: () => void;

  // 可选 — 有合理默认值或非必需的
  size?: 'sm' | 'md' | 'lg';
  showCloseButton?: boolean;
  children?: React.ReactNode;
}
```

### 默认值处理

```tsx
// ✅ 在解构时设置默认值
function Dialog({ title, size = 'md', showCloseButton = true, onClose }: DialogProps) {}

// ❌ 避免在组件内部用 || 或 ?? 设置默认值
function Dialog(props: DialogProps) {
  const size = props.size || 'md'; // 不推荐
}
```

### 避免 Props 过多

```tsx
// ❌ 过多 props
interface BadProps {
  title: string;
  subtitle: string;
  icon: ReactNode;
  showIcon: boolean;
  headerClassName: string; // ... 10+ props
}

// ✅ 使用组合或分组
interface BetterProps {
  header: ReactNode;
  children: ReactNode;
  footer?: ReactNode;
  classNames?: { header?: string; body?: string; footer?: string };
}
```

### 透传 Props

```tsx
interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant: 'primary' | 'secondary';
}

function Button({ variant, className, ...rest }: ButtonProps) {
  return <button className={twMerge(variantStyles[variant], className)} {...rest} />;
}
```

---

## Zustand Store 结构

```typescript
import { create } from 'zustand';
import { combine } from 'zustand/middleware';
import { immer } from 'zustand/middleware/immer';
import { useShallow } from 'zustand/react/shallow';

// 1. 初始状态（TypeScript 自动推导类型）
const initialState = {
  count: 0,
  name: '',
};

// 2. 创建 Store（combine + immer）
const useExample = create(
  immer(
    combine(initialState, (set, get) => ({
      setExample: (fn: (state: typeof initialState) => void) => set(fn),
      reset: () => set(() => ({ ...initialState })),
    }))
  )
);

// 3. 定义 Selectors
type ExampleStore = ReturnType<typeof useExample.getState>;
const selectCount = (state: ExampleStore) => state.count;
const selectNameAndCount = (state: ExampleStore) => ({
  name: state.name,
  count: state.count,
});

// 4. 导出 Selector Hooks
export const useCount = () => useExample(selectCount);
export const useNameAndCount = () => useExample(useShallow(selectNameAndCount));
export const useExampleSelector = <T>(selector: (state: ExampleStore) => T) =>
  useExample(useShallow(selector));

export default useExample;
```

### Selector 使用原则

- **返回原始值** — 直接使用 selector
- **返回对象/数组** — 使用 `useShallow` 包装，避免不必要的重渲染
- **优先使用预定义的 selector hooks**，保持一致性

### Store 文件位置

- **全局 Store** — `src/stores/`（如 `user.ts`, `global.ts`）
- **模块级 Store** — `src/modules/xxx/stores/`

---

## useEffect 规范

> **核心原则：你可能不需要 useEffect**
>
> useEffect 是 React 中最容易被滥用的 Hook。在使用前，先问自己：这个逻辑真的需要 useEffect 吗？

### 不需要 useEffect 的场景

**派生状态：**

```tsx
// ❌ 错误 - 用 useEffect 同步状态
const [items, setItems] = useState([]);
const [total, setTotal] = useState(0);

useEffect(() => {
  setTotal(items.reduce((sum, item) => sum + item.price, 0));
}, [items]);

// ✅ 正确 - 直接计算（渲染时计算）
const [items, setItems] = useState([]);
const total = items.reduce((sum, item) => sum + item.price, 0);

// ✅ 正确 - 复杂计算用 useMemo
const total = useMemo(() => items.reduce((sum, item) => sum + item.price, 0), [items]);
```

**用户事件响应：**

```tsx
// ❌ 错误 - 用 useEffect 响应状态变化来执行操作
const [query, setQuery] = useState('');

useEffect(() => {
  if (query) {
    trackSearch(query);
  }
}, [query]);

// ✅ 正确 - 在事件处理函数中直接执行
const handleSearch = (value: string) => {
  setQuery(value);
  trackSearch(value);
};
```

**数据获取：**

```tsx
// ❌ 错误 - 组件中 useEffect + fetch
useEffect(() => {
  fetchUser(userId).then(setUser);
}, [userId]);

// ✅ 正确 - 使用 React Query
const { data: user, isLoading } = useQuery({
  queryKey: ['user', userId],
  queryFn: () => fetchUser(userId),
});
```

**初始化逻辑：**

```tsx
// ❌ 错误 - useEffect 做一次性初始化
useEffect(() => {
  initAnalytics();
}, []);

// ✅ 正确 - 模块级初始化（组件外）
initAnalytics();
function App() {
  /* ... */
}
```

**通知父组件：**

```tsx
// ❌ 错误 - useEffect 监听状态变化通知父组件
useEffect(() => {
  onValidChange(isValid);
}, [isValid, onValidChange]);

// ✅ 正确 - 在事件中通知
const handleChange = (newValue: string) => {
  setValue(newValue);
  onValidChange(newValue.length > 0);
};
```

### 需要 useEffect 的场景

```tsx
// ✅ 外部系统同步
useEffect(() => {
  document.title = `${unreadCount} 条新消息`;
}, [unreadCount]);

// ✅ 订阅与清理
useEffect(() => {
  const ws = new WebSocket(url);
  ws.onmessage = (e) => setData(JSON.parse(e.data));
  return () => ws.close();
}, [url]);

// ✅ DOM 操作
useEffect(() => {
  inputRef.current?.focus();
}, []);
```

### useEffect 反模式

| 反模式                      | 正确做法             |
| --------------------------- | -------------------- |
| 多个 useEffect 处理相关逻辑 | 抽离到自定义 Hook    |
| useEffect 链式更新          | 直接计算或合并       |
| 没有清理函数                | 总是清理订阅和定时器 |
| 依赖数组不完整              | 完整的依赖数组       |

### useEffect 决策流程

```
需要在渲染后执行某些逻辑？
├─ 是派生/计算值？ → 直接计算或 useMemo
├─ 是响应用户操作？ → 放在事件处理函数中
├─ 是获取数据？ → 使用 useQuery 或自定义 Hook
├─ 需要同步外部系统？ → ✅ 使用 useEffect
└─ 需要订阅/监听？ → ✅ 使用 useEffect + 清理函数
```

---

## API 请求（React Query）

> 业务 Hook 封装 API 调用，组件只负责调用和渲染。
>
> **统一使用 `@tanstack/react-query`，禁止使用 `ahooks` 的 `useRequest`。**

### useQuery - 数据获取

```typescript
export function useMarketData(symbol: string) {
  return useQuery({
    queryKey: ["marketData", symbol],
    queryFn: () => fetchMarketData(symbol),
    staleTime: 5000,
    refetchInterval: 10000,
  });
}

// 组件中使用
function MarketPanel() {
  const { data, isLoading, error } = useMarketData("BTC-USDT");
  if (isLoading) return <Skeleton />;
  if (error) return <ErrorMessage error={error} />;
  return <MarketDisplay data={data} />;
}
```

### useMutation - 数据修改

```typescript
export function useUpdateLeverage() {
  const { toast } = useToast();

  const updateLeverageUseCase = useMemo(() => {
    return new UpdateLeverageUseCase(new HttpAccountRepository());
  }, []);

  const { mutateAsync: updateLeverage, ...rest } = useMutation({
    mutationKey: ['updateLeverage'],
    mutationFn: (leverage: number) => updateLeverageUseCase.execute({ leverage }),
    onSuccess: () => {
      /* 更新本地状态 */
    },
    onError: (error) => {
      toast.show({ type: 'error', title: 'Error', txt: error.message || 'Network Error' });
    },
  });

  return { updateLeverage, ...rest };
}
```

### API 方法定义

```typescript
// src/common/api.ts
export const api = {
  async getUserInfo(userId: string) {
    const res = await axios.get('/v1/private/user/info', { params: { userId } });
    if (res?.data?.code !== SUCCESS_CODE) return null;
    return res.data.data;
  },
};
```

### React Query 高级用法

```tsx
// 条件查询
useQuery({ queryKey: ['user', userId], queryFn: () => api.getUser(userId), enabled: !!userId });

// 手动刷新缓存
queryClient.invalidateQueries({ queryKey: ['user'] });

// 乐观更新
useMutation({
  mutationFn: api.updateUser,
  onMutate: async (newData) => {
    await queryClient.cancelQueries({ queryKey: ['user'] });
    const previous = queryClient.getQueryData(['user']);
    queryClient.setQueryData(['user'], newData);
    return { previous };
  },
  onError: (err, variables, context) => {
    queryClient.setQueryData(['user'], context?.previous);
  },
  onSettled: () => {
    queryClient.invalidateQueries({ queryKey: ['user'] });
  },
});
```

**queryKey 规范：** 使用数组形式，包含资源名和参数：`["resource", param1, param2]`

### API 禁止事项

```typescript
// ❌ 组件中直接写 axios 调用
// ❌ 忘记处理 loading 状态（按钮没有 disabled={loading}）
// ❌ 忘记错误处理（缺少 onError）
```

---

## 表单处理（React Hook Form + Zod）

### 基础用法

```tsx
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';

const formSchema = z.object({
  username: z.string().min(2, '用户名至少2个字符').max(50),
  email: z.string().email('请输入有效邮箱'),
});

type FormValues = z.infer<typeof formSchema>;

function MyForm() {
  const form = useForm<FormValues>({
    resolver: zodResolver(formSchema),
    defaultValues: { username: '', email: '' },
  });

  return (
    <Form {...form}>
      <form onSubmit={form.handleSubmit(onSubmit)}>
        <FormField
          control={form.control}
          name="username"
          render={({ field }) => (
            <FormItem>
              <FormLabel>用户名</FormLabel>
              <FormControl>
                <Input {...field} />
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />
        <Button type="submit">提交</Button>
      </form>
    </Form>
  );
}
```

### 提取表单 Hook

当表单逻辑复杂时（API 调用、多步骤、复杂验证），提取为自定义 Hook：

```tsx
export function useTransferForm(onSuccess?: () => void) {
  const { toast } = useToast();
  const schema = z.object({
    amount: z.string().min(1, '请输入金额'),
    toAddress: z.string().regex(/^0x[a-fA-F0-9]{40}$/, '无效地址'),
  });

  const form = useForm<z.infer<typeof schema>>({
    resolver: zodResolver(schema),
    defaultValues: { amount: '', toAddress: '' },
  });

  const { mutateAsync: transfer, isPending } = useMutation({
    mutationFn: (data: z.infer<typeof schema>) => transferApi(data),
    onSuccess: () => {
      toast.show({ type: 'success', title: '转账成功' });
      form.reset();
      onSuccess?.();
    },
    onError: (error) => {
      toast.show({ type: 'error', title: '转账失败', txt: error.message });
    },
  });

  const onSubmit = form.handleSubmit((values) => transfer(values));
  return { form, onSubmit, isPending };
}
```

### 常用 Zod 模式

```tsx
z.string().min(1, '必填'); // 必填字符串
z.string().regex(/^\d+(\.\d+)?$/, '请输入有效数字'); // 数字（从字符串输入）
z.string().optional(); // 可选字段
z.string().refine((val) => parseFloat(val) <= max, { message: `最大 ${max}` }); // 条件验证
```

### 表单提取信号

当组件包含以下情况时，应提取为 `use<Entity>Form` Hook：

- 表单提交涉及 API 调用
- 有复杂的验证逻辑（异步验证、跨字段验证）
- 表单逻辑需要复用
- 组件中 useForm 相关代码超过 20 行

---

## 国际化

使用 `useTranslation` Hook 获取翻译函数：

```typescript
import useTranslation from "@/hooks/useTranslation";

function MyComponent() {
  const t = useTranslation();
  return <h1>{t("referral.shareTitle")}</h1>;
}

// 带参数的翻译
t("rewards.messengerBenefit1", { rate: "10%" })
```

**Key 命名规范：** `模块.功能.描述`（如 `referral.bind.success`）

**最佳实践：**

```typescript
// ✅ 复用已有 key
t("btnSubmit")

// ✅ HTML 内容
<div dangerouslySetInnerHTML={{ __html: t("referral.shareSubTitle") }} />

// ❌ 不要硬编码文本
<button>Submit</button>

// ❌ 不要在翻译 key 中拼接变量
t(`error.${errorCode}`)
```

**翻译文件位置：** `apps/web/src/locales/`（en-US.json, zh-CN.json 等）

**添加新翻译：** 先在 `en-US.json` 添加，同步到其他语言文件。

---

## 性能优化

> 项目启用了 **React Compiler**（babel-plugin-react-compiler），会自动进行 memoization 优化。
> 大多数情况下不需要手动使用 `memo`、`useMemo`、`useCallback`。

### memo/useMemo/useCallback 准则

```tsx
// ✅ 正确 - 直接导出函数组件（React Compiler 自动处理）
export function MyComponent() {
  return <div>...</div>;
}

// ❌ 不需要 - React Compiler 已自动处理
export const MyComponent = memo(function MyComponent() {
  return <div>...</div>;
});
```

**需要手动使用的场景：**

| Hook        | 场景                                    |
| ----------- | --------------------------------------- |
| useMemo     | 大数据处理（排序、过滤、复杂计算）      |
| useMemo     | Context 的 value（保持引用稳定）        |
| useCallback | 传递给第三方 `React.memo` 组件的回调    |
| useCallback | 作为 `useEffect` 依赖项（避免无限循环） |

**原则：** 禁止滥用 → 默认不加 → 按需使用 → 先分析后优化

### 代码分割与懒加载

```typescript
const TradePage = lazy(() => import('./pages/Trade'))

export function Dashboard() {
  return (
    <Suspense fallback={<Skeleton />}>
      <HeavyChart data={data} />
    </Suspense>
  )
}
```

**使用场景：** 路由级分割、大型组件（图表/编辑器）、条件渲染的不常用模块

### 长列表虚拟化

**触发阈值：** 列表项 >100 条时考虑使用虚拟化（`@tanstack/react-virtual`）

```typescript
const virtualizer = useVirtualizer({
  count: items.length,
  getScrollElement: () => parentRef.current,
  estimateSize: () => 50,
  overscan: 5,
});
```

### 性能诊断

使用 React DevTools Profiler：

| 指标         | 阈值     | 说明                 |
| ------------ | -------- | -------------------- |
| 单次渲染     | >16ms    | 可能导致掉帧         |
| 组件渲染次数 | 异常频繁 | 检查不必要的重渲染   |
| Commit 时间  | >50ms    | 考虑拆分组件或虚拟化 |
