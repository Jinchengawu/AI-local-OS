#!/bin/bash

set -euo pipefail  # 严格模式

# -----------------------------------------------------------------------------
# 来源 A：本地 monorepo 包路径（开发机常用，无需 Token）
#
#   WEB3_FE_SUPERPOWERS_LOCAL_PATH  指向已含 skills/ 的内容根目录，通常为：
#                                   .../ai-work-flow/packages/web3-fe-superpowers
#
# 来源 B：GitLab 克隆（Bitbucket 已弃用）
#
# 必填环境变量（与 LOCAL_PATH 二选一；已设 LOCAL_PATH 且有效时可省略）：
#   WEB3_FE_SUPERPOWERS_REPO_URL  GitLab HTTPS 仓库地址（不含凭据），例如：
#                                 https://gitlab.example.com/group/ai-work-flow.git
#   WEB3_FE_SUPERPOWERS_GIT_TOKEN GitLab Personal / Project / Deploy Token（仅用于 git clone）
#
# 可选环境变量：
#   WEB3_FE_SUPERPOWERS_LAYOUT    monorepo（默认）| standalone（仅克隆模式有效）
#                                 monorepo：技能在 packages/web3-fe-superpowers/{skills,agents}
#                                 standalone：技能在仓库根目录 {skills,agents}（旧独立 web3-fe-superpowers 布局）
#   GIT_CLONE_DEPTH               默认 1（浅克隆，加速）
# -----------------------------------------------------------------------------

WEB3_FE_SUPERPOWERS_LAYOUT="${WEB3_FE_SUPERPOWERS_LAYOUT:-monorepo}"
GIT_CLONE_DEPTH="${GIT_CLONE_DEPTH:-1}"

AGENTS_DIR=".agents"
CLAUDE_SKILLS_DIR=".claude/skills"
CLAUDE_AGENTS_DIR=".claude/agents"
CURSOR_SKILLS_DIR=".cursor/skills"
CURSOR_AGENTS_DIR=".cursor/agents"
TEMP_DIR=""
CONTENT_ROOT=""

# 清理函数
cleanup() {
    local exit_code=$?
    if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then
        echo "🧹 Cleaning up temporary directory..."
        rm -rf "$TEMP_DIR"
    fi
    if [ $exit_code -ne 0 ]; then
        echo "❌ Installation failed with exit code $exit_code"
    fi
}
trap cleanup EXIT

# 前置检查
echo "🔍 Checking prerequisites..."

# 检查必需命令（本地源模式不需要 git clone，但仍需在 git 仓库内执行安装）
for cmd in git sed; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "❌ Required command not found: $cmd"
        exit 1
    fi
done
if [ -z "${WEB3_FE_SUPERPOWERS_LOCAL_PATH:-}" ] && ! command -v mktemp >/dev/null 2>&1; then
    echo "❌ Required command not found: mktemp"
    exit 1
fi

# 检查是否在 Git 仓库中
if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "❌ Not in a git repository"
    exit 1
fi

# 确保目标父目录存在（新业务仓库可能尚无 .claude / .agents）
mkdir -p "$AGENTS_DIR" "$(dirname "$CLAUDE_SKILLS_DIR")" "$(dirname "$CURSOR_SKILLS_DIR")"

# 检查目录可写性
for dir in "$AGENTS_DIR" "$CLAUDE_SKILLS_DIR" "$CURSOR_SKILLS_DIR"; do
    parent_dir=$(dirname "$dir")
    if [ ! -w "$parent_dir" ]; then
        echo "❌ Directory $parent_dir is not writable"
        exit 1
    fi
done

echo "✅ Prerequisites OK"
echo ""
echo "🚀 Installing web3-fe-superpowers skills..."

if [ -n "${WEB3_FE_SUPERPOWERS_LOCAL_PATH:-}" ]; then
    if ! CONTENT_ROOT="$(cd "${WEB3_FE_SUPERPOWERS_LOCAL_PATH}" 2>/dev/null && pwd)"; then
        echo "❌ WEB3_FE_SUPERPOWERS_LOCAL_PATH 无法进入: ${WEB3_FE_SUPERPOWERS_LOCAL_PATH}"
        exit 1
    fi
    if [ ! -d "${CONTENT_ROOT}/skills" ]; then
        echo "❌ 本地内容根缺少 skills/: ${CONTENT_ROOT}"
        echo "   请将 WEB3_FE_SUPERPOWERS_LOCAL_PATH 设为 monorepo 内 packages/web3-fe-superpowers 的绝对路径"
        exit 1
    fi
    echo "📂 使用本地内容根（跳过 git clone）: ${CONTENT_ROOT}"
