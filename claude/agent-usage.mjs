#!/usr/bin/env node
// Claude and Z.ai (zcode) plan usage in one shape, for people and orchestrator agents.
// Usage: agent-usage [claude|zcode] [--json]. `--omarchy-record` writes zcode's for Omarchy's agents panel (zcode-usage.timer).
import { createDecipheriv, createHash } from "node:crypto";
import { execFileSync } from "node:child_process";
import { readFileSync, renameSync, writeFileSync } from "node:fs";
import { homedir, platform, userInfo } from "node:os";

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

/** zcode's credential cipher (apps/zcode-cli/packages/adapters/src/auth/credential-cipher.ts). */
function decrypt(value) {
  const secret = `zcode-credential-fallback:${platform()}:${homedir()}:${userInfo().username}`;
  const key = createHash("sha256").update(secret).digest();
  const [iv, tag, data] = value.slice("enc:v1:".length).split(".").map((part) => Buffer.from(part, "base64url"));
  const decipher = createDecipheriv("aes-256-gcm", key, iv);
  decipher.setAuthTag(tag);
  return Buffer.concat([decipher.update(data), decipher.final()]).toString();
}

/** The desktop app's names: unit 3 is hours, unit 6 weeks (packages/ui/src/CodingPlanUsageRemainingPanel.tsx). */
function zcodeWindowName({ type, unit, number }) {
  if (unit === 3) return `${number}-hour`;
  if (unit === 6) return number === 1 ? "weekly" : `${number}-week`;
  return `${type} unit ${unit}×${number}`;
}

/** The Z.ai Coding Plan limits the ZCode desktop app shows, with the desktop login's API key. */
async function zcode() {
  const credentials = JSON.parse(readFileSync(`${homedir()}/.zcode/v2/credentials.json`, "utf8"));
  const apiKey = decrypt(Object.entries(credentials).find(([name]) => name.endsWith(":api-key"))[1]);
  const { email } = JSON.parse(decrypt(credentials["oauth:zai:user_info"]));
  // The monitor API takes the bare key, no "Bearer".
  const response = await fetch("https://api.z.ai/api/monitor/usage/quota/limit", { headers: { authorization: apiKey } });
  const body = await response.json();
  if (!body.success) throw new Error(`usage API ${body.code} ${body.msg}`);
  return {
    plan: body.data.level,
    email,
    limits: body.data.limits.map((limit) => ({
      window: zcodeWindowName(limit),
      usedPercent: Math.round((limit.currentValue / limit.usage) * 1000) / 10,
      resetsAt: new Date(limit.nextResetTime).toISOString(),
      type: limit.type,
      used: limit.currentValue,
      total: limit.usage,
      ...(limit.usageDetails?.length ? { byModel: limit.usageDetails } : {}),
    })),
  };
}

/** Omarchy's agents panel record (schemaVersion 1, /usr/share/omarchy/shell/plugins/agents): an Omarchy update may change it. */
function writeOmarchyRecord({ plan, limits }) {
  const labels = { "5-hour": "Session (5-hour)", weekly: "Weekly (7-day)" };
  const record = {
    schemaVersion: 1,
    id: "zcode",
    name: "ZCode",
    updatedAt: new Date().toISOString(),
    ready: true,
    hasLocalStats: false,
    tierLabel: plan[0].toUpperCase() + plan.slice(1),
    limits: limits.map((limit) => ({ label: labels[limit.window] ?? limit.window, percent: limit.used / limit.total, resetsAt: limit.resetsAt })),
    usageStatusText: "",
    authHelpText: "Sign in again in the ZCode desktop app.",
  };
  const file = `${homedir()}/.local/state/omarchy/agents/usage/zcode.json`;
  writeFileSync(`${file}.tmp`, `${JSON.stringify(record, null, 2)}\n`);
  renameSync(`${file}.tmp`, file);
}

if (process.argv.includes("--omarchy-record")) {
  writeOmarchyRecord(await zcode());
  process.exit();
}

const providers = { claude, zcode };
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
