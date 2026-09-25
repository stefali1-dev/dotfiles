-- Options are automatically loaded before lazy.nvim startup.
require("config.remote_clipboard").setup()

vim.opt.relativenumber = false
vim.g.autoformat = false

-- Workaround: snacks statuscolumn hides the tutor's ✗/✓ signs (a text-less line_hl extmark wins the priority tie).
-- Remove once snacks.nvim skips extmarks without sign_text.
vim.api.nvim_create_autocmd("FileType", {
  pattern = "tutor",
  callback = function()
    vim.opt_local.statuscolumn = ""
  end,
})