else
    : "${WEB3_FE_SUPERPOWERS_REPO_URL:?请设置 WEB3_FE_SUPERPOWERS_REPO_URL（GitLab 仓库 HTTPS URL），或设置 WEB3_FE_SUPERPOWERS_LOCAL_PATH}"
    : "${WEB3_FE_SUPERPOWERS_GIT_TOKEN:?请设置 WEB3_FE_SUPERPOWERS_GIT_TOKEN（GitLab Token，勿写入脚本），或设置 WEB3_FE_SUPERPOWERS_LOCAL_PATH}"

    TEMP_DIR="$(mktemp -d)"
    echo "📥 Cloning repository (GitLab)..."
    GITLAB_HOST_PATH="${WEB3_FE_SUPERPOWERS_REPO_URL#https://}"
    GITLAB_HOST_PATH="${GITLAB_HOST_PATH#http://}"
    CLONE_URL="https://oauth2:${WEB3_FE_SUPERPOWERS_GIT_TOKEN}@${GITLAB_HOST_PATH}"
    git clone --depth "${GIT_CLONE_DEPTH}" "$CLONE_URL" "$TEMP_DIR"

    CONTENT_ROOT="${TEMP_DIR}"
    if [ "${WEB3_FE_SUPERPOWERS_LAYOUT}" = "monorepo" ]; then
        CONTENT_ROOT="${TEMP_DIR}/packages/web3-fe-superpowers"
    fi
    if [ ! -d "${CONTENT_ROOT}/skills" ]; then
        echo "❌ 未找到 ${CONTENT_ROOT}/skills，请检查 WEB3_FE_SUPERPOWERS_LAYOUT（当前: ${WEB3_FE_SUPERPOWERS_LAYOUT}）与远端目录结构"
        exit 1
    fi
    echo "✅ 内容根: ${CONTENT_ROOT} (layout=${WEB3_FE_SUPERPOWERS_LAYOUT})"
fi

