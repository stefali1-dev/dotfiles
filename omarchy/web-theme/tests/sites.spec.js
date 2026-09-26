// Opens each page from pages.js in Brave, logged in through a copy of the real profile.
// THEME=off runs without the extension and only takes screenshots, for before/after comparison.
const { test: base, expect, chromium } = require("@playwright/test");
const { execFileSync } = require("child_process");
const fs = require("fs");
const os = require("os");
const path = require("path");
const sites = require("./pages");

const themeOn = process.env.THEME !== "off";
const braveProfile = path.join(os.homedir(), ".config/BraveSoftware/Brave-Browser");
const extension = path.resolve(__dirname, "../extension");
// Headless Brave says "HeadlessChrome", and YouTube then drops the account's dark mode.
const braveMajor = execFileSync("/opt/brave-bin/brave", ["--version"]).toString().match(/ (\d+)\./)[1];
const userAgent = `Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/${braveMajor}.0.0.0 Safari/537.36`;

const test = base.extend({
  // One Brave for the whole run: a profile directory can only be open once.
  brave: [
    async ({}, use) => {
      const dir = fs.mkdtempSync(path.join(os.tmpdir(), "omarchy-web-theme-"));
      // Logins and site settings, without caches and the profile's own extensions.
      execFileSync("rsync", [
        "-a",
        "--exclude=Cache", "--exclude=Code Cache", "--exclude=GPUCache",
        "--exclude=Service Worker", "--exclude=Extensions", "--exclude=Local Extension Settings",
        "--exclude=Sessions", "--exclude=adblock_cache", "--exclude=Shared Dictionary",
        `${braveProfile}/Local State`, `${braveProfile}/Default`, dir,
      ]);
      const context = await chromium.launchPersistentContext(dir, {
        executablePath: "/opt/brave-bin/brave",
        headless: true,
        viewport: { width: 1400, height: 900 },
        colorScheme: "dark",
        userAgent,
        // Playwright's basic password store can't decrypt the copied cookies; the keyring can.
        ignoreDefaultArgs: ["--password-store=basic", "--disable-extensions"],
        args: [
          "--password-store=gnome-libsecret",
          ...(themeOn ? [`--disable-extensions-except=${extension}`, `--load-extension=${extension}`] : []),
        ],
      });
      await use(context);
      await context.close();
      fs.rmSync(dir, { recursive: true, force: true });
    },
    { scope: "worker" },
  ],
});

// Visible elements over 2% of the viewport with a mostly opaque, neutral dark background:
// surfaces the site CSS missed, which look gray next to the theme's tinted background.
function grayPatches(ignore) {
  const viewportArea = innerWidth * innerHeight;
  const patches = [];
  for (const el of document.querySelectorAll("body *")) {
    if (ignore.some((selector) => el.closest(selector))) continue;
    const match = getComputedStyle(el).backgroundColor.match(/^rgba?\((\d+), (\d+), (\d+)(?:, ([\d.]+))?\)$/);
    if (!match || (match[4] !== undefined && Number(match[4]) < 0.8)) continue;
    const [r, g, b] = match.slice(1, 4).map(Number);
    if (Math.max(r, g, b) - Math.min(r, g, b) > 6 || Math.max(r, g, b) > 80) continue;
    const rect = el.getBoundingClientRect();
    const width = Math.min(rect.right, innerWidth) - Math.max(rect.left, 0);
    const height = Math.min(rect.bottom, innerHeight) - Math.max(rect.top, 0);
    if (width <= 0 || height <= 0 || width * height < viewportArea * 0.02) continue;
    const id = el.id ? `#${el.id}` : "";
    const cls = typeof el.className === "string" && el.className ? `.${el.className.trim().split(/\s+/).join(".")}` : "";
    patches.push(`${el.tagName.toLowerCase()}${id}${cls} rgb(${r}, ${g}, ${b})`.slice(0, 160));
  }
  return patches;
}

for (const [site, { surface, ignore = [], pages }] of Object.entries(sites)) {
  for (const [name, url] of Object.entries(pages)) {
    test(`${site} ${name}`, async ({ brave }) => {
      const page = await brave.newPage();
      await page.goto(url, { waitUntil: "domcontentloaded" });
      // Sites keep loading forever (feeds, video), so give the UI a fixed moment to settle.
      await page.waitForTimeout(5000);
      await page.screenshot({ path: `tests/screenshots/${site}-${name}${themeOn ? "" : "-off"}.png` });

      if (themeOn) {
        const [actual, expected] = await page.evaluate((selector) => {
          const probe = document.createElement("div");
          probe.style.backgroundColor = "var(--omarchy-background)";
          document.body.append(probe);
          const colors = [getComputedStyle(document.querySelector(selector)).backgroundColor, getComputedStyle(probe).backgroundColor];
          probe.remove();
          return colors;
        }, surface);
        expect.soft(actual, `${surface} background`).toBe(expected);
        expect(await page.evaluate(grayPatches, ignore)).toEqual([]);
      }
      await page.close();
    });
  }
}
