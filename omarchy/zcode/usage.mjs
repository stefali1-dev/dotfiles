#!/usr/bin/env node
// Prints the Z.ai Coding Plan usage limits the ZCode desktop app shows. `--json` for scripts, `--raw` for the API response,
// `--omarchy-record` writes them for Omarchy's agents panel (run by zcode-usage.timer).
import { createDecipheriv, createHash } from "node:crypto";
import { readFileSync, renameSync, writeFileSync } from "node:fs";
import { homedir, platform, userInfo } from "node:os";

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
function windowName({ type, unit, number }) {
  if (unit === 3) return `${number}-hour`;
  if (unit === 6) return number === 1 ? "weekly" : `${number}-week`;
  return `${type} unit ${unit}×${number}`;
}

const credentials = JSON.parse(readFileSync(`${homedir()}/.zcode/v2/credentials.json`, "utf8"));
const apiKey = decrypt(Object.entries(credentials).find(([name]) => name.endsWith(":api-key"))[1]);
const { email } = JSON.parse(decrypt(credentials["oauth:zai:user_info"]));

// The monitor API takes the bare key, no "Bearer".
const response = await fetch("https://api.z.ai/api/monitor/usage/quota/limit", { headers: { authorization: apiKey } });
const body = await response.json();
if (process.argv.includes("--raw")) {
  console.log(JSON.stringify(body, null, 2));
  process.exit();
}
if (!body.success) {
  console.error(`zcode-usage: ${body.code} ${body.msg}`);
  process.exit(1);
}

const limits = body.data.limits.map((limit) => ({
  window: windowName(limit),
  type: limit.type,
  used: limit.currentValue,
  total: limit.usage,
  remaining: limit.remaining,
  usedPercent: Math.round((limit.currentValue / limit.usage) * 1000) / 10,
  resetsAt: new Date(limit.nextResetTime).toISOString(),
  ...(limit.usageDetails?.length ? { byModel: limit.usageDetails } : {}),
}));

if (process.argv.includes("--omarchy-record")) {
  // Omarchy's agents panel record (schemaVersion 1, /usr/share/omarchy/shell/plugins/agents): an Omarchy update may change it.
  const labels = { "5-hour": "Session (5-hour)", weekly: "Weekly (7-day)" };
  const record = {
    schemaVersion: 1,
    id: "zcode",
    name: "ZCode",
    updatedAt: new Date().toISOString(),
    ready: true,
    hasLocalStats: false,
    tierLabel: body.data.level[0].toUpperCase() + body.data.level.slice(1),
    limits: limits.map((limit) => ({ label: labels[limit.window] ?? limit.window, percent: limit.used / limit.total, resetsAt: limit.resetsAt })),
    usageStatusText: "",
    authHelpText: "Sign in again in the ZCode desktop app.",
  };
  const file = `${homedir()}/.local/state/omarchy/agents/usage/zcode.json`;
  writeFileSync(`${file}.tmp`, `${JSON.stringify(record, null, 2)}\n`);
  renameSync(`${file}.tmp`, file);
} else if (process.argv.includes("--json")) {
  console.log(JSON.stringify({ plan: body.data.level, email, limits }, null, 2));
} else {
  console.log(`Z.ai Coding Plan · ${body.data.level} · ${email}`);
  for (const limit of limits) {
    const resets = new Date(limit.resetsAt).toLocaleString("en-GB", { weekday: "short", day: "numeric", month: "short", hour: "2-digit", minute: "2-digit" });
    console.log(`  ${limit.window.padEnd(8)} ${String(limit.usedPercent).padStart(5)}% used  ${limit.used} / ${limit.total}  resets ${resets}`);
  }
}
