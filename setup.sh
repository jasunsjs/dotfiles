#!/usr/bin/env bash
# Set up a Linux machine (dev container, Codespace, server) from this repo.
# Windows counterpart: install.ps1 (same steps, same order).
#
# Copies each config file to the place its program reads it. Anything already
# there is backed up to ~/.dotfiles-backup/<timestamp>/ first. Safe to re-run.
#
# Usage: ./setup.sh [--fonts]
#   --fonts  also install a Nerd Font (Linux desktops only; containers use your local fonts)
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
BIN_DIR="$HOME/.local/bin"
GIT_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/git"

INSTALL_FONTS=false
if [ "${1:-}" = "--fonts" ]; then
  INSTALL_FONTS=true
fi

# Copy a repo file to a target path, backing up whatever was there first.
install_dotfile() {
  local src="$DOTFILES_DIR/$1" target="$2"
  if [ -f "$target" ] && [ ! -L "$target" ] && cmp -s "$src" "$target"; then
    echo "up to date  $target"
    return
  fi
  if [ -e "$target" ] || [ -L "$target" ]; then
    local backup="$BACKUP_DIR/${target#"$HOME"/}"
    mkdir -p "$(dirname "$backup")"
    cp -P "$target" "$backup"
    rm -f "$target" # the old setup.sh left symlinks here; don't write through them
  fi
  mkdir -p "$(dirname "$target")"
  cp "$src" "$target"
  echo "installed   $target"
}

# Append a line to a file unless it's already there.
append_once() {
  touch "$2"
  grep -qxF "$1" "$2" || echo "$1" >>"$2"
}

# 1. Tools
mkdir -p "$BIN_DIR"
export PATH="$BIN_DIR:$PATH"

if ! command -v difft >/dev/null 2>&1; then
  case "$(uname -m)" in
  x86_64) arch=x86_64 ;;
  aarch64 | arm64) arch=aarch64 ;;
  *) arch="" ;;
  esac
  if [ -n "$arch" ]; then
    # Release assets carry the version in their name, so look up the latest tag first.
    version="$(curl -fsSLI -o /dev/null -w '%{url_effective}' https://github.com/Wilfred/difftastic/releases/latest)"
    version="${version##*/}"
    echo "installing difftastic $version"
    curl -fsSL "https://github.com/Wilfred/difftastic/releases/download/$version/difft-$version-$arch-unknown-linux-gnu.tar.gz" |
      tar -xz -C "$BIN_DIR"
  else
    echo "skipping    difftastic (no build for $(uname -m))"
  fi
fi

if ! command -v oh-my-posh >/dev/null 2>&1; then
  echo "installing oh-my-posh"
  curl -fsSL https://ohmyposh.dev/install.sh | bash -s -- -d "$BIN_DIR"
fi

if ! command -v act >/dev/null 2>&1; then
  echo "installing act"
  curl -fsSL https://raw.githubusercontent.com/nektos/act/master/install.sh | BINDIR="$BIN_DIR" bash
fi

# 2. Font
if [ "$INSTALL_FONTS" = true ]; then
  oh-my-posh font install meslo
fi

# 3. Git
install_dotfile git/config "$HOME/.gitconfig"
install_dotfile git/ignore "$GIT_CONFIG_DIR/ignore"

# 4. Shell
install_dotfile oh-my-posh/vityusha.omp.json "$HOME/.config/oh-my-posh/vityusha.omp.json"
if [ -f "$HOME/.bashrc" ]; then
  sed -i '/oh-my-posh --init --shell bash/d' "$HOME/.bashrc" # prompt line from the old setup.sh
fi
# shellcheck disable=SC2016 # these lines are meant to expand when .bashrc runs, not now
append_once 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.bashrc"
# shellcheck disable=SC2016
append_once 'eval "$(oh-my-posh init bash --config ~/.config/oh-my-posh/vityusha.omp.json)"' "$HOME/.bashrc"

# 5. Editor
for dir in "$HOME/.vscode-remote/data/Machine" "$HOME/.vscode-server/data/Machine"; do
  if [ -d "$dir" ]; then
    install_dotfile vscode/machine-settings.json "$dir/settings.json"
  fi
done

# 6. act
install_dotfile act/actrc "$HOME/.actrc"
if [ -S /var/run/docker.sock ] && sudo -n true 2>/dev/null; then
  echo "making /var/run/docker.sock usable without sudo"
  sudo chmod 666 /var/run/docker.sock
fi

# 7. Node tools
if command -v npm >/dev/null 2>&1 && ! command -v ncu >/dev/null 2>&1; then
  npm install --global npm-check-updates || echo "warning: couldn't install npm-check-updates" >&2
fi
