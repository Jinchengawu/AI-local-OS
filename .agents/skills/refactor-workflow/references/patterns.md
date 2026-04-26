# 重构模式

## 1. 组件拆分

**适用**：组件 >200 行，职责不清

```typescript
// ❌ 重构前：大组件
function Dashboard() {
  // 用户信息逻辑 (50行)
  // 订单列表逻辑 (50行)
  // 统计图表逻辑 (50行)
  return (
    <div>
      {/* 用户信息 UI */}
      {/* 订单列表 UI */}
      {/* 统计图表 UI */}
    </div>
  )
}

// ✅ 重构后：拆分
function Dashboard() {
  return (
    <div>
      <UserInfo />
      <OrderList />
      <StatsChart />
    </div>
  )
}
```

**步骤**：

1. 识别独立 UI 区块
2. 提取为独立组件文件
3. 通过 props 传递数据
4. 验证渲染结果不变

## 2. 提取自定义 Hook

**适用**：状态逻辑复杂或可复用

```typescript
// ❌ 重构前：逻辑在组件中
function SearchPage() {
  const [query, setQuery] = useState('')
  const [results, setResults] = useState([])
  const [loading, setLoading] = useState(false)

  useEffect(() => {
    if (!query) return
    setLoading(true)
    fetch(`/api/search?q=${query}`)
      .then(res => res.json())
      .then(setResults)
      .finally(() => setLoading(false))
  }, [query])

  return (/* UI */)
}

// ✅ 重构后：提取 Hook
function useSearch() {
  const [query, setQuery] = useState('')
  const [results, setResults] = useState([])
  const [loading, setLoading] = useState(false)

  useEffect(() => {
    if (!query) return
    setLoading(true)
    fetch(`/api/search?q=${query}`)
      .then(res => res.json())
      .then(setResults)
      .finally(() => setLoading(false))
  }, [query])

  return { query, setQuery, results, loading }
}

function SearchPage() {
  const { query, setQuery, results, loading } = useSearch()
  return (/* UI */)
}
```

**步骤**：

1. 创建 `use<Name>.ts` 文件
2. 移动状态和副作用
3. 返回需要的值和方法
4. 在组件中使用 Hook

## 3. 提取函数

**适用**：函数 >50 行或有重复逻辑

```typescript
// ❌ 重构前：长函数
function processOrder(order) {
  // 验证 (20行)
  // 计算 (20行)
  // 保存 (20行)
}

// ✅ 重构后：拆分
function processOrder(order) {
  validateOrder(order);
  const total = calculateTotal(order);
  saveOrder({ ...order, total });
}
```

## 4. 简化条件

**适用**：深层嵌套 >4 层

```typescript
// ❌ 重构前：深嵌套
function getDiscount(user, order) {
  if (user) {
    if (user.isVip) {
      if (order.total > 100) {
        return 0.2;
      }
    }
  }
  return 0;
}

// ✅ 重构后：尽早返回
function getDiscount(user, order) {
  if (!user) return 0;
  if (!user.isVip) return 0;
  return order.total > 100 ? 0.2 : 0.1;
}
```

## 5. 消除魔术数字

```typescript
// ❌ 重构前
if (password.length < 8) {
}
setTimeout(callback, 300);

// ✅ 重构后
const MIN_PASSWORD_LENGTH = 8;
const DEBOUNCE_MS = 300;

if (password.length < MIN_PASSWORD_LENGTH) {
}
setTimeout(callback, DEBOUNCE_MS);
```

## 6. Props 透传优化

**适用**：Props 透传 >2 层

```typescript
// ❌ 重构前：透传
<App user={user}>
  <Layout user={user}>
    <Header user={user}>
      <UserMenu user={user} />

// ✅ 重构后：Context
const UserContext = createContext(null)

<UserContext.Provider value={user}>
  <App>
    <Layout>
      <Header>
        <UserMenu />  // useContext(UserContext)
```

## 7. 用映射替换条件链

```typescript
// ❌ 重构前：条件链
function getIcon(type) {
  if (type === 'success') return <SuccessIcon />
  if (type === 'error') return <ErrorIcon />
  if (type === 'warning') return <WarningIcon />
  return <InfoIcon />
}

// ✅ 重构后：映射
const ICONS = {
  success: SuccessIcon,
  error: ErrorIcon,
  warning: WarningIcon,
  info: InfoIcon,
}

function getIcon(type) {
  const Icon = ICONS[type] || ICONS.info
  return <Icon />
}
```
