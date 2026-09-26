# web-theme

A Brave extension that recolors the dark mode of a few sites with the current Omarchy theme, so they
match the rest of the desktop and Brave's tab strip. It only changes backgrounds, panels, lines and
the odd spot that looked wrong next to them; text, links, images and brand colors stay the site's own.

Sites: YouTube, ChatGPT, GitHub, X, Grok. Each is only recolored while the site itself is in dark
mode (X: "Lights out"; GitHub: "Dark", not "sync with system").

## How it works

- `generate.sh` turns the current theme's `colors.toml` into `extension/palette.css`:
  `accent = "#7aa2f7"` becomes `--omarchy-accent: #7aa2f7;`. It's also the Omarchy theme-set hook.
- `extension/sites/<site>.css` points the site's own colors at those variables. Where a site has
  color variables (YouTube, ChatGPT, GitHub), those are overridden; they change less often than
  class names. X and Grok are recolored through their class names, with comments on why.
- Everything is `!important`: extension CSS otherwise loses to the site's own.

## Setup

`install.sh omarchy` in the dotfiles repo runs `generate.sh`, links it as an Omarchy theme-set hook,
and `omarchy/brave-flags.conf` loads `extension/` into Brave. After an Omarchy theme switch, the new
colors show once Brave restarts.

## Testing

```sh
npm install
npm test               # every page in tests/pages.js, with the extension
THEME=off npm test     # the same pages without it, for before/after screenshots
```

The tests run headless Brave on a temporary copy of your Brave profile, so the sites are logged
in and in your chosen dark modes. They only open pages; they don't click or post anything. Per page:

- the page background is the theme's background,
- no large, neutral dark gray area is left (a surface the site CSS missed),
- a screenshot goes to `tests/screenshots/` (gitignored: it shows your feeds and chats). Look at
  these too; the checks can't tell whether something looks ugly.

## Adding a site

1. Add a `content_scripts` entry to `extension/manifest.json` and an empty `extension/sites/<site>.css`.
2. Add its pages to `tests/pages.js`.
3. Run the tests, find the site's dark-mode colors (its CSS variables, or the elements the gray
   check lists), map them to palette variables, and repeat until the checks and screenshots look right.
