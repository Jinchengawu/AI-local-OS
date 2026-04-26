#!/usr/bin/env bash
# 一键接入/更新：自动加载 .env 后调用 install-web3-skills.sh
# 用法：在业务仓库任意目录执行
#   bash .cursor/skills/dev-ops/run-web3-skills-install.sh
# 或：chmod +x ... && ./run-web3-skills-install.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_SH="$SCRIPT_DIR/install-web3-skills.sh"

if [ ! -f "$INSTALL_SH" ]; then
  echo "❌ 未找到同目录下的 install-web3-skills.sh: $INSTALL_SH"
  exit 1
fi

PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [ -z "$PROJECT_ROOT" ]; then
  echo "❌ 请在 git 仓库内执行（需要定位项目根以加载配置与执行安装）"
  exit 1
fi

USER_ENV="${XDG_CONFIG_HOME:-$HOME/.config}/web3-fe-superpowers/env"
ENV_FILE="$PROJECT_ROOT/.env.web3-skills"

load_env_file() {
  local f="$1"
  echo "📂 加载环境: $f"
  set -a
  # shellcheck disable=SC1090
  source "$f"
  set +a
}

if [ -f "$ENV_FILE" ]; then
  load_env_file "$ENV_FILE"
elif [ -f "$USER_ENV" ]; then
  load_env_file "$USER_ENV"
fi

if [ -z "${WEB3_FE_SUPERPOWERS_LOCAL_PATH:-}" ]; then
  if [ -z "${WEB3_FE_SUPERPOWERS_REPO_URL:-}" ] || [ -z "${WEB3_FE_SUPERPOWERS_GIT_TOKEN:-}" ]; then
    echo ""
    echo "❌ 未设置 WEB3_FE_SUPERPOWERS_LOCAL_PATH，且缺少 WEB3_FE_SUPERPOWERS_REPO_URL 或 WEB3_FE_SUPERPOWERS_GIT_TOKEN"
    echo ""
    echo "任选其一："
    echo "  1) 本地 monorepo：在 .env.web3-skills 中设置 WEB3_FE_SUPERPOWERS_LOCAL_PATH=.../packages/web3-fe-superpowers"
    echo "  2) GitLab 克隆：在仓库根创建 .env.web3-skills（可复制包内 templates/env.web3-skills.example）并填写 URL + Token"
    echo "  3) 当前 shell: export WEB3_FE_SUPERPOWERS_LOCAL_PATH=... 或 export WEB3_FE_SUPERPOWERS_REPO_URL=... WEB3_FE_SUPERPOWERS_GIT_TOKEN=..."
    echo "  4) 用户级配置文件: $USER_ENV"
    echo ""
    echo "详见: skills/dev-ops/skills.md"
    exit 1
  fi
fi

export WEB3_FE_SUPERPOWERS_LOCAL_PATH="${WEB3_FE_SUPERPOWERS_LOCAL_PATH:-}"
export WEB3_FE_SUPERPOWERS_REPO_URL="${WEB3_FE_SUPERPOWERS_REPO_URL:-}"
export WEB3_FE_SUPERPOWERS_GIT_TOKEN="${WEB3_FE_SUPERPOWERS_GIT_TOKEN:-}"
export WEB3_FE_SUPERPOWERS_LAYOUT="${WEB3_FE_SUPERPOWERS_LAYOUT:-monorepo}"
export GIT_CLONE_DEPTH="${GIT_CLONE_DEPTH:-1}"

echo "🚀 项目根: $PROJECT_ROOT"
echo "📦 执行: install-web3-skills.sh (layout=${WEB3_FE_SUPERPOWERS_LAYOUT})"
cd "$PROJECT_ROOT"
exec bash "$INSTALL_SH"
