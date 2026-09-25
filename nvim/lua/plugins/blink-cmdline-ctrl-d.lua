-- HACK: blink's cmdline menu ignores <C-d> and stays drawn over the <C-d> match list.
-- Remove once blink.cmp hides its menu on <C-d>.
return {
  "saghen/blink.cmp",
  opts = {
    cmdline = {
      keymap = {
        ["<C-d>"] = { function(cmp) cmp.hide() end, "fallback" },
      },
    },
  },
}
