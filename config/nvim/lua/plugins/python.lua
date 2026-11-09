-- Point pyright at the project's ./.venv (or ./venv) automatically, so imports
-- from your project's dependencies resolve without activating the venv first.
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        pyright = {
          before_init = function(_, config)
            local root = config.root_dir or vim.fn.getcwd()
            for _, name in ipairs({ ".venv", "venv" }) do
              local py = root .. "/" .. name .. "/bin/python"
              if vim.uv.fs_stat(py) then
                config.settings = config.settings or {}
                config.settings.python = vim.tbl_deep_extend("force", config.settings.python or {}, { pythonPath = py })
                return
              end
            end
          end,
        },
      },
    },
  },
}
