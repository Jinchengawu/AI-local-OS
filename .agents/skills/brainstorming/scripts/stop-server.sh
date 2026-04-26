#!/usr/bin/env bash
# 停止头脑风暴服务器并清理
# 用法: stop-server.sh <screen_dir>
#
# 终止服务器进程。只有在 /tmp 下的临时会话目录才会被删除。
# 持久化目录（.agent/）会保留以便后续查看模型图。

SCREEN_DIR="$1"

if [[ -z "$SCREEN_DIR" ]]; then
  echo '{"error": "Usage: stop-server.sh <screen_dir>"}'
  exit 1
fi

PID_FILE="${SCREEN_DIR}/.server.pid"

if [[ -f "$PID_FILE" ]]; then
  pid=$(cat "$PID_FILE")

  # 尝试优雅关闭，如果仍然存活则强制终止
  kill "$pid" 2>/dev/null || true

  # 等待优雅关闭（最多约 2 秒）
  for i in {1..20}; do
    if ! kill -0 "$pid" 2>/dev/null; then
      break
    fi
    sleep 0.1
  done

  # 如果仍在运行，升级为 SIGKILL
  if kill -0 "$pid" 2>/dev/null; then
    kill -9 "$pid" 2>/dev/null || true

    # 等待 SIGKILL 生效
    sleep 0.1
  fi

  if kill -0 "$pid" 2>/dev/null; then
    echo '{"status": "failed", "error": "process still running"}'
    exit 1
  fi

  rm -f "$PID_FILE" "${SCREEN_DIR}/.server.log"

  # 只删除临时的 /tmp 目录
  if [[ "$SCREEN_DIR" == /tmp/* ]]; then
    rm -rf "$SCREEN_DIR"
  fi

  echo '{"status": "stopped"}'
else
  echo '{"status": "not_running"}'
fi
