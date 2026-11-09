# Neovim setup: how to recreate it on another machine

This folder holds everything needed to reproduce the Neovim + LazyVim setup from the desktop
(Ubuntu 24.04, Neovim 0.12, set up 2026-11-07) on a laptop or any other Linux machine.

| File | What it is |
|---|---|
| `install.sh` | Installs everything and copies the config into place |
| `config/nvim/` | Snapshot of `~/.config/nvim`, including `lazy-lock.json` (exact plugin versions) |
| `config/tmux/tmux.conf` | Snapshot of `~/.tmux.conf` |
| `mason-install.lua` | List of language servers/formatters, installed by `install.sh` |
| `nvim-playbook.html` | Shortcut guide for day-to-day use. Open it in a browser. |

---

## Quick start (Linux)

1. **Copy this folder to the laptop**, for example with a USB stick, or over the network:
   ```bash
   scp -r ~/Documents/nvim-setup  you@laptop:~/
   ```

2. **Install the system prerequisites** (the only step that needs sudo):
   ```bash
   sudo apt update && sudo apt install -y git curl tar unzip build-essential python3-venv tmux xz-utils
   ```

3. **Run the installer:**
   ```bash
   cd ~/nvim-setup && ./install.sh
   ```
   It takes about 5 minutes, most of it downloading language tools. If any prerequisite is
   missing, it stops and prints the `apt` command to fix it.

4. **Open a new terminal** so the PATH changes take effect.

5. **Set your terminal's font to "JetBrainsMono Nerd Font".** Without it, the file tree and
   status bar show boxes instead of icons. In GNOME Terminal: Preferences → your profile →
   Custom font.

6. **Try it:** `cd some-project && nvim .`

Re-running `install.sh` is safe. It backs up any existing nvim config, data and `~/.tmux.conf`
with a `.bak-<date>` suffix instead of deleting them.

Options: `SKIP_FONT=1 ./install.sh` skips the font download (about 100 MB).
`SKIP_TOOLS=1 ./install.sh` skips the language tools; install them later with `:Mason` inside nvim.

---

## What gets installed

Everything goes in your home folder. Nothing is installed system-wide.

| Tool | Where | Why |
|---|---|---|
| Neovim (latest stable) | `~/.local/opt/nvim-linux-*/`, linked into `~/.local/bin/nvim` | The editor. LazyVim needs 0.11 or newer. |
| ripgrep (`rg`) | `~/.local/bin` | Project-wide text search (`Space /`) |
| fd | `~/.local/bin` | Fast file finding (`Space Space`) |
| fzf | `~/.local/bin` | Fuzzy matching |
| lazygit | `~/.local/bin` | Git interface (`Space g g`) |
| Node.js LTS via nvm | `~/.nvm` | Runs the JS/TS, HTML/CSS, Pyright and other language servers |
| tree-sitter CLI | npm global | Builds the syntax-highlighting parsers |
| JetBrainsMono Nerd Font | `~/.local/share/fonts` | Icons in the file tree and status bar |
| Language tools (27) | `~/.local/share/nvim/mason` | Language servers, formatters, linters and debuggers, listed below |

Language tools by language:

- **Python:** pyright, ruff, debugpy
- **JavaScript/TypeScript:** vtsls, eslint-lsp, prettier, js-debug-adapter
- **Web:** html-lsp, css-lsp, tailwindcss-language-server
- **C/C++:** clangd, codelldb
- **Shell:** bash-language-server, shellcheck, shfmt
- **SQL:** sqlfluff
- **Lua:** lua-language-server, stylua
- **Data and docs:** json-lsp, yaml-language-server, taplo, marksman, markdownlint-cli2, markdown-toc
- **Docker:** dockerfile-language-server, docker-compose-language-service, hadolint

`~/.bashrc` gets two additions if they aren't there already: loading nvm, and adding `~/.local/bin` to PATH.

---

## What's customized in the config

