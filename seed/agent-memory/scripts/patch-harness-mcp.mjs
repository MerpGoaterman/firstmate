#!/usr/bin/env node
import fs from "node:fs";

const [harness, configPath, homeDir] = process.argv.slice(2);
if (!harness || !configPath || !homeDir) {
  console.error("usage: patch-harness-mcp.mjs <claude|opencode> <config-path> <home-dir>");
  process.exit(1);
}

const text = fs.existsSync(configPath) ? fs.readFileSync(configPath, "utf8") : "";
let data = {};
if (text.trim()) {
  data = JSON.parse(text);
}

if (harness === "claude") {
  data.mcpServers ??= {};
  if (!data.mcpServers.memwal) {
    data.mcpServers.memwal = {
      type: "stdio",
      command: "npx",
      args: ["-y", "@mysten-incubation/memwal-mcp"],
      env: {},
    };
    fs.writeFileSync(configPath, `${JSON.stringify(data, null, 2)}\n`);
    console.log(`patched: ${configPath} (claude memwal)`);
  } else {
    console.log(`unchanged: ${configPath} (claude memwal already present)`);
  }
  process.exit(0);
}

if (harness === "opencode") {
  data.mcp ??= {};
  if (!data.mcp.memwal) {
    data.mcp.memwal = {
      type: "local",
      command: ["npx", "-y", "@mysten-incubation/memwal-mcp"],
      cwd: homeDir,
      enabled: true,
      timeout: 60000,
    };
    fs.writeFileSync(configPath, `${JSON.stringify(data, null, 2)}\n`);
    console.log(`patched: ${configPath} (opencode memwal)`);
  } else {
    console.log(`unchanged: ${configPath} (opencode memwal already present)`);
  }
  process.exit(0);
}

console.error(`error: unknown harness: ${harness}`);
process.exit(1);