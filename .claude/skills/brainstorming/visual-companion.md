# 可视化伴侣指南

基于浏览器的可视化头脑风暴伴侣，用于展示模型图、图表和选项。

## 何时使用

逐个问题判断，而非按会话判断。标准：**用户看到它是否比读到它更容易理解？**

**使用浏览器** 展示本身就是视觉性的内容：

- **UI 模型图** — 线框图、布局、导航结构、组件设计
- **架构图** — 系统组件、数据流、关系图
- **并排视觉对比** — 对比两种布局、两种配色、两种设计方向
- **设计细节打磨** — 当问题关于外观感受、间距、视觉层次
- **空间关系** — 状态机、流程图、以图表渲染的实体关系

**使用终端** 展示文本或表格内容：

- **需求和范围问题** — "X 是什么意思？"、"哪些功能在范围内？"
- **概念性 A/B/C 选择** — 在文字描述的方案之间做选择
- **权衡清单** — 优缺点、对比表
- **技术决策** — API 设计、数据建模、架构方案选择
- **澄清问题** — 任何答案是文字而非视觉偏好的问题

关于 UI 主题的问题不一定是视觉问题。"你想要什么样的向导？"是概念性的——用终端。"这些向导布局中哪个感觉合适？"是视觉性的——用浏览器。

## 工作原理

服务器监控一个目录中的 HTML 文件，将最新的文件提供给浏览器。你写 HTML 内容，用户在浏览器中看到，可以点击选择选项。选择结果记录到 `.events` 文件中，你在下一轮对话时读取。

**内容片段 vs 完整文档：** 如果你的 HTML 文件以 `<!DOCTYPE` 或 `<html` 开头，服务器会原样提供（只注入 helper 脚本）。否则，服务器会自动用框架模板包装你的内容——添加头部、CSS 主题、选择指示器和所有交互基础设施。**默认编写内容片段。** 只有在需要完全控制页面时才编写完整文档。

## 启动会话

```bash
# 启动服务器并持久化（模型图保存到项目目录）
scripts/start-server.sh --project-dir /path/to/project

# 返回：{"type":"server-started","port":52341,"url":"http://localhost:52341",
#         "screen_dir":"/path/to/project/.agent/brainstorm/12345-1706000000"}
```

保存返回中的 `screen_dir`。告诉用户打开 URL。

**查找连接信息：** 服务器将启动 JSON 写入 `$SCREEN_DIR/.server-info`。如果你在后台启动服务器且未捕获 stdout，读取该文件获取 URL 和端口。使用 `--project-dir` 时，检查 `<project>/.agent/brainstorm/` 查找会话目录。

**注意：** 将项目根目录作为 `--project-dir` 传入，这样模型图文件会持久化到 `.agent/brainstorm/`，服务器重启后仍然存在。不传的话文件会放在 `/tmp` 并在停止时被清理。如果 `.agent/` 还未在 `.gitignore` 中，提醒用户添加。

**各平台启动方式：**

**Claude Code (macOS / Linux)：**

```bash
# 默认模式即可——脚本自行将服务器放入后台
scripts/start-server.sh --project-dir /path/to/project
```

**Claude Code (Windows)：**

```bash
# Windows 自动检测并使用前台模式，这会阻塞工具调用。
# 在 Bash 工具调用时设置 run_in_background: true，使服务器在对话轮次间存活。
scripts/start-server.sh --project-dir /path/to/project
```

通过 Bash 工具调用时，设置 `run_in_background: true`。然后在下一轮读取 `$SCREEN_DIR/.server-info` 获取 URL 和端口。

**Codex：**

```bash
# Codex 会回收后台进程。脚本自动检测 CODEX_CI 并切换到前台模式。
# 正常运行即可——不需要额外参数。
scripts/start-server.sh --project-dir /path/to/project
```

**Gemini CLI：**

