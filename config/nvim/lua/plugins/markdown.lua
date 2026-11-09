-- No diagnostics (linter warnings/errors, LSP squiggles) in markdown buffers.
return {
  {
    "mfussenegger/nvim-lint",
    opts = function(_, opts)
      opts.linters_by_ft = opts.linters_by_ft or {}
      opts.linters_by_ft.markdown = {}
      opts.linters_by_ft["markdown.mdx"] = {}
    end,
  },
  {
    "LazyVim/LazyVim",
    init = function()
      vim.api.nvim_create_autocmd({ "FileType", "LspAttach", "BufEnter" }, {
        group = vim.api.nvim_create_augroup("markdown_no_diagnostics", { clear = true }),
        callback = function(ev)
          if vim.bo[ev.buf].filetype:match("^markdown") then
            vim.diagnostic.enable(false, { bufnr = ev.buf })
          end
        end,
      })
    end,
  },
}
