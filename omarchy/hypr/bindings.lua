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
