-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

local omarchy_gdk_scale = 1
local omarchy_monitor_scale = 1.25

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = omarchy_monitor_scale })

-- Configure a specific monitor.
-- hl.monitor({ output = "DP-2", mode = "2560x1440@144", position = "0x0", scale = 1 })

-- Portrait/rotated secondary monitor (transform: 1 = 90°, 3 = 270°).
-- hl.monitor({ output = "DP-2", mode = "preferred", position = "auto", scale = 1, transform = 1 })

-- With an external monitor, workspace 1 stays on the laptop screen and 2-5 go
-- to the external one. Clamshell and unplugging need nothing here: Hyprland
-- moves workspaces off a monitor that goes away.
local function is_laptop(monitor)
  return monitor.name:match("^eDP") ~= nil
end

local function place_workspaces()
  local laptop, external
  for _, monitor in ipairs(hl.get_monitors()) do
    if is_laptop(monitor) then
      laptop = monitor.name
    else
      external = monitor.name
    end
  end
  if not (laptop and external) then
    return
  end

  hl.workspace_rule({ workspace = "1", monitor = laptop })
  for id = 2, 5 do
    hl.workspace_rule({ workspace = tostring(id), monitor = external })
  end

  local existing = {}
  for _, workspace in ipairs(hl.get_workspaces()) do
    existing[workspace.id] = true
  end
  if existing[1] then
    hl.dispatch(hl.dsp.workspace.move({ workspace = "1", monitor = laptop }))
  end
  for id = 5, 2, -1 do
    if existing[id] then
      hl.dispatch(hl.dsp.workspace.move({ workspace = tostring(id), monitor = external }))
    end
  end
end

hl.on("monitor.added", place_workspaces)