```bash
# 使用 --foreground 并在 shell 工具调用中设置 is_background: true，
# 使进程在轮次间存活
scripts/start-server.sh --project-dir /path/to/project --foreground
```

**其他环境：** 服务器需要在后台跨对话轮次持续运行。如果你的环境会回收分离的/后台进程，使用 `--foreground` 并用你的平台的后台执行机制启动命令。

如果 URL 从浏览器无法访问（在远程/容器化环境中常见），绑定非回环地址：

```bash
scripts/start-server.sh \
  --project-dir /path/to/project \
  --host 0.0.0.0 \
  --url-host localhost
```

使用 `--url-host` 控制返回的 URL JSON 中显示的主机名。

## 循环流程

1. **检查服务器是否存活**，然后**写入 HTML** 到 `screen_dir` 中的新文件：
   - 每次写入前，检查 `$SCREEN_DIR/.server-info` 是否存在。如果不存在（或 `.server-stopped` 存在），服务器已关闭——在继续之前用 `start-server.sh` 重启。服务器在 30 分钟不活动后自动退出。
   - 使用语义化文件名：`platform.html`、`visual-style.html`、`layout.html`
   - **不要重用文件名** — 每个画面使用新文件
   - 使用 Write 工具 — **不要使用 cat/heredoc**（会在终端输出噪音）
   - 服务器自动提供最新的文件

2. **告诉用户期望看到什么并结束你的轮次：**
   - 提醒他们 URL（每步都要，不只是第一步）
   - 简要文字描述屏幕上的内容（例如"展示了 3 个首页布局选项"）
   - 请他们在终端回复："看一下，告诉我你的想法。如果愿意可以点击选择选项。"

3. **在你的下一轮** — 用户在终端回复后：
   - 如果存在，读取 `$SCREEN_DIR/.events` — 包含用户在浏览器中的交互（点击、选择），格式为 JSON 行
   - 与用户的终端文字合并，获取完整画面
   - 终端消息是主要反馈；`.events` 提供结构化的交互数据

4. **迭代或推进** — 如果反馈需要修改当前画面，写入新文件（例如 `layout-v2.html`）。只有当前步骤验证通过后才进入下一个问题。

5. **返回终端时卸载** — 当下一步不需要浏览器时（例如澄清问题、权衡讨论），推送等待画面以清除过时内容：

   ```html
   <!-- 文件名：waiting.html（或 waiting-2.html 等）-->
   <div style="display:flex;align-items:center;justify-content:center;min-height:60vh">
     <p class="subtitle">在终端继续中...</p>
   </div>
   ```

   这可以避免用户盯着一个已解决的选择，而对话已经继续了。当下一个视觉问题出现时，照常推送新内容文件。

6. 重复直到完成。

## 编写内容片段

只写放在页面内部的内容。服务器自动用框架模板包装（头部、主题 CSS、选择指示器和所有交互基础设施）。

**最小示例：**

```html
<h2>哪种布局更好？</h2>
<p class="subtitle">考虑可读性和视觉层次</p>

<div class="options">
  <div class="option" data-choice="a" onclick="toggleSelect(this)">
    <div class="letter">A</div>
    <div class="content">
      <h3>单栏布局</h3>
      <p>简洁、聚焦的阅读体验</p>
    </div>
  </div>
  <div class="option" data-choice="b" onclick="toggleSelect(this)">
    <div class="letter">B</div>
    <div class="content">
      <h3>双栏布局</h3>
      <p>侧边导航加主内容区域</p>
    </div>
  </div>
</div>
```

就这样。不需要 `<html>`，不需要 CSS，不需要 `<script>` 标签。服务器提供这一切。

## 可用 CSS 类

框架模板为你的内容提供以下 CSS 类：

### 选项（A/B/C 选择题）

```html
<div class="options">
  <div class="option" data-choice="a" onclick="toggleSelect(this)">
    <div class="letter">A</div>
    <div class="content">
      <h3>标题</h3>
      <p>描述</p>
    </div>
  </div>
</div>
```

