#!/usr/bin/env node
// Claude plan usage, for people and orchestrator agents.
// Usage: agent-usage [--json].
import { execFileSync } from "node:child_process";
import { readFileSync } from "node:fs";
import { homedir, platform } from "node:os";

const windowNames = { session: "5-hour", weekly_all: "weekly" };

/** Live from the endpoint behind Claude Code's /usage. The token is only read: refreshing it would log out running sessions. */
// Undocumented endpoint: if Anthropic changes it, this throws and the claude entry shows the error.
async function claude() {
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
  const { emailAddress } = JSON.parse(readFileSync(`${homedir()}/.claude.json`, "utf8")).oauthAccount;
  return {
    plan: subscriptionType,
    email: emailAddress,
    limits: limits.map((limit) => ({
      window: windowNames[limit.kind] ?? limit.kind,
      usedPercent: limit.percent,
      resetsAt: new Date(limit.resets_at).toISOString(),
    })),
  };
}

const providers = { claude };
const picked = process.argv.slice(2).filter((arg) => arg in providers);
const usage = {};
for (const name of picked.length ? picked : Object.keys(providers)) {
  usage[name] = await providers[name]().catch((error) => ({ error: error.code === "ENOENT" ? `not signed in (${error.path} missing)` : error.message }));
}

if (process.argv.includes("--json")) {
  console.log(JSON.stringify(usage, null, 2));
} else {
  const blocks = Object.entries(usage).map(([provider, { plan, email, limits, error }]) => {
    if (error) return `${provider}: ${error}`;
    const lines = limits.map(({ window, usedPercent, resetsAt }) => {
      const resets = new Date(resetsAt).toLocaleString("en-GB", { weekday: "short", hour: "2-digit", minute: "2-digit" });
      return `  ${window.padEnd(8)} ${String(usedPercent).padStart(5)}% used  resets ${resets}`;
    });
    return [`${provider} · ${plan} · ${email}`, ...lines].join("\n");
  });
  console.log(blocks.join("\n\n"));
}
