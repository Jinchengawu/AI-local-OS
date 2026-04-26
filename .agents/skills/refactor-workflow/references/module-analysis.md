# 模块分析指南

模块模式下的 ANALYZE 阶段详细步骤。

## Step 1：目录结构扫描

使用 **Glob** 和 **LS** 工具扫描目录（不要直接执行 shell 命令）：

1. 用 `Glob` 工具列出所有 `.ts/.tsx` 文件
2. 用 `Read` 工具读取每个文件，统计行数
3. 用 `LS` 工具查看目录结构

需要收集：

- 文件总数
- 每个文件行数及总行数
- 入口文件（index.ts/tsx）
- 目录结构层级

## Step 2：依赖关系分析

**内部依赖**：模块内文件之间的 import 关系

```typescript
// 检查每个文件的 import 语句
import { Foo } from './components/Foo'; // 内部依赖
import { Bar } from '../other-module'; // 外部依赖
```

**循环依赖检测**：

- A → B → A（直接循环）
- A → B → C → A（间接循环）

## Step 3：逐文件异味检测

对每个 .ts/.tsx 文件检查：

| 异味           | 阈值    | 说明                 |
| -------------- | ------- | -------------------- |
| 大文件         | >200 行 | 组件文件             |
| 超大文件       | >500 行 | 任何文件，必须拆分   |
| useState 过多  | >5 个   | 单组件               |
| useEffect 过多 | >3 个   | 单组件               |
| 深嵌套         | >4 层   | JSX 或逻辑           |
| any 类型       | 任意    | 需要添加类型         |
| useRequest     | 任意    | 需迁移到 react-query |

## Step 4：模块级问题识别

### 目录结构规范

推荐的模块结构：

```
modules/<name>/
├── index.ts(x)      # 统一导出入口
├── types.ts         # 类型定义
├── components/      # UI 组件
├── hooks/           # 自定义 hooks
├── utils/           # 工具函数（可选）
├── constants.ts     # 常量（可选）
└── api/             # API 定义（可选）
```

检查项：

- [ ] 是否有统一入口 `index.ts`
- [ ] 是否有类型定义文件 `types.ts`
- [ ] 复杂模块是否有 `hooks/` 目录
- [ ] 是否有超大文件需要拆分

### 导出规范

- ❌ 多个 default export（难以追踪）
- ❌ 缺少统一入口（直接 import 内部文件）
- ✅ 通过 index.ts 统一导出

### 命名规范

- 组件文件：PascalCase（`UserProfile.tsx`）
- hooks 文件：camelCase，use 前缀（`useUserProfile.ts`）
- 工具函数：camelCase（`formatDate.ts`）
- 类型文件：`types.ts` 或 `<name>.types.ts`

## 分析报告模板

```markdown
## 模块分析报告：`<模块路径>`

### 1. 概览

| 指标       | 值               |
| ---------- | ---------------- |
| 文件数     | X                |
| 总行数     | Y                |
| 入口文件   | index.tsx / 缺失 |
| 类型文件   | types.ts / 缺失  |
| hooks 目录 | 有 / 缺失        |

### 2. 文件列表（按问题严重度排序）

| 文件               | 行数 | 问题数 | 主要问题                  |
| ------------------ | ---- | ------ | ------------------------- |
| components/Foo.tsx | 350  | 3      | 超大文件, useRequest, any |
| components/Bar.tsx | 180  | 1      | 深嵌套                    |
| ...                | ...  | ...    | ...                       |

### 3. 模块级问题

- ❌ 缺少 hooks/ 目录（有 3 个文件需要提取 hook）
- ❌ 缺少 types.ts（类型散落在各文件）
- ⚠️ 2 个文件超过 300 行
- ✅ 无循环依赖

### 4. 依赖关系

**内部依赖图**：
```

index.tsx
├── components/Foo.tsx
│ └── components/FooItem.tsx
└── components/Bar.tsx

```

**外部依赖**：
- @/stores/user
- @/hooks/useDevice
- @/components/Empty

**循环依赖**：无 / 有
- A.tsx ↔ B.tsx
```

## PLAN 阶段建议

根据分析结果，按以下顺序规划：

### Phase 1: 基础设施（如有缺失）

1. 创建 `types.ts`，集中类型定义
2. 创建 `hooks/` 目录和 `hooks/index.ts`

### Phase 2: 逐文件重构

按依赖顺序（被依赖的先重构）：3. 重构文件 A（提取 hook）4. 重构文件 B（拆分组件）
...

### Phase 3: 清理

N-2. 检查并删除无用的 import 语句
N-1. 统一导出到 index.ts（确保外部只通过入口引用）
N. 删除无用代码/文件（如重构后不再使用的旧组件）

## 优先级判断

| 优先级 | 条件                            |
| ------ | ------------------------------- |
| P0 高  | 超大文件 >500 行、循环依赖      |
| P1 中  | 大文件 >200 行、使用 useRequest |
| P2 低  | 缺少类型、命名不规范            |

---

## 示例：activity 模块重构

### 重构前

```
modules/activity/
├── index.tsx
├── components/
│   ├── Ranking.tsx        # 261行，使用 useRequest，15处 any
│   ├── RewardProgressBar.tsx
│   └── ...
└── api/
    └── index.ts
```

**问题**：

- ❌ 缺少 `hooks/` 目录
- ❌ `Ranking.tsx` 使用 ahooks useRequest
- ❌ 大量 any 类型

### 重构计划

**Phase 1: 基础设施**

1. 创建 `hooks/` 目录和 `hooks/index.ts`

**Phase 2: 逐文件重构** 2. 创建 `hooks/useAgentRanking.ts`（封装 API，迁移到 react-query）3. 创建 `hooks/useRankingPagination.ts`（提取分页逻辑）4. 重构 `components/Ranking.tsx`（使用新 hooks，添加类型）

**Phase 3: 清理** 5. 更新 `hooks/index.ts` 导出

### 重构后

```
modules/activity/
├── index.tsx
├── components/
│   ├── Ranking.tsx        # 使用 hooks，类型安全
│   └── ...
├── hooks/                  # 新增
│   ├── index.ts
│   ├── useAgentRanking.ts
│   └── useRankingPagination.ts
└── api/
    └── index.ts
```
