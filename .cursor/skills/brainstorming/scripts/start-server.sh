#!/usr/bin/env bash
# 启动头脑风暴服务器并输出连接信息
# 用法: start-server.sh [--project-dir <path>] [--host <bind-host>] [--url-host <display-host>] [--foreground] [--background]
#
# 在随机高端口上启动服务器，输出包含 URL 的 JSON。
# 每个会话有独立目录以避免冲突。
#
# 选项:
#   --project-dir <path>  将会话文件存储在 <path>/.agent/brainstorm/ 下，
#                         而非 /tmp。服务器停止后文件会保留。
#   --host <bind-host>    绑定的主机/接口（默认: 127.0.0.1）。
#                         在远程/容器化环境中使用 0.0.0.0。
#   --url-host <host>     返回的 URL JSON 中显示的主机名。
#   --foreground          在当前终端运行服务器（不放入后台）。
#   --background          强制后台模式（覆盖 Codex 自动前台模式）。

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# 解析参数
PROJECT_DIR=""
FOREGROUND="false"
FORCE_BACKGROUND="false"
BIND_HOST="127.0.0.1"
URL_HOST=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-dir)
      PROJECT_DIR="$2"
      shift 2
      ;;
    --host)
      BIND_HOST="$2"
      shift 2
      ;;
    --url-host)
      URL_HOST="$2"
      shift 2
      ;;
    --foreground|--no-daemon)
      FOREGROUND="true"
      shift
      ;;
    --background|--daemon)
      FORCE_BACKGROUND="true"
      shift
      ;;
    *)
      echo "{\"error\": \"Unknown argument: $1\"}"
      exit 1
      ;;
  esac
done

if [[ -z "$URL_HOST" ]]; then
  if [[ "$BIND_HOST" == "127.0.0.1" || "$BIND_HOST" == "localhost" ]]; then
    URL_HOST="localhost"
  else
    URL_HOST="$BIND_HOST"
  fi
fi

# 某些环境会回收分离的/后台进程。检测到时自动切换为前台模式。
if [[ -n "${CODEX_CI:-}" && "$FOREGROUND" != "true" && "$FORCE_BACKGROUND" != "true" ]]; then
  FOREGROUND="true"
fi

# Windows/Git Bash 会回收 nohup 后台进程。检测到时自动切换为前台模式。
if [[ "$FOREGROUND" != "true" && "$FORCE_BACKGROUND" != "true" ]]; then
  case "${OSTYPE:-}" in
    msys*|cygwin*|mingw*) FOREGROUND="true" ;;
  esac
  if [[ -n "${MSYSTEM:-}" ]]; then
    FOREGROUND="true"
  fi
fi

# 生成唯一会话目录
SESSION_ID="$$-$(date +%s)"

if [[ -n "$PROJECT_DIR" ]]; then
  SCREEN_DIR="${PROJECT_DIR}/.agent/brainstorm/${SESSION_ID}"
else
  SCREEN_DIR="/tmp/brainstorm-${SESSION_ID}"
fi

PID_FILE="${SCREEN_DIR}/.server.pid"
LOG_FILE="${SCREEN_DIR}/.server.log"

# 创建新的会话目录
mkdir -p "$SCREEN_DIR"

# 终止已有的服务器
if [[ -f "$PID_FILE" ]]; then
  old_pid=$(cat "$PID_FILE")
  kill "$old_pid" 2>/dev/null
  rm -f "$PID_FILE"
fi

cd "$SCRIPT_DIR"

# 解析宿主 PID（此脚本的祖父进程）。
# $PPID 是宿主启动来运行我们的临时 shell——脚本退出时它就消失了。
# 宿主本身是 $PPID 的父进程。
OWNER_PID="$(ps -o ppid= -p "$PPID" 2>/dev/null | tr -d ' ')"
if [[ -z "$OWNER_PID" || "$OWNER_PID" == "1" ]]; then
  OWNER_PID="$PPID"
fi

# 在 Windows/MSYS2 上，MSYS2 的 PID 命名空间对 Node.js 不可见。
# 跳过宿主 PID 监控——30 分钟空闲超时可防止孤儿进程。
case "${OSTYPE:-}" in
  msys*|cygwin*|mingw*) OWNER_PID="" ;;
esac

# 前台模式，用于会回收分离的/后台进程的环境。
if [[ "$FOREGROUND" == "true" ]]; then
  echo "$$" > "$PID_FILE"
  env BRAINSTORM_DIR="$SCREEN_DIR" BRAINSTORM_HOST="$BIND_HOST" BRAINSTORM_URL_HOST="$URL_HOST" BRAINSTORM_OWNER_PID="$OWNER_PID" node server.cjs
  exit $?
fi

# 启动服务器，将输出捕获到日志文件
# 使用 nohup 使进程在 shell 退出后存活；使用 disown 从作业表中移除
nohup env BRAINSTORM_DIR="$SCREEN_DIR" BRAINSTORM_HOST="$BIND_HOST" BRAINSTORM_URL_HOST="$URL_HOST" BRAINSTORM_OWNER_PID="$OWNER_PID" node server.cjs > "$LOG_FILE" 2>&1 &
SERVER_PID=$!
disown "$SERVER_PID" 2>/dev/null
echo "$SERVER_PID" > "$PID_FILE"

# 等待 server-started 消息（检查日志文件）
for i in {1..50}; do
  if grep -q "server-started" "$LOG_FILE" 2>/dev/null; then
    # 短暂等待后验证服务器是否仍然存活（捕获进程回收器的影响）
    alive="true"
    for _ in {1..20}; do
      if ! kill -0 "$SERVER_PID" 2>/dev/null; then
        alive="false"
        break
      fi
      sleep 0.1
    done
    if [[ "$alive" != "true" ]]; then
      echo "{\"error\": \"Server started but was killed. Retry in a persistent terminal with: $SCRIPT_DIR/start-server.sh${PROJECT_DIR:+ --project-dir $PROJECT_DIR} --host $BIND_HOST --url-host $URL_HOST --foreground\"}"
      exit 1
    fi
    grep "server-started" "$LOG_FILE" | head -1
    exit 0
  fi
  sleep 0.1
done

# 超时 - 服务器未能启动
echo '{"error": "Server failed to start within 5 seconds"}'
exit 1
