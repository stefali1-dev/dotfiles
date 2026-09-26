-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Add a new binding.
-- o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh your-server")

-- Change an existing binding by unbinding it first, then binding the key again.
-- This example changes SUPER+SPACE from the launcher to the Omarchy root menu.
-- hl.unbind("SUPER + SPACE")
-- o.bind("SUPER + SPACE", "Omarchy menu", "omarchy-menu toggle root")

-- Disable a default binding without replacing it.
-- hl.unbind("SUPER + SHIFT + B")

-- Logitech MX Keys examples:
-- o.bind("SUPER + SHIFT + S", nil, "omarchy-capture-screenshot")
-- o.bind("SUPER + H", nil, "voxtype record toggle")
-- o.bind("SUPER + PERIOD", nil, "omarchy-shell shell toggle omarchy.emojis")

-- Mac-style Cmd shortcuts: SUPER + letter sends the matching CTRL shortcut to
-- the focused app, like Omarchy's universal copy/paste. In terminals, where
-- CTRL + letter means something else (Ctrl+S freezes output, Ctrl+Z suspends),
-- the shortcuts do the terminal-appropriate thing or nothing.
local function send_shortcut_once(mods, key)
  return function()
    hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "down" }))

    hl.timer(function()
      hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "up" }))
    end, { timeout = 50, type = "oneshot" })
  end
end

local function active_window_is_terminal()
  local window = hl.get_active_window()
  if not window then
    return false
  end

  for _, tag in ipairs(window.tags or {}) do
    if tag:gsub("%*$", "") == "terminal" then
      return true
    end
  end

  return false
end

local function close_window()
  hl.dispatch(hl.dsp.window.close())
end

local function new_terminal()
  hl.exec_cmd("omarchy-launch-terminal")
end

-- terminal_action: a function to run instead in terminals, or nil to do nothing.
local function mac_shortcut(mods, key, terminal_action)
  return function()
    if active_window_is_terminal() then
      if terminal_action then
        terminal_action()
      end
    else
      send_shortcut_once(mods, key)()
    end
  end
end

-- Move the Omarchy window actions these keys used to have.
hl.unbind("SUPER + W") -- was: Close window (now SUPER + Q)
hl.unbind("SUPER + F") -- was: Full screen (now SUPER + CTRL + F, as on macOS)
hl.unbind("SUPER + T") -- was: Toggle floating (now SUPER + ALT + T)
hl.unbind("SUPER + S") -- was: Toggle scratchpad (now SUPER + ALT + S)
hl.unbind("SUPER + CTRL + F") -- was: Tiled full screen (now SUPER + CTRL + SHIFT + F)
hl.unbind("SUPER + ALT + S") -- was: Move window to scratchpad (now SUPER + SHIFT + ALT + S)

o.bind("SUPER + Q", "Close window", hl.dsp.window.close())
o.bind("SUPER + CTRL + F", "Full screen", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
o.bind("SUPER + CTRL + SHIFT + F", "Tiled full screen", "omarchy-hyprland-window-tiled-fullscreen-toggle")
o.bind("SUPER + ALT + T", "Toggle window floating/tiling", hl.dsp.window.float({ action = "toggle" }))
o.bind("SUPER + ALT + S", "Toggle scratchpad", hl.dsp.workspace.toggle_special("scratchpad"))
o.bind("SUPER + SHIFT + ALT + S", "Move window to scratchpad", hl.dsp.window.move({ workspace = "special:scratchpad", follow = false }))
o.bind("SUPER + B", "Browser", { omarchy = "browser" })

-- Yazi replaces Nautilus as the file manager.
hl.unbind("SUPER + SHIFT + F") -- was: Nautilus
hl.unbind("SUPER + ALT + SHIFT + F") -- was: Nautilus in the terminal's cwd
o.bind("SUPER + SHIFT + F", "File manager", { tui = "yazi" })
o.bind("SUPER + ALT + SHIFT + F", "File manager (cwd)", 'omarchy-launch-tui yazi "$(omarchy-cmd-terminal-cwd)"')

o.bind("SUPER + W", "Close tab", mac_shortcut("CTRL", "W", close_window))
o.bind("SUPER + T", "New tab", mac_shortcut("CTRL", "T", new_terminal))
o.bind("SUPER + SHIFT + T", "Reopen closed tab", mac_shortcut("CTRL SHIFT", "T"))
o.bind("SUPER + N", "New", mac_shortcut("CTRL", "N", new_terminal))
o.bind("SUPER + S", "Save", mac_shortcut("CTRL", "S"))
o.bind("SUPER + A", "Select all", mac_shortcut("CTRL", "A"))
o.bind("SUPER + Z", "Undo", mac_shortcut("CTRL", "Z"))
o.bind("SUPER + SHIFT + Z", "Redo", mac_shortcut("CTRL SHIFT", "Z"))
o.bind("SUPER + R", "Reload", mac_shortcut("CTRL", "R"))
o.bind("SUPER + F", "Find", mac_shortcut("CTRL", "F", send_shortcut_once("CTRL SHIFT", "R")))

-- Mac-style word editing: ALT + arrows jump words, ALT + Backspace/Delete delete
-- them, and SHIFT selects. Apps do this with CTRL, so they get the CTRL version;
-- terminals already handle ALT (zsh, Claude Code), so they get the ALT key back.
-- Replaces ALT + Left/Right as browser Back/Forward.
local function word_shortcut(mods, key)
  return mac_shortcut("CTRL" .. mods, key, send_shortcut_once("ALT" .. mods, key))
end

o.bind("ALT + Left", "Previous word", word_shortcut("", "Left"), { repeating = true })
o.bind("ALT + Right", "Next word", word_shortcut("", "Right"), { repeating = true })
o.bind("ALT + SHIFT + Left", "Select previous word", word_shortcut(" SHIFT", "Left"), { repeating = true })
o.bind("ALT + SHIFT + Right", "Select next word", word_shortcut(" SHIFT", "Right"), { repeating = true })
o.bind("ALT + BackSpace", "Delete previous word", word_shortcut("", "BackSpace"), { repeating = true })
o.bind("ALT + Delete", "Delete next word", word_shortcut("", "Delete"), { repeating = true })

-- Window moves go on SUPER + CTRL + number, as on macOS, which frees
-- SUPER + SHIFT + number for screenshots. SUPER + CTRL + number opened bar
-- panels; the panels keep their letter shortcuts (SUPER + CTRL + A, B, W, ...).
for workspace = 1, 10 do
  local key = "code:" .. tostring(workspace + 9)
  hl.unbind("SUPER + SHIFT + " .. key)
  hl.unbind("SUPER + SHIFT + ALT + " .. key)
  hl.unbind("SUPER + CTRL + " .. key)
  o.bind("SUPER + CTRL + " .. key, "Move window to workspace " .. workspace, hl.dsp.window.move({ workspace = tostring(workspace) }))
  o.bind("SUPER + CTRL + ALT + " .. key, "Move window silently to workspace " .. workspace, hl.dsp.window.move({ workspace = tostring(workspace), follow = false }))
end

hl.unbind("PRINT")
o.bind("PRINT", "Screenshot", "omasnap")
o.bind("SUPER + SHIFT + code:10", "Extract text (OCR) from screenshot", "omarchy-capture-text")
o.bind("SUPER + SHIFT + code:11", "Screenshot", "omasnap")
o.bind("SUPER + SHIFT + code:12", "Scrolling screenshot", "omasnap --scroll")
