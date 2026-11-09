-- Installs every language server / formatter / linter / debugger the setup uses, then quits.
-- Run with: nvim --headless -c "luafile mason-install.lua"
local packages = {
  "bash-language-server", "clangd", "codelldb", "css-lsp", "debugpy", "docker-compose-language-service",
  "dockerfile-language-server", "eslint-lsp", "hadolint", "html-lsp", "js-debug-adapter", "json-lsp",
  "lua-language-server", "markdownlint-cli2", "markdown-toc", "marksman", "prettier", "pyright", "ruff",
  "shellcheck", "shfmt", "sqlfluff", "stylua", "tailwindcss-language-server", "taplo", "vtsls",
  "yaml-language-server",
}
require("lazy").load({ plugins = { "mason.nvim" } })
local registry = require("mason-registry")
local failed = {}
registry.refresh(function()
  local pending = #packages
  for _, name in ipairs(packages) do
    local pkg = registry.get_package(name)
    if pkg:is_installed() then
      pending = pending - 1
    else
      io.write("installing " .. name .. "\n")
      pkg:install():once("closed", function()
        if not pkg:is_installed() then table.insert(failed, name) end
        pending = pending - 1
      end)
    end
  end
  local function wait()
    if pending > 0 then return vim.defer_fn(wait, 1000) end
    -- give treesitter parsers (installed by LazyVim at startup) time to finish too
    vim.defer_fn(function()
      io.write(#failed == 0 and "all language tools installed\n" or ("FAILED: " .. table.concat(failed, ", ") .. "\n"))
      vim.cmd(#failed == 0 and "qa!" or "cq!")
    end, 20000)
  end
  wait()
end)
vim.defer_fn(function() io.write("timed out\n"); vim.cmd("cq!") end, 900000)
