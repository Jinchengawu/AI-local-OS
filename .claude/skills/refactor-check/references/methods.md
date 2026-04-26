# 校验方法

## 1. 函数签名对比

**目的**：确保函数接口未变

### 检查内容

- 参数数量
- 参数类型
- 返回值类型
- 可选参数默认值

### 方法

```typescript
// 重构前
function calculateFee(amount: number, rate: number): number;

// 重构后 - 必须保持一致
function calculateFee(amount: number, rate: number): number; // ✅ 通过
function calculateFee(amount: number): number; // ❌ 参数变了
function calculateFee(amount: number, rate: number): string; // ❌ 返回类型变了
```

### 检查命令

```bash
# 对比重构前后的类型定义
git diff HEAD~1 --name-only | xargs grep -l "export function\|export const\|export interface"
```

## 2. 导出接口对比

**目的**：确保模块对外接口未变

### 方法

```bash
# 列出所有导出
grep -n "^export" 文件路径

# 对比重构前后
git show HEAD~1:文件路径 | grep "^export" > /tmp/before.txt
grep "^export" 文件路径 > /tmp/after.txt
diff /tmp/before.txt /tmp/after.txt
```

### 判定标准

- 新增导出：⚠️ 警告（可能可以接受）
- 删除导出：❌ 阻止（破坏兼容性）
- 修改导出：❌ 阻止（可能影响调用方）

## 3. 输入输出验证

**目的**：确保相同输入产生相同输出

### 方法

#### 方法 A：单元测试

```typescript
// 如果有测试，运行测试
pnpm test -- --coverage 文件路径
```

#### 方法 B：手动验证

```typescript
// 准备测试用例
const testCases = [
  { input: [100, 0.01], expected: 1 },
  { input: [0, 0.01], expected: 0 },
  { input: [100, 0], expected: 0 },
];

// 重构前后分别运行，对比结果
testCases.forEach(({ input, expected }) => {
  const result = calculateFee(...input);
  console.assert(result === expected, `Failed: ${input} => ${result}`);
});
```

#### 方法 C：快照对比

```typescript
// 重构前：生成快照
const snapshot = JSON.stringify(functionResult);
fs.writeFileSync('snapshot-before.json', snapshot);

// 重构后：对比快照
const before = fs.readFileSync('snapshot-before.json', 'utf-8');
const after = JSON.stringify(functionResult);
console.assert(before === after, 'Output changed!');
```

## 4. 异常处理验证

**目的**：确保错误处理行为一致

### 检查内容

- 抛出异常的条件
- 异常类型
- 异常消息

### 方法

```typescript
// 测试边界情况
const errorCases = [
  { input: [null, 0.01], shouldThrow: true },
  { input: [-1, 0.01], shouldThrow: true },
  { input: [100, -1], shouldThrow: true },
];

errorCases.forEach(({ input, shouldThrow }) => {
  try {
    calculateFee(...input);
    if (shouldThrow) console.error(`Should have thrown: ${input}`);
  } catch (e) {
    if (!shouldThrow) console.error(`Should not throw: ${input}`);
  }
});
```

## 5. 副作用验证

**目的**：确保副作用行为一致（如 API 调用、状态修改）

### 检查内容

- 是否调用相同的外部 API
- 调用顺序是否一致
- 传递的参数是否一致

### 方法

```typescript
// 使用 mock 验证调用
const mockApi = jest.fn();

// 重构前运行，记录调用
runFunction();
const callsBefore = mockApi.mock.calls;

// 重构后运行，对比调用
mockApi.mockClear();
runFunction();
const callsAfter = mockApi.mock.calls;

expect(callsAfter).toEqual(callsBefore);
```

## 6. 性能基准对比（可选）

**目的**：确保重构未显著影响性能

### 方法

```typescript
// 简单基准测试
const start = performance.now();
for (let i = 0; i < 10000; i++) {
  calculateFee(100, 0.01);
}
const duration = performance.now() - start;
console.log(`Duration: ${duration}ms`);

// 重构前后对比，允许 10% 波动
```

### 判定标准

- 性能提升：✅ 通过
- 性能持平（±10%）：✅ 通过
- 性能下降 >10%：⚠️ 警告，需要评估