The config is the standard [LazyVim starter](https://github.com/LazyVim/starter) plus the following changes.

**`lazyvim.json`: language packs ("extras") that are turned on.** Change these with `:LazyExtras`
inside nvim.
- Languages: Python, TypeScript/JavaScript, Tailwind, JSON, YAML, TOML, Markdown, Docker, SQL,
  C/C++ (clangd), git files
- Tools: Prettier formatting, ESLint, debugger (DAP), test runner (neotest), dotfile/shell support

**`lua/plugins/startup.lua`: opens like `code .`**
- `nvim` or `nvim <folder>` switches into the folder and shows the file tree on the left
  with an empty editor on the right.
- `nvim <file>` just opens the file.
- The start-screen dashboard is turned off. Delete this file to get it back.

**`lua/config/keymaps.lua`: word jumps.** `Ctrl`/`Alt` + `←`/`→` jump between space-separated
words in every mode, like in a shell. LazyVim's Ctrl+arrow window resizing (all four arrows) is removed; resize
splits with the mouse instead. On a Mac, set the terminal to send Option as Meta/Esc+ so Option+arrow works.

The file tree is also narrowed to 32 columns (80% of the default) in `startup.lua`.
The tree also shows dotfiles (`.env`, `.gitignore`, ...) and git-ignored files by default (`hidden = true, ignored = true`);
press `H` / `I` inside the tree to toggle them off.

**`lua/plugins/python.lua`: uses the project's virtualenv.** Python code intelligence uses
`./.venv` or `./venv` automatically, so imports from installed packages resolve without
activating the venv first. Start nvim from the project root for this to work.

**`lua/plugins/web.lua`: HTML and CSS support,** plus extra syntax parsers for SCSS and JSDoc.

**`lazy-lock.json`: exact plugin versions.** The installer runs `:Lazy restore`, so the laptop
gets exactly the same plugin versions as the desktop. Use `:Lazy update` to move to newer ones.

**`~/.tmux.conf`: settings that make nvim work well inside tmux:** no `Esc` delay, true color,
reloading files changed outside nvim, mouse support, and window/pane numbering from 1.

**`lua/plugins/markdown.lua`: no diagnostics in markdown.** Turns off the markdownlint linter and hides
all diagnostics (linter and LSP warnings/errors) in markdown buffers. Delete this file to get them back.
`~/.markdownlint-cli2.jsonc` (also copied by the installer) only matters if you re-enable linting.

---

## Manual setup (if you'd rather not run the script)

```bash
# 1. Neovim
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
mkdir -p ~/.local/opt ~/.local/bin
tar -xzf nvim-linux-x86_64.tar.gz -C ~/.local/opt
ln -sf ~/.local/opt/nvim-linux-x86_64/bin/nvim ~/.local/bin/nvim

# 2. CLI tools: download the linux release from each GitHub releases page and put the
#    binary in ~/.local/bin: BurntSushi/ripgrep, sharkdp/fd, junegunn/fzf, jesseduffield/lazygit

# 3. Node + tree-sitter
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
# open a new terminal, then:
nvm install --lts
npm install -g tree-sitter-cli

# 4. Config
cp -r config/nvim ~/.config/nvim
cp config/tmux/tmux.conf ~/.tmux.conf
cp config/markdownlint/markdownlint-cli2.jsonc ~/.markdownlint-cli2.jsonc

# 5. Plugins and language tools
nvim --headless "+Lazy! restore" +qa
nvim --headless -c "luafile mason-install.lua"
```

---

## macOS

`install.sh` is Linux-only. On a Mac, use Homebrew instead, then copy the config:

```bash
brew install neovim ripgrep fd fzf lazygit node tree-sitter-cli tmux
brew install --cask font-jetbrains-mono-nerd-font
cp -r config/nvim ~/.config/nvim && cp config/tmux/tmux.conf ~/.tmux.conf && cp config/markdownlint/markdownlint-cli2.jsonc ~/.markdownlint-cli2.jsonc
nvim --headless "+Lazy! restore" +qa
nvim --headless -c "luafile mason-install.lua"
```

---

## Keeping both machines in sync

The kit is a snapshot of the desktop's config. If you change the config on either machine,
copy `~/.config/nvim` across again, or put it in a git repo and clone it on both.
`~/.config/nvim` is already a git repository, but it has no commits or remote yet.

---

## Troubleshooting

| Problem | Fix |
|---|---|
| Boxes or question marks instead of icons | Set the terminal font to *JetBrainsMono Nerd Font* |
| `nvim: command not found` | Open a new terminal, or `source ~/.bashrc` |
| A language has no completion or errors | Run `:Mason` to check its tool is installed, and press `Space c l` while in the file to see which language servers are running |
| Python imports show as unresolved | Start nvim from the project root, and make sure `.venv/` exists there |
| `Esc` feels laggy in tmux | Reload the tmux config: `tmux source ~/.tmux.conf` |
| Anything else | `:checkhealth` lists what's missing and how to fix it |
