#!/usr/bin/env node
// Claude and Z.ai (zcode) plan usage in one shape, for people and orchestrator agents. `--json` for scripts.
import { execFileSync } from "node:child_process";
import { readFileSync } from "node:fs";
import { homedir, platform } from "node:os";

const windowNames = { session: "5-hour", weekly_all: "weekly" };

/** Live from the endpoint behind Claude Code's /usage. The token is only read: refreshing it would log out running sessions. */
// Undocumented endpoint: if Anthropic changes it, this throws and claude() falls back to the status line's cache.
async function claudeLive() {
  const credentials =
    platform() === "darwin"
      ? execFileSync("security", ["find-generic-password", "-s", "Claude Code-credentials", "-w"], { encoding: "utf8" })
      : readFileSync(`${homedir()}/.claude/.credentials.json`, "utf8");
  const { accessToken, subscriptionType } = JSON.parse(credentials).claudeAiOauth;
  const response = await fetch("https://api.anthropic.com/api/oauth/usage", {
    headers: { authorization: `Bearer ${accessToken}`, "anthropic-beta": "oauth-2025-04-20" },
  });
  if (!response.ok) throw new Error(`usage API ${response.status}`);
  const { limits } = await response.json();
  return {
    plan: subscriptionType,
    source: "live",
    limits: limits.map((limit) => ({
      window: windowNames[limit.kind] ?? limit.kind,
      usedPercent: limit.percent,
      resetsAt: new Date(limit.resets_at).toISOString(),
    })),
  };
}

/** What claude/statusline.sh saved at the last reply of any session. */
function claudeCache(error) {
  const cache = JSON.parse(readFileSync(`${homedir()}/.cache/claude-usage.json`, "utf8"));
  return {
    source: "cache",
    updatedAt: new Date(cache.updated_at * 1000).toISOString(),
    liveError: error.message,
    limits: [
      ["5-hour", cache.five_hour],
      ["weekly", cache.seven_day],
    ]
      .filter(([, window]) => window)
      .map(([window, { used_percentage, resets_at }]) => ({
        window,
        usedPercent: used_percentage,
        resetsAt: new Date(resets_at * 1000).toISOString(),
      })),
  };
}

async function claude() {
  try {
    return await claudeLive();
  } catch (error) {
    try {
      return claudeCache(error);
    } catch {
      return { error: error.message };
    }
  }
}

function zcode() {
  try {
    return { source: "live", ...JSON.parse(execFileSync("zcode-usage", ["--json"], { encoding: "utf8" })) };
  } catch (error) {
    return { error: error.code === "ENOENT" ? "zcode-usage not installed" : error.message.split("\n")[0] };
  }
}

const usage = { claude: await claude(), zcode: zcode() };

if (process.argv.includes("--json")) {
  console.log(JSON.stringify(usage, null, 2));
} else {
  for (const [provider, { plan, source, updatedAt, limits, error }] of Object.entries(usage)) {
    if (error) {
      console.log(`${provider}: ${error}`);
      continue;
    }
    const note = source === "cache" ? ` (cached ${new Date(updatedAt).toLocaleTimeString("en-GB", { hour: "2-digit", minute: "2-digit" })})` : "";
    console.log(`${provider}${plan ? ` (${plan})` : ""}${note}`);
    for (const { window, usedPercent, resetsAt } of limits) {
      const resets = new Date(resetsAt).toLocaleString("en-GB", { weekday: "short", hour: "2-digit", minute: "2-digit" });
      console.log(`  ${window.padEnd(8)} ${String(usedPercent).padStart(5)}% used  resets ${resets}`);
    }
  }
}