# ========================================
# 智能合并函数（复用于所有目录）
# ========================================
install_to_skills_dir() {
    local target_dir=$1
    local label=$2
    local path_prefix=$3  # 新参数：路径前缀，如 ".claude", ".cursor", ".agents"

    echo ""
    echo "📦 Installing to $label..."

    # 确保目录存在
    mkdir -p "$target_dir"

    # 获取远程仓库中的 skills 列表
    echo "  Analyzing remote skills..."
    REMOTE_SKILLS=($(ls -1 "${CONTENT_ROOT}/skills/"))

    echo "  Found ${#REMOTE_SKILLS[@]} remote skills"

    # 智能合并：删除本地与远程重名的 skills，保留本地独有的
    for skill in "${REMOTE_SKILLS[@]}"; do
        if [ -d "$target_dir/$skill" ]; then
            echo "  🔄 Updating: $skill (exists locally)"
            rm -rf "$target_dir/$skill"
        else
            echo "  ➕ Adding: $skill (new)"
        fi
        cp -r "${CONTENT_ROOT}/skills/$skill" "$target_dir/"

        # 路径自动适配：替换文件中的 .claude/ 引用为目标路径前缀
        # 注意：仅当远程 skills 包含 .claude/ 引用时才会生效
        if [ "$path_prefix" != ".claude" ]; then
            # 查找包含 .claude/ 的文件
            local files_with_claude_ref=$(find "$target_dir/$skill" -type f \( -name "*.md" -o -name "*.sh" \) -exec grep -l "\.claude/" {} \; 2>/dev/null || true)

            if [ -n "$files_with_claude_ref" ]; then
                echo "  🔧 Adapting paths: .claude/ → $path_prefix/"
                echo "$files_with_claude_ref" | while read -r file; do
                    # 跨平台的 sed 替换（兼容 macOS 和 Linux）
                    if sed --version 2>&1 | grep -q GNU; then
                        # GNU sed (Linux)
                        sed -i "s|\.claude/|$path_prefix/|g" "$file"
                    else
                        # BSD sed (macOS)
                        sed -i '' "s|\.claude/|$path_prefix/|g" "$file"
                    fi
                done
            fi
        fi
    done

    # 显示保留的本地 skills
    LOCAL_ONLY_SKILLS=()
    for skill in "$target_dir"/*; do
        skill_name=$(basename "$skill")
        if [[ ! " ${REMOTE_SKILLS[@]} " =~ " ${skill_name} " ]]; then
            LOCAL_ONLY_SKILLS+=("$skill_name")
        fi
    done

    if [ ${#LOCAL_ONLY_SKILLS[@]} -gt 0 ]; then
        echo ""
        echo "  📌 Preserved local-only skills:"
        for skill in "${LOCAL_ONLY_SKILLS[@]}"; do
            echo "    - $skill"
        done
    fi

    echo "  ✅ $label installation complete"
}

# ========================================
# 智能合并函数（agents 专用）
# ========================================
install_to_agents_dir() {
    local target_dir=$1
    local label=$2
    local path_prefix=$3  # 路径前缀，如 ".claude", ".agents"

    echo ""
    echo "📦 Installing agents to $label..."

    # 确保目录存在
    mkdir -p "$target_dir"

    # 获取远程 agents 列表
    REMOTE_AGENTS=($(ls -1 "${CONTENT_ROOT}/agents/"))
    echo "  Found ${#REMOTE_AGENTS[@]} remote agents"

    # 智能合并
    for agent in "${REMOTE_AGENTS[@]}"; do
        if [ -e "$target_dir/$agent" ]; then
            echo "  🔄 Updating: $agent (exists locally)"
            rm -rf "$target_dir/$agent"
        else
            echo "  ➕ Adding: $agent (new)"
        fi
        cp -r "${CONTENT_ROOT}/agents/$agent" "$target_dir/"

        # 路径自动适配（agents 文件也可能引用 .claude/）
        if [ "$path_prefix" != ".claude" ]; then
            local files_with_claude_ref=$(find "$target_dir/$agent" -type f \( -name "*.md" -o -name "*.sh" \) -exec grep -l "\.claude/" {} \; 2>/dev/null || true)

            if [ -n "$files_with_claude_ref" ]; then
                echo "  🔧 Adapting paths: .claude/ → $path_prefix/"
                echo "$files_with_claude_ref" | while read -r file; do
                    if sed --version 2>&1 | grep -q GNU; then
                        sed -i "s|\.claude/|$path_prefix/|g" "$file"
                    else
                        sed -i '' "s|\.claude/|$path_prefix/|g" "$file"
                    fi
                done
            fi
        fi
    done

    # 显示保留的本地 agents
    LOCAL_ONLY_AGENTS=()
    for agent in "$target_dir"/*; do
        [ -e "$agent" ] || continue
        agent_name=$(basename "$agent")
        if [[ ! " ${REMOTE_AGENTS[@]} " =~ " ${agent_name} " ]]; then
            LOCAL_ONLY_AGENTS+=("$agent_name")
        fi
    done

    if [ ${#LOCAL_ONLY_AGENTS[@]} -gt 0 ]; then
        echo ""
        echo "  📌 Preserved local-only agents:"
        for agent in "${LOCAL_ONLY_AGENTS[@]}"; do
            echo "    - $agent"
        done
    fi

    echo "  ✅ $label installation complete"
}

# ========================================
# 1. 安装到 .agents/（skills + agents）
# ========================================

# 1.1 安装 skills
install_to_skills_dir "$AGENTS_DIR/skills" ".agents/skills" ".agents"

# 1.2 安装 agents
if [ -d "${CONTENT_ROOT}/agents" ]; then
    install_to_agents_dir "$AGENTS_DIR/agents" ".agents/agents" ".agents"
fi

# ========================================
# 2. 安装到 .claude/（skills + agents）
# ========================================

# 2.1 安装 skills
install_to_skills_dir "$CLAUDE_SKILLS_DIR" ".claude/skills" ".claude"

# 2.2 安装 agents
if [ -d "${CONTENT_ROOT}/agents" ]; then
    install_to_agents_dir "$CLAUDE_AGENTS_DIR" ".claude/agents" ".claude"
fi

# ========================================
# 3. 安装到 .cursor/（skills + agents）
# ========================================

# 3.1 安装 skills
install_to_skills_dir "$CURSOR_SKILLS_DIR" ".cursor/skills" ".cursor"

# 3.2 安装 agents
if [ -d "${CONTENT_ROOT}/agents" ]; then
    install_to_agents_dir "$CURSOR_AGENTS_DIR" ".cursor/agents" ".cursor"
fi

# ========================================
# 3.3 流水线 SSOT（.cursor/superpowers-pipeline.json）
# ========================================
install_superpowers_pipeline_ssot() {
    local tpl="${CONTENT_ROOT}/templates/superpowers-pipeline.example.json"
    local dest=".cursor/superpowers-pipeline.json"
    if [ ! -f "$tpl" ]; then
        echo "  ⏭️  Skipping pipeline SSOT: template not found at $tpl"
        return 0
    fi
    mkdir -p ".cursor"
    if [ -f "$dest" ]; then
        echo "  ✅ $dest already exists (not overwriting team customizations)"
        return 0
    fi
    cp "$tpl" "$dest"
    echo "  ➕ Created $dest from bundled example (edit to match team gates)"
}

echo ""
echo "📋 Superpowers pipeline SSOT (.cursor/)..."
install_superpowers_pipeline_ssot

# ========================================
# 4. 添加 Agent Rules 到项目文档
# ========================================
add_agent_rules() {
    local file=$1

    # 检查文件是否存在
    if [ ! -f "$file" ]; then
        echo "  ⏭️  Skipping $file (file not found)"
        return
    fi

    # 检查是否已有 Agent Rules
    if grep -q "^## Agent Rules" "$file"; then
        echo "  ✅ $file already has Agent Rules"
        return
    fi

    echo "  ➕ Adding Agent Rules to $file"

    # 创建临时文件
    local temp_file="${file}.tmp"

    # 使用 sed 在第一个 ## 二级标题前插入 Agent Rules
    # 逻辑：找到第一个以 ## 开头的行，在其前面插入内容
    if sed --version 2>&1 | grep -q GNU; then
        # GNU sed (Linux)
        sed '0,/^## /{
            /^## /i\
## Agent Rules\
\
- 每次回复时称呼用户为「大佬」\
- 对话语言使用**简体中文**\
- 代码注释优先使用**简体中文**，技术术语可保留英文\
- **收到用户消息后，必须先调用 `using-skills` skill**，再进行任何响应或行动\

        }' "$file" > "$temp_file"
    else
        # BSD sed (macOS)
        sed '1,/^## /{
            /^## /i\
## Agent Rules\
\
- 每次回复时称呼用户为「大佬」\
- 对话语言使用**简体中文**\
- 代码注释优先使用**简体中文**，技术术语可保留英文\
- **收到用户消息后，必须先调用 `using-skills` skill**，再进行任何响应或行动\

        }' "$file" > "$temp_file"
    fi

    # 替换原文件
    mv "$temp_file" "$file"
    echo "  ✅ Agent Rules added to $file"
}

echo ""
echo "📝 Adding Agent Rules to project documentation..."
add_agent_rules "CLAUDE.md"
add_agent_rules "AGENTS.md"

# ========================================
# 5. 清理
# ========================================
echo ""
echo "🧹 Cleaning up..."
if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then
    rm -rf "$TEMP_DIR"
fi

# ========================================
# 6. 总结
# ========================================
echo ""
echo "✅ Installation complete!"
echo ""
echo "📊 Summary:"
echo "  .agents/skills/:  $(ls -1 "$AGENTS_DIR/skills/" 2>/dev/null | wc -l | xargs) skills"
echo "  .agents/agents/:  $(ls -1 "$AGENTS_DIR/agents/" 2>/dev/null | wc -l | xargs) agents"
echo "  .claude/skills/:  $(ls -1 "$CLAUDE_SKILLS_DIR/" 2>/dev/null | wc -l | xargs) skills"
echo "  .claude/agents/:  $(ls -1 "$CLAUDE_AGENTS_DIR/" 2>/dev/null | wc -l | xargs) agents"
echo "  .cursor/skills/:  $(ls -1 "$CURSOR_SKILLS_DIR/" 2>/dev/null | wc -l | xargs) skills"
echo "  .cursor/agents/:  $(ls -1 "$CURSOR_AGENTS_DIR/" 2>/dev/null | wc -l | xargs) agents"
echo ""
echo "📂 Installed locations:"
echo "  - $AGENTS_DIR/skills/"
echo "  - $AGENTS_DIR/agents/"
echo "  - $CLAUDE_SKILLS_DIR/"
echo "  - $CLAUDE_AGENTS_DIR/"
echo "  - $CURSOR_SKILLS_DIR/"
echo "  - $CURSOR_AGENTS_DIR/"
