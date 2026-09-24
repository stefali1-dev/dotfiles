-- For the `onepiece` command in zsh/zshrc: when a One Piece video plays, however
-- it was opened, record its path and save its position on quit. Other videos are
-- left alone. Matches "one piece" anywhere in the path, so the folder name counts.
local utils = require("mp.utils")

local state_dir = os.getenv("HOME") .. "/.local/state/onepiece"

mp.register_event("file-loaded", function()
  local path = utils.join_path(mp.get_property("working-directory"), mp.get_property("path"))
  local words = path:lower():gsub("[%p%s]+", " ")
  if not words:find("one ?piece") then
    return
  end

  mp.set_property_bool("file-local-options/save-position-on-quit", true)
  mp.command_native({ name = "subprocess", args = { "mkdir", "-p", state_dir } })
  local file = io.open(state_dir .. "/last", "w")
  file:write(path)
  file:close()
end)
