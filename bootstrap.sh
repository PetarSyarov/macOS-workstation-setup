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
#  Install Homebrew if missing
# -------------------------------------------------------------------
if ! command -v brew >/dev/null 2>&1; then
  log "Installing Homebrew"
  NONINTERACTIVE=1 /bin/bash -c \
    "$(sudo curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  log "Homebrew already installed"
fi

# -------------------------------------------------------------------
#  Load Homebrew into current shell
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
#  Update Homebrew
# -------------------------------------------------------------------
log "Updating Homebrew"
brew update

# -------------------------------------------------------------------
#  Install apps from Brewfile
# -------------------------------------------------------------------
log "Installing apps from Brewfile"

BREWFILE_URL="https://raw.githubusercontent.com/PetarSyarov/macos-workstation-setup/main/Brewfile"
TMP_BREWFILE="/tmp/Brewfile.$$"

curl -fsSL "$BREWFILE_URL" -o "$TMP_BREWFILE" || {
  echo "Failed to download Brewfile"
  exit 1
}

brew bundle --file="$TMP_BREWFILE"

# -------------------------------------------------------------------
#  Install Hammerspoon config (init.lua)
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
#  Launch apps once so macOS registers them
# -------------------------------------------------------------------
log "Launching apps once"
open -a Hammerspoon || true
open -a BetterDisplay || true
open -a "Scroll Reverser" || true
open -a KeePassXC || true

echo
echo "Done."
echo "You will need to reload Hammerspoon config manually"
echo "- Hammerspoon will need Accessibility permission"
echo "- Scroll Reverser will need Accessibility permission"
echo "- BetterDisplay will ask for extra permissions depending on features used"