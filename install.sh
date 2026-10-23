#!/usr/bin/env bash
# One-shot Termux installer for OpenCode 1.17.9 (Android / aarch64).
# Installs the prebuilt package from guysoft/opencode-termux release v0.2.1.
set -euo pipefail

VERSION="1.17.9"
BASE_URL="https://github.com/guysoft/opencode-termux/releases/download/v0.2.1"
DEB_NAME="opencode_${VERSION}_aarch64.deb"
DEB_SHA256="8d5dec3eca5e087df6fddc30d86dda58be4029b866d55e71bb10eb209d5eb6f5"
ZIP_NAME="opencode-${VERSION}-android-aarch64.zip"
ZIP_SHA256="0c77d4b8f286e01ba08c9e9aeca8c73a0e0c655342044ab3a59cf1953093a9b0"

# ---------------------------------------------------------------- guards ----

echo "[*] Checking environment..."

if [ -z "${PREFIX:-}" ] && ! command -v pkg >/dev/null 2>&1; then
  echo "[!] This script must be run inside Termux." >&2
  exit 1
fi

if ! command -v pkg >/dev/null 2>&1; then
  echo "[!] 'pkg' not found; are you really in Termux?" >&2
  exit 1
fi

ARCH="$(uname -m)"
if [ "$ARCH" != "aarch64" ]; then
  echo "[!] Unsupported architecture: $ARCH (aarch64 is required)." >&2
  exit 1
fi

# Make sure PREFIX is defined for the manual install paths.
: "${PREFIX:=/data/data/com.termux/files/usr}"

TMPDIR_INSTALL="$(mktemp -d "${TMPDIR:-${PREFIX}/tmp}/opencode-install.XXXXXX")"
cleanup() { rm -rf "$TMPDIR_INSTALL"; }
trap cleanup EXIT

# ----------------------------------------------------------- dependency ----

echo "[*] Checking for ripgrep (required dependency)..."

if ! command -v rg >/dev/null 2>&1; then
  echo "[*] ripgrep not found, installing it with pkg..."
  pkg install -y ripgrep
else
  echo "[*] ripgrep already installed."
fi

echo "[*] Installing required download tools..."

for tool in curl unzip; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "[*] Installing $tool..."
    pkg install -y "$tool"
  fi
done

# ------------------------------------------------------- manual fallback ----

install_from_zip() {
  echo "[*] Fallback: installing from the standalone zip..."

  local zip_path="$TMPDIR_INSTALL/$ZIP_NAME"
  local extract_dir="$TMPDIR_INSTALL/zip"

  curl -fL --retry 3 -o "$zip_path" "$BASE_URL/$ZIP_NAME"

  echo "$ZIP_SHA256  $zip_path" > "$zip_path.sha256"
  sha256sum -c "$zip_path.sha256"

  mkdir -p "$extract_dir"
  unzip -q -o "$zip_path" -d "$extract_dir"

  # Locate the payload root (some archives wrap everything in a top folder).
  local root="$extract_dir"
  if [ ! -f "$root/opencode" ] && [ ! -f "$root/opencode.bin" ]; then
    root="$(find "$extract_dir" -maxdepth 2 -type f -name 'opencode.bin' -print -quit | xargs -r dirname)"
  fi
  if [ -z "$root" ] || [ ! -d "$root" ]; then
    echo "[!] Could not find the extracted OpenCode payload." >&2
    return 1
  fi

  echo "[*] Creating install directories..."
  mkdir -p "$PREFIX/libexec/opencode" "$PREFIX/lib" "$PREFIX/bin"

  if [ -f "$root/opencode" ]; then
    echo "[*] Installing launcher -> $PREFIX/bin/opencode"
    mv -f "$root/opencode" "$PREFIX/bin/opencode"
  fi

  if [ -f "$root/opencode.bin" ]; then
    echo "[*] Installing binary -> $PREFIX/libexec/opencode/"
    mv -f "$root/opencode.bin" "$PREFIX/libexec/opencode/"
  fi

  local lib
  for lib in libtagfix.so libc++_shared.so libopentui.so; do
    if [ -f "$root/$lib" ]; then
      echo "[*] Installing library -> $PREFIX/lib/$lib"
      mv -f "$root/$lib" "$PREFIX/lib/"
    fi
  done

  echo "[*] Setting executable bits..."
  [ -f "$PREFIX/bin/opencode" ] && chmod +x "$PREFIX/bin/opencode"
  [ -f "$PREFIX/libexec/opencode/opencode.bin" ] && chmod +x "$PREFIX/libexec/opencode/opencode.bin"

  return 0
}

# ---------------------------------------------------------- .deb install ----

installed_via_deb=0

if command -v dpkg >/dev/null 2>&1; then
  echo "[*] Preferred route: installing the .deb package..."

  deb_path="$TMPDIR_INSTALL/$DEB_NAME"
  sha_path="$TMPDIR_INSTALL/$DEB_NAME.sha256"

  echo "[*] Downloading $DEB_NAME..."
  if curl -fL --retry 3 -o "$deb_path" "$BASE_URL/$DEB_NAME"; then

    echo "[*] Verifying sha256 checksum..."
    echo "$DEB_SHA256  $deb_path" > "$sha_path"
    if sha256sum -c "$sha_path"; then
      echo "[*] Checksum OK. Installing with dpkg..."
      if dpkg -i "$deb_path"; then
        installed_via_deb=1
        echo "[*] dpkg install succeeded."
      else
        echo "[!] dpkg -i failed; falling back to the standalone zip."
      fi
    else
      echo "[!] Checksum mismatch; falling back to the standalone zip." >&2
    fi
  else
    echo "[!] Download failed; falling back to the standalone zip." >&2
  fi
else
  echo "[*] dpkg not available; using the standalone zip."
fi

# ------------------------------------------------------------- fallback ----

if [ "$installed_via_deb" -ne 1 ]; then
  install_from_zip
fi

# ---------------------------------------------------------------- verify ----

echo "[*] Installation complete. Verifying..."
opencode --version
