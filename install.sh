#!/usr/bin/env bash
# Reproduces this Neovim + LazyVim setup on another Linux machine (x86_64 or arm64).
# Everything installs into your home directory; no sudo needed except for the
# one-time apt prerequisites the script tells you about.
#
#   cd nvim-setup && ./install.sh
#
# Options (environment variables):
#   SKIP_FONT=1   don't download the JetBrainsMono Nerd Font
#   SKIP_TOOLS=1  don't install language servers (do it later from inside nvim)
set -euo pipefail

KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN="$HOME/.local/bin"
OPT="$HOME/.local/opt"
STAMP="$(date +%Y%m%d-%H%M%S)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$BIN" "$OPT"
export PATH="$BIN:$PATH"

say()  { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m  ! %s\033[0m\n' "$*"; }

case "$(uname -m)" in
  x86_64)        NVIM_ARCH=x86_64; RUST_ARCH=x86_64; GO_ARCH=amd64; LG_ARCH=x86_64 ;;
  aarch64|arm64) NVIM_ARCH=arm64;  RUST_ARCH=aarch64; GO_ARCH=arm64; LG_ARCH=arm64 ;;
  *) echo "Unsupported CPU: $(uname -m)"; exit 1 ;;
esac
[ "$(uname -s)" = Linux ] || { echo "This script is for Linux. See SETUP.md for macOS."; exit 1; }

