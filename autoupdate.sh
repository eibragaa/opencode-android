#!/usr/bin/env bash
# Espelha o `autoupdate` do opencode CLI, adaptado ao build Android (guysoft).
#
# O opencode CLI nativo tem a opção `autoupdate`:
#   true       -> baixa e instala a atualização automaticamente ao iniciar
#   "notify"   -> só avisa quando há versão nova
#   false      -> desliga
# Aqui o mesmo comportamento é controlado por OPENCODE_AUTOUPDATE
# (auto | notify | off; padrão: notify) ou pelo arquivo ~/.config/opencode/autoupdate.
#
# IMPORTANTE: não usamos `opencode upgrade` (baixa o binário oficial glibc e quebra
# no Termux). A atualização vem do guysoft/opencode-termux via update.sh.
set -euo pipefail

MODE="${OPENCODE_AUTOUPDATE:-notify}"
[ -f "$HOME/.config/opencode/autoupdate" ] && MODE="$(tr -d '[:space:]' < "$HOME/.config/opencode/autoupdate")"
case "$MODE" in
  auto|true)   MODE=auto ;;
  off|false|0) MODE=off ;;
  *)           MODE=notify ;;
esac

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# --- estado local ---
installed="$(opencode --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || true)"
dpkg_ver="$(dpkg-query -W -f='${Version}' opencode2 2>/dev/null || echo none)"

# --- upstream v2 (npm @opencode/cli) ---
npm_ver="$(curl -fsSL -m 6 https://registry.npmjs.org/@opencode/cli/latest 2>/dev/null \
  | python3 -c 'import sys,json;print(json.load(sys.stdin).get("version",""))' 2>/dev/null || true)"

# --- última release Android do guysoft ---
latest_tag="$(curl -fsSL -m 8 'https://api.github.com/repos/guysoft/opencode-termux/releases?per_page=30' 2>/dev/null \
  | python3 -c '
import sys,json
for r in json.load(sys.stdin):
    if any(a["name"].startswith("opencode2_") and a["name"].endswith("_aarch64.deb") for a in r.get("assets",[])):
        print(r["tag_name"]); break
' 2>/dev/null || true)"
tag_ver="${latest_tag#v}"
tag_ver="${tag_ver//-/}"

# --- derivações ---
update_available=0
[ -n "$tag_ver" ] && [ "$dpkg_ver" != none ] && [ "$dpkg_ver" != "$tag_ver" ] && update_available=1

upstream_ahead=0
if [ -n "$installed" ] && [ -n "$npm_ver" ]; then
  im="${installed%%.*}"; ip="${installed#*.}"; ip="${ip%%.*}"
  um="${npm_ver%%.*}"; up="${npm_ver#*.}"; up="${up%%.*}"
  { [ "$um" -gt "$im" ] || { [ "$um" -eq "$im" ] && [ "$up" -gt "$ip" ]; }; } && upstream_ahead=1
fi

case "$MODE" in
  auto)
    if [ "$update_available" = 1 ]; then
      echo "[opencode] nova release Android: $latest_tag (instalada: $dpkg_ver) — atualizando..."
      "$SCRIPT_DIR/update.sh"
    elif [ "$upstream_ahead" = 1 ]; then
      echo "[opencode] upstream v2 ($npm_ver) à frente do build Android ($installed) — aguardando release do guysoft"
    fi
    ;;
  notify)
    if [ "$update_available" = 1 ]; then
      echo "[opencode] atualização disponível: $latest_tag (instalada: $dpkg_ver) — rode ./update.sh"
    fi
    if [ "$upstream_ahead" = 1 ]; then
      echo "[opencode] upstream v2 ($npm_ver) à frente do build Android ($installed) — aguardando release do guysoft"
    fi
    ;;
  off) ;;
esac

exit 0
