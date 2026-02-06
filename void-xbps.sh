#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$HOME/void-xbps/x86_64"
KEY_DIR="$HOME/void-xbps"
ENCRYPTED_KEY="$KEY_DIR/private.pem.gpg"
PRIVATE_KEY="$KEY_DIR/private.pem"
SIGNED_BY="MohamedZaki"

# Color support
if [[ -t 1 ]]; then
  RED="\033[31m"
  GREEN="\033[32m"
  BLUE="\033[34m"
  RESET="\033[0m"
else
  RED="" GREEN="" BLUE="" RESET=""
fi

info() { echo -e "${BLUE}ℹ️INFO:  $*${RESET}"; }
warn() { echo -e "${YELLOW}⚠️  $*${RESET}"; }
success() { echo -e "${GREEN}✅ OK: $*${RESET}"; }
error() {
  echo -e "${RED}❌ ERROR: $*${RESET}"
  exit 1
}

# Prepare repo
mkdir -p "$REPO_DIR"
cd "$REPO_DIR"

# Decrypt private key temporarily
info "Decrypting private key temporarily"
gpg --quiet --decrypt "$ENCRYPTED_KEY" >"$PRIVATE_KEY"
chmod 600 "$PRIVATE_KEY"

# Ensure temporary key is removed after use
cleanup() {
  info "Removing temporary decrypted key"
  rm -f "$PRIVATE_KEY"
}
trap cleanup EXIT

# Build repodata
info "Rebuilding repodata"
rm -f repodata repodata.sig
xbps-rindex -a *.xbps

# Sign repository metadata
info "Signing repository metadata"
xbps-rindex --privkey "$PRIVATE_KEY" --signedby "$SIGNED_BY" -s .

# Sign binary packages
info "Signing binary packages"
xbps-rindex --privkey "$PRIVATE_KEY" -S *.xbps

success "Repository signed successfully"
info "Encrypted GPG key ($ENCRYPTED_KEY) remains intact for future use"
