# 前端安全规范

> 作为金融交易项目，安全是底线要求。

## XSS 防护

### dangerouslySetInnerHTML

```typescript
// ⚠️ 必须确保内容来源可信
// 仅允许：翻译文本中的 HTML 标签、后台配置的富文本

// ✅ 允许 - 翻译文本（我们控制内容）
<div dangerouslySetInnerHTML={{ __html: t("referral.description") }} />

// ❌ 禁止 - 用户输入内容
<div dangerouslySetInnerHTML={{ __html: userComment }} />  // XSS 风险！

// ✅ 用户内容必须清洗
import DOMPurify from 'dompurify';
<div dangerouslySetInnerHTML={{ __html: DOMPurify.sanitize(userContent) }} />
```

### URL 处理

```typescript
// ❌ 危险 - 用户可控的 URL
<a href={userProvidedUrl}>Link</a>  // javascript: 协议可执行代码

// ✅ 安全 - 验证 URL 协议
function isSafeUrl(url: string): boolean {
  try {
    const parsed = new URL(url);
    return ['http:', 'https:'].includes(parsed.protocol);
  } catch {
    return false;
  }
}

// 使用
{isSafeUrl(url) && <a href={url}>Link</a>}
```

## 敏感数据处理

### 绝对禁止

```typescript
// ❌ 禁止存入 localStorage/sessionStorage
localStorage.setItem('privateKey', key);
localStorage.setItem('mnemonic', mnemonic);
sessionStorage.setItem('password', pwd);

// ❌ 禁止打印到控制台
console.log('Private Key:', privateKey);
console.log('API Secret:', apiSecret);
console.log('User token:', token);

// ❌ 禁止硬编码
const API_KEY = 'sk-xxxxxxxxxxxx'; // 绝对禁止
```

### 敏感数据脱敏显示

```typescript
// 钱包地址脱敏
function maskAddress(address: string): string {
  if (!address || address.length < 10) return address;
  return `${address.slice(0, 6)}...${address.slice(-4)}`;
}
// 0x1234567890abcdef1234567890abcdef12345678
// -> 0x1234...5678

// 邮箱脱敏
function maskEmail(email: string): string {
  const [name, domain] = email.split('@');
  if (!domain) return email;
  const masked = name.length > 2 ? `${name[0]}***${name[name.length - 1]}` : '***';
  return `${masked}@${domain}`;
}
// john.doe@example.com -> j***e@example.com

// API Key 脱敏
function maskApiKey(key: string): string {
  if (!key || key.length < 8) return '****';
  return `${key.slice(0, 4)}****${key.slice(-4)}`;
}
```

### 敏感数据生命周期

```typescript
// ✅ 敏感数据用完立即清除
async function signTransaction(privateKey: string) {
  try {
    const signature = await sign(privateKey);
    return signature;
  } finally {
    // 无法真正清除 JS 字符串，但可以覆盖变量引用
    privateKey = '';
  }
}

// ✅ 组件卸载时清除敏感状态
useEffect(() => {
  return () => {
    setPrivateKey('');
    setMnemonic('');
  };
}, []);
```

## 输入验证

客户端验证是用户体验，不是安全防线，但仍需做好：

```typescript
// ✅ 前端验证 + 类型约束
const schema = z.object({
  // 金额验证
  amount: z
    .string()
    .min(1, '请输入金额')
    .regex(/^\d+(\.\d{1,8})?$/, '无效金额')
    .refine((v) => parseFloat(v) > 0, '金额必须大于0')
    .refine((v) => parseFloat(v) <= maxAmount, `最大金额 ${maxAmount}`),

  // 地址验证
  address: z.string().regex(/^0x[a-fA-F0-9]{40}$/, '无效的 EVM 地址'),

  // 防止特殊字符注入
  username: z
    .string()
    .min(2)
    .max(50)
    .regex(/^[a-zA-Z0-9_-]+$/, '只允许字母、数字、下划线和连字符'),
});
```

## 第三方依赖安全

```bash
# 定期检查漏洞
pnpm audit

# 检查过时依赖
pnpm outdated
```

**依赖引入原则：**

- 优先使用知名、维护活跃的包
- 检查 npm 下载量和 GitHub stars
- 大版本升级前查看 changelog 和 breaking changes
- 避免引入不必要的依赖

## 安全清单

| 检查项       | 说明                                 |
| ------------ | ------------------------------------ |
| 无硬编码密钥 | API Key、Secret 等必须从环境变量读取 |
| 无敏感日志   | console.log 不包含私钥、密码、token  |
| XSS 防护     | 用户输入不直接渲染为 HTML            |
| URL 验证     | 动态 href 验证协议                   |
| 输入验证     | 所有用户输入经过 Zod 验证            |
| 脱敏显示     | 地址、邮箱、密钥等敏感信息脱敏展示   |
