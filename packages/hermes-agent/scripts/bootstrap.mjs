#!/usr/bin/env node
/**
 * 调用 Hermes Agent 官方安装脚本（需网络）。
 * 不在此仓库内嵌安装逻辑，避免与上游分叉。
 */
import { spawn } from "node:child_process";
import process from "node:process";

const INSTALL_URL =
  process.env.HERMES_INSTALL_URL ??
  "https://hermes-agent.nousresearch.com/install.sh";

console.log("[@ai-local-os/hermes-agent] 即将执行官方安装脚本：");
console.log(`  curl -fsSL ${INSTALL_URL} | bash`);
console.log("若需代理或镜像，请先设置环境变量 HERMES_INSTALL_URL。\n");

const child = spawn("bash", ["-lc", `set -euo pipefail; curl -fsSL '${INSTALL_URL.replace(/'/g, "'\\''")}' | bash`], {
  stdio: "inherit",
  env: process.env,
});

child.on("exit", (code, signal) => {
  if (signal) {
    process.exit(1);
  }
  process.exit(code ?? 1);
});