# ---------------------------------------------------------------- prerequisites
say "Checking prerequisites"
missing=()
for c in git curl tar unzip gcc make python3 tmux; do command -v "$c" >/dev/null || missing+=("$c"); done
python3 -c 'import ensurepip' 2>/dev/null || missing+=("python3-venv")
if [ ${#missing[@]} -gt 0 ]; then
  pkgs="$(printf '%s\n' "${missing[@]}" | sed 's/^gcc$/build-essential/; s/^make$/build-essential/' | sort -u | tr '\n' ' ')"
  echo "Missing: ${missing[*]}"
  echo "Install them first, then re-run this script:"
  echo "  sudo apt update && sudo apt install -y $pkgs"
  exit 1
fi
echo "ok"

# Download the newest GitHub release asset whose name matches a regex.
gh_asset() { # repo regex outfile
  local url
  url="$(curl -fsSL "https://api.github.com/repos/$1/releases/latest" \
    | grep -o '"browser_download_url": *"[^"]*"' | cut -d'"' -f4 | grep -iE "$2" | head -1)"
  [ -n "$url" ] || { echo "No release asset matching '$2' in $1"; return 1; }
  curl -fsSL "$url" -o "$3"
}

# Extract a tarball and copy the named binary into ~/.local/bin.
install_bin() { # tarball binary-name
  local d="$TMP/x-$2"; mkdir -p "$d"; tar -xzf "$1" -C "$d"
  install -m 755 "$(find "$d" -type f -name "$2" -perm -u+x | head -1)" "$BIN/$2"
}

# ---------------------------------------------------------------- neovim
say "Installing Neovim (latest stable)"
curl -fsSL "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-$NVIM_ARCH.tar.gz" -o "$TMP/nvim.tgz"
rm -rf "$OPT/nvim-linux-$NVIM_ARCH"
tar -xzf "$TMP/nvim.tgz" -C "$OPT"
ln -sf "$OPT/nvim-linux-$NVIM_ARCH/bin/nvim" "$BIN/nvim"
nvim --version | head -1

# ---------------------------------------------------------------- CLI tools
say "Installing ripgrep, fd, fzf, lazygit"
gh_asset BurntSushi/ripgrep "ripgrep-.*-$RUST_ARCH-unknown-linux-(musl|gnu)\.tar\.gz$" "$TMP/rg.tgz"
install_bin "$TMP/rg.tgz" rg
gh_asset sharkdp/fd         "fd-v.*-$RUST_ARCH-unknown-linux-(musl|gnu)\.tar\.gz$"      "$TMP/fd.tgz"
install_bin "$TMP/fd.tgz" fd
gh_asset junegunn/fzf       "fzf-.*-linux_$GO_ARCH\.tar\.gz$"                            "$TMP/fzf.tgz"
install_bin "$TMP/fzf.tgz" fzf
gh_asset jesseduffield/lazygit "lazygit_.*_linux_$LG_ARCH\.tar\.gz$"                     "$TMP/lg.tgz"
install_bin "$TMP/lg.tgz" lazygit
for c in rg fd fzf lazygit; do printf '  %-8s %s\n' "$c" "$("$c" --version 2>/dev/null | head -1)"; done

# ---------------------------------------------------------------- node (via nvm)
say "Installing Node.js LTS via nvm (needed by the JS/TS, HTML/CSS and Pyright language servers)"
export NVM_DIR="$HOME/.nvm"
if [ ! -s "$NVM_DIR/nvm.sh" ]; then
  # PROFILE=/dev/null: we add the nvm lines to ~/.bashrc ourselves below
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | PROFILE=/dev/null bash
fi
set +u; . "$NVM_DIR/nvm.sh"; nvm install --lts >/dev/null; nvm alias default 'lts/*' >/dev/null; set -u
echo "node $(node -v)"
say "Installing tree-sitter CLI (compiles syntax-highlighting parsers)"
npm install -g tree-sitter-cli >/dev/null
tree-sitter --version

# ---------------------------------------------------------------- shell PATH
say "Updating ~/.bashrc"
touch "$HOME/.bashrc"
if ! grep -q 'NVM_DIR="$HOME/.nvm"' "$HOME/.bashrc"; then
  cat >> "$HOME/.bashrc" <<'EOF'

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
EOF
  echo "added nvm"
fi
if ! grep -q '.local/bin' "$HOME/.bashrc"; then
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"; echo "added ~/.local/bin to PATH"
fi

# ---------------------------------------------------------------- font
if [ "${SKIP_FONT:-0}" != 1 ]; then
  say "Installing JetBrainsMono Nerd Font (for file icons)"
  if fc-list 2>/dev/null | grep -qi 'JetBrainsMono Nerd Font'; then
    echo "already installed"
  else
    curl -fsSL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz -o "$TMP/font.tar.xz"
    mkdir -p "$HOME/.local/share/fonts/JetBrainsMonoNF"
    tar -xJf "$TMP/font.tar.xz" -C "$HOME/.local/share/fonts/JetBrainsMonoNF"
    command -v fc-cache >/dev/null && fc-cache -f >/dev/null
    echo "installed. Set your terminal's font to 'JetBrainsMono Nerd Font'."
  fi
fi

# ---------------------------------------------------------------- config
say "Copying config (existing files are backed up, not deleted)"
for d in "$HOME/.config/nvim" "$HOME/.local/share/nvim" "$HOME/.local/state/nvim" "$HOME/.cache/nvim"; do
  if [ -e "$d" ]; then mv "$d" "$d.bak-$STAMP"; echo "backed up $d -> $d.bak-$STAMP"; fi
done
mkdir -p "$HOME/.config"
cp -r "$KIT/config/nvim" "$HOME/.config/nvim"
if [ -e "$HOME/.tmux.conf" ] && ! cmp -s "$HOME/.tmux.conf" "$KIT/config/tmux/tmux.conf"; then
  mv "$HOME/.tmux.conf" "$HOME/.tmux.conf.bak-$STAMP"; echo "backed up ~/.tmux.conf"
fi
cp "$KIT/config/tmux/tmux.conf" "$HOME/.tmux.conf"
# markdownlint: disable the 80-column line-length warning (MD013) in markdown files
if [ -e "$HOME/.markdownlint-cli2.jsonc" ] && ! cmp -s "$HOME/.markdownlint-cli2.jsonc" "$KIT/config/markdownlint/markdownlint-cli2.jsonc"; then
  mv "$HOME/.markdownlint-cli2.jsonc" "$HOME/.markdownlint-cli2.jsonc.bak-$STAMP"; echo "backed up ~/.markdownlint-cli2.jsonc"
fi
cp "$KIT/config/markdownlint/markdownlint-cli2.jsonc" "$HOME/.markdownlint-cli2.jsonc"
echo "config in place"

# ---------------------------------------------------------------- plugins + tools
say "Installing plugins at the exact versions from lazy-lock.json"
nvim --headless "+Lazy! restore" +qa >/dev/null 2>&1
echo "done"

if [ "${SKIP_TOOLS:-0}" != 1 ]; then
  say "Installing language servers, formatters and debuggers (takes a few minutes)"
  nvim --headless -c "luafile $KIT/mason-install.lua" 2>&1 | tr '\r' '\n' | grep -E '^(installing|all language|FAILED|timed out)' || true
fi

say "Done"
cat <<EOF
Next:
  1. Open a new terminal (or run: source ~/.bashrc)
  2. Set your terminal font to "JetBrainsMono Nerd Font"
  3. cd into a project and run: nvim .
  Inside nvim, :checkhealth reports anything still missing.
EOF
