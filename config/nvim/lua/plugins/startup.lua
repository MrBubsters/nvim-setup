-- VS Code-style startup ("code ." behaviour):
--   nvim            -> file tree on the left for the current directory, empty editor on the right
--   nvim <dir>      -> cd into <dir>, then the same layout (the tree itself comes from snacks' replace_netrw)
--   nvim <file>     -> just open the file, no tree (same as `code file`)
-- The start-screen dashboard is disabled.
return {
  {
    "folke/snacks.nvim",
    init = function()
      -- `nvim some/dir`: make that directory the working dir so file search, git, etc. are scoped to it.
      local arg = vim.fn.argv(0)
      if vim.fn.argc() == 1 and vim.fn.isdirectory(arg) == 1 then
        vim.cmd.cd(vim.fn.fnameescape(arg))
      end

      vim.api.nvim_create_autocmd("VimEnter", {
        once = true,
        callback = function()
          -- Plain `nvim` with no files (and no piped stdin): show the tree.
          if vim.fn.argc() == 0 and vim.api.nvim_buf_get_name(0) == "" and vim.bo.buftype == "" then
            vim.schedule(function()
              Snacks.explorer()
            end)
          end
        end,
      })
    end,
    opts = {
      dashboard = { enabled = false },
      picker = {
        sources = {
          -- file tree: 32 columns (80% of the default 40)
          -- also show dotfiles (.env, ...) and git-ignored files; H / I in the tree still toggle them
          explorer = { hidden = true, ignored = true, layout = { layout = { width = 32, min_width = 32 } } },
        },
      },
    },
  },
}
