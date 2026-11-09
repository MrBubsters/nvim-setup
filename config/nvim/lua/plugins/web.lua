-- HTML / CSS language servers and extra syntax parsers not covered by LazyVim extras.
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        html = {},
        cssls = {},
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "html", "css", "scss", "javascript", "jsdoc", "tsx", "typescript" } },
  },
}
