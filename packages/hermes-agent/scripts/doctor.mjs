#!/usr/bin/env node
import { spawnSync } from "node:child_process";

function which(cmd) {
  const isWin = process.platform === "win32";
  const c = isWin ? "where" : "command";
  const args = isWin ? [cmd] : ["-v", cmd];
  const r = spawnSync(c, args, { encoding: "utf8", shell: isWin });
  return r.status === 0 ? (r.stdout || "").trim().split("\n")[0] : null;
}

const hermes = which("hermes");
if (!hermes) {
  console.warn(
    "[doctor] 未在 PATH 中找到 `hermes`（尚未安装属正常）。安装请执行: pnpm hermes:bootstrap 或官方 curl 命令。",
  );
  process.exit(0);
}

const ver = spawnSync("hermes", ["--version"], { encoding: "utf8", shell: true });
console.log("[doctor] hermes 路径:", hermes);
if (ver.stdout) console.log("[doctor] hermes --version:\n", ver.stdout.trim());
if (ver.stderr) console.error(ver.stderr.trim());
process.exit(ver.status === 0 ? 0 : ver.status ?? 1);
