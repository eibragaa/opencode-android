#!/usr/bin/env bash
# One-shot Termux installer for OpenCode 2 (Android/Termux), exposed as `opencode`.
# Installs the prebuilt package from guysoft/opencode-termux release v1.0.3,
# then links `opencode` -> `opencode2`.
set -euo pipefail

VERSION="1.0.3"   # guysoft package release (OpenCode app 2.0.0-android-termux.2)
BASE_URL="https://github.com/guysoft/opencode-termux/releases/download/v${VERSION}"
DEB_NAME="opencode2_${VERSION}_aarch64.deb"
DEB_SHA256="761ac47793cb7e82cef4bd040e9d509597493f2b62ceb2f0d6eeca19f25e5f00"

echo "[*] Checking environment..."
if [ -z "${PREFIX:-}" ] && ! command -v pkg >/dev/null 2>&1; then
  echo "[!] This script must be run inside Termux." >&2
  exit 1
fi
if [ "$(uname -m)" != "aarch64" ]; then
  echo "[!] Unsupported architecture: $(uname -m) (aarch64 required)." >&2
  exit 1
fi
: "${PREFIX:=/data/data/com.termux/files/usr}"

echo "[*] Ensuring ripgrep (required dependency)..."
if ! command -v rg >/dev/null 2>&1; then pkg install -y ripgrep; fi

echo "[*] Ensuring curl..."
if ! command -v curl >/dev/null 2>&1; then pkg install -y curl; fi

echo "[*] Removing legacy OpenCode 1 if present (to free the 'opencode' name)..."
if dpkg -s opencode >/dev/null 2>&1; then
  dpkg -r opencode || true
fi

TMP="$(mktemp -d "${TMPDIR:-${PREFIX}/tmp}/opencode-install.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

echo "[*] Downloading $DEB_NAME..."
curl -fL --retry 3 -o "$TMP/$DEB_NAME" "$BASE_URL/$DEB_NAME"
echo "$DEB_SHA256  $TMP/$DEB_NAME" > "$TMP/$DEB_NAME.sha256"
sha256sum -c "$TMP/$DEB_NAME.sha256"

echo "[*] Installing..."
dpkg -i "$TMP/$DEB_NAME"

echo "[*] Linking 'opencode' -> 'opencode2'..."
ln -sf opencode2 "$PREFIX/bin/opencode"

echo "[*] Done. Verifying..."
opencode --version
