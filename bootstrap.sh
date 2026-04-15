#!/usr/bin/env bash
set -euo pipefail

echo "==> Starting macOS bootstrap..."

# -------------------------------------------------------------------
# Helper
# -------------------------------------------------------------------
log() {
  printf "\n==> %s\n" "$1"
}

# -------------------------------------------------------------------
# 1) Install Xcode Command Line Tools if missing
# -------------------------------------------------------------------
if ! xcode-select -p >/dev/null 2>&1; then
  log "Installing Xcode Command Line Tools"
  xcode-select --install || true

  echo "Waiting for Command Line Tools installation to finish..."
  until xcode-select -p >/dev/null 2>&1; do
    sleep 5
  done
else
  log "Xcode Command Line Tools already installed"
fi

# -------------------------------------------------------------------
# 2) Install Homebrew if missing
# -------------------------------------------------------------------
if ! command -v brew >/dev/null 2>&1; then
  log "Installing Homebrew"
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  log "Homebrew already installed"
fi

# -------------------------------------------------------------------
# 3) Load Homebrew into current shell
# -------------------------------------------------------------------
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
else
  echo "Homebrew was not found after install."
  exit 1
fi

# -------------------------------------------------------------------
# 4) Update Homebrew
# -------------------------------------------------------------------
log "Updating Homebrew"
brew update

# -------------------------------------------------------------------
# 5) Install apps from Brewfile
# -------------------------------------------------------------------
log "Installing apps from Brewfile"

brew install powershell

BREWFILE_URL="https://raw.githubusercontent.com/PetarSyarov/macos-workstation-setup/main/Brewfile"
TMP_BREWFILE="/tmp/Brewfile.$$"

curl -fsSL "$BREWFILE_URL" -o "$TMP_BREWFILE" || {
  echo "Failed to download Brewfile"
  exit 1
}

brew bundle --file="$TMP_BREWFILE"

# -------------------------------------------------------------------
# 6) Install Hammerspoon config (init.lua)
# -------------------------------------------------------------------
log "Setting up Hammerspoon config"

HAMMERSPOON_DIR="$HOME/.hammerspoon"
INIT_URL="https://raw.githubusercontent.com/PetarSyarov/macos-workstation-setup/main/init.lua"

mkdir -p "$HAMMERSPOON_DIR"

curl -fsSL "$INIT_URL" -o "$HAMMERSPOON_DIR/init.lua" || {
  echo "Failed to download init.lua"
  exit 1
}

echo "Hammerspoon config installed to $HAMMERSPOON_DIR/init.lua"

# -------------------------------------------------------------------
# 7) Launch apps once so macOS registers them
# -------------------------------------------------------------------
log "Launching apps once"
open -a Hammerspoon || true
open -a BetterDisplay || true
open -a "Scroll Reverser" || true

sleep 3
osascript -e 'tell application "Hammerspoon" to reload config' || true

echo
echo "Done."
echo "You may still need to approve permissions in System Settings:"
echo "- Hammerspoon may need Accessibility permission"
echo "- Scroll Reverser may need Accessibility permission"
echo "- BetterDisplay may ask for extra permissions depending on features used"