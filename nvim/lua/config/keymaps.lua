-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set("n", "<leader>fy", function()
  vim.fn.setreg("+", vim.fn.expand("%"))
end, { desc = "Copy relative file path" })

vim.keymap.set("n", "<leader>fY", function()
  vim.fn.setreg("+", vim.fn.expand("%:p"))
end, { desc = "Copy full file path" })

vim.keymap.set("n", "<leader>fd", function()
  local dir = vim.fn.expand("%:p:h")
  vim.fn.setreg("+", vim.fs.relpath(LazyVim.root(), dir) or dir)
end, { desc = "Copy directory path relative to project root" })

vim.keymap.set("n", "<leader>fD", function()
  vim.fn.setreg("+", vim.fn.expand("%:p:h"))
end, { desc = "Copy full directory path" })
