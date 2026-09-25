-- For the `onepiece` command in zsh/zshrc: in mpv windows it started (marked by
-- --script-opts=onepiece-track=yes), record each video's path and save its position
-- on quit. Windows opened any other way, e.g. from the file manager, are left alone.
local utils = require("mp.utils")

if mp.get_opt("onepiece-track") ~= "yes" then
  return
end

local state_dir = os.getenv("HOME") .. "/.local/state/onepiece"

mp.set_property_bool("save-position-on-quit", true)

mp.register_event("file-loaded", function()
  local path = utils.join_path(mp.get_property("working-directory"), mp.get_property("path"))
  mp.command_native({ name = "subprocess", args = { "mkdir", "-p", state_dir } })
  local file = io.open(state_dir .. "/last", "w")
  file:write(path)
  file:close()
end)