**多选：** 在容器上添加 `data-multiselect` 允许用户选择多个选项。每次点击切换该项。指示栏显示选中数量。

```html
<div class="options" data-multiselect>
  <!-- 相同的选项标记——用户可以选择/取消选择多个 -->
</div>
```

### 卡片（视觉设计展示）

```html
<div class="cards">
  <div class="card" data-choice="design1" onclick="toggleSelect(this)">
    <div class="card-image"><!-- 模型图内容 --></div>
    <div class="card-body">
      <h3>名称</h3>
      <p>描述</p>
    </div>
  </div>
</div>
```

### 模型图容器

```html
<div class="mockup">
  <div class="mockup-header">预览：仪表盘布局</div>
  <div class="mockup-body"><!-- 你的模型图 HTML --></div>
</div>
```

### 分屏视图（并排对比）

```html
<div class="split">
  <div class="mockup"><!-- 左侧 --></div>
  <div class="mockup"><!-- 右侧 --></div>
</div>
```

### 优缺点

```html
<div class="pros-cons">
  <div class="pros">
    <h4>优点</h4>
    <ul>
      <li>好处</li>
    </ul>
  </div>
  <div class="cons">
    <h4>缺点</h4>
    <ul>
      <li>不足</li>
    </ul>
  </div>
</div>
```

### 模拟元素（线框图构建模块）

```html
<div class="mock-nav">Logo | 首页 | 关于 | 联系</div>
<div style="display: flex;">
  <div class="mock-sidebar">导航</div>
  <div class="mock-content">主内容区域</div>
</div>
<button class="mock-button">操作按钮</button>
<input class="mock-input" placeholder="输入框" />
<div class="placeholder">占位区域</div>
```

### 排版和分节

- `h2` — 页面标题
- `h3` — 章节标题
- `.subtitle` — 标题下方的二级文字
- `.section` — 带底部间距的内容块
- `.label` — 小号大写标签文字

## 浏览器事件格式

当用户在浏览器中点击选项时，交互记录到 `$SCREEN_DIR/.events`（每行一个 JSON 对象）。推送新画面时文件自动清空。

```jsonl
{"type":"click","choice":"a","text":"选项 A - 简单布局","timestamp":1706000101}
{"type":"click","choice":"c","text":"选项 C - 复杂网格","timestamp":1706000108}
{"type":"click","choice":"b","text":"选项 B - 混合型","timestamp":1706000115}
```

完整事件流展示了用户的探索路径——他们可能在最终确定之前点击多个选项。最后一个 `choice` 事件通常是最终选择，但点击模式可能揭示值得追问的犹豫或偏好。

如果 `.events` 不存在，用户没有与浏览器交互——只使用他们的终端文字。

## 设计技巧

- **保真度与问题匹配** — 布局问题用线框图，打磨问题用精细设计
- **每个页面解释问题** — "哪种布局看起来更专业？"而不只是"选一个"
- **先迭代再推进** — 如果反馈需要修改当前画面，先写新版本
- **每屏最多 2-4 个选项**
- **在需要时使用真实内容** — 例如摄影作品集就用实际图片（Unsplash）。占位内容会掩盖设计问题。
- **保持模型图简洁** — 聚焦布局和结构，而非像素级完美

## 文件命名

- 使用语义化命名：`platform.html`、`visual-style.html`、`layout.html`
- 不要重用文件名——每个画面必须是新文件
- 迭代时：添加版本后缀，如 `layout-v2.html`、`layout-v3.html`
- 服务器按修改时间提供最新文件

## 清理

```bash
scripts/stop-server.sh $SCREEN_DIR
```

如果会话使用了 `--project-dir`，模型图文件持久化在 `.agent/brainstorm/` 中供后续参考。只有 `/tmp` 会话在停止时被删除。

## 参考

- 框架模板（CSS 参考）：`scripts/frame-template.html`
- Helper 脚本（客户端）：`scripts/helper.js`
