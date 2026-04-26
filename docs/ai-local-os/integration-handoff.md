# AI-local-OS 集成移交与推进清单（方案 A → 可运行）

> 前置阅读：[README](./README.md)、[设计规格 §5–6](../specs/2026-04-26-ai-local-os-design.md)。  
> 侧车更新：填写本文 **§2 官方文档链接表** 后，请将 URL 同步到 [REQ-2026-0426](../../debug/superpowers-intent/REQ-2026-0426-ai-local-os.md)「**产品与 API 文档链接**」节，并在「后续跟踪清单」勾选对应项（或随 PR 更新）。

---

## 1. 本页用途

仓库内规格与模板已齐；本页把 **从纸面到可跑** 拆成可勾选步骤，避免遗漏密钥、实例隔离与 OpenClaw 侧接入顺序。**不**替代各产品官方文档。

---

## 2. 官方文档链接（由负责人填写）

将下列表格填完后提交仓库（或仅内网可见时：填脱敏副本 + REQ 内说明「链接仅存内网 wiki」）。

| 系统 | 产品名称 / 版本 | 文档 URL | 备注（如：插件入口、鉴权章节） |
| --- | --- | --- | --- |
| OpenClaw | （待填） | （待填） | 自定义函数 / 插件、环境变量 |
| Hermes | （待填） | （待填） | HTTP API、API Key、CORS |

---

## 3. 本地实例与密钥

- [ ] 复制 [hermes-instances.template.yaml](./hermes-instances.template.yaml) 为本地专用文件；推荐使用 `docs/ai-local-os/hermes-instances.local.yaml`（已在仓库 [.gitignore](../../.gitignore) 中忽略），**勿**将含真实 Key 的文件提交 Git。
- [ ] 复制 [.env.example](./.env.example) 为 `.env` 或接入宿主环境；确认 `.env` 已在 [.gitignore](../../.gitignore) 或等价忽略规则中。
- [ ] 确认每台 Hermes **独立端口、独立数据目录**（见规格 §4）。

---

## 4. OpenClaw 侧接入顺序（概念）

与规格 [§5](../specs/2026-04-26-ai-local-os-design.md) 一致，建议顺序：

1. 在 OpenClaw 中创建「AI-local-OS 垂类心智调度」类插件/函数（具体名称以你方规范为准）。
2. 加载实例清单：自 YAML 或环境变量解析 `baseUrl`、`timeoutMs`、标签路由。
3. 实现对外调用：向 Hermes 发起 HTTP 请求；配置 **超时、错误捕获、熔断**；失败时 **内核兜底** 并明确告知用户。

路由行为以 [routing-rules.md](./routing-rules.md) 为准。

---

## 5. 仓库内拓扑与流程参考（PDF）

以下文件在仓库根目录，便于对照拓扑与接入流程（路径以你本机克隆为准）：

- `AI-local-OS：OpenClaw+Hermes 私有化本地智能操作系统方案.pdf`
- `OpenClaw + Hermes 双智能体融合架构（拓扑图+接入流程）.pdf`

---

## 6. 完成后

1. 在 REQ「产品与 API 文档链接」粘贴表格摘要，并在「后续跟踪清单」勾选 **「实际 OpenClaw / Hermes 产品形态与 API 文档链接写入本节」**。  
2. 填写分支 / PR / 负责人在 REQ 元信息表。  
3. 若 REQ 或本页将含**不可公开**链接：按 REQ 清单在规格中声明，并考虑将 `debug/superpowers-intent/` 或含密链接的副本纳入 `.gitignore`。
