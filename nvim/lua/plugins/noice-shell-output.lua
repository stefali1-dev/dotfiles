-- Workaround: noice has no route for Neovim 0.12's shell_* message kinds, so :!cmd output is dropped.
-- Remove once noice.nvim routes shell_out/shell_err/shell_ret.
return {
  "folke/noice.nvim",
  opts = function(_, opts)
    table.insert(opts.routes, 1, {
      filter = { event = "msg_show", kind = { "shell_out", "shell_err", "shell_ret" } },
      view = "notify",
      opts = { title = "Shell" },
    })
  end,
}
