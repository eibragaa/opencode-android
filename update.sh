#!/usr/bin/env bash
# Atualiza o OpenCode (Android/Termux) para a última release do guysoft/opencode-termux.
# Uso: ./update.sh          -> baixa, verifica e instala a última release
#       ./update.sh --check -> somente mostra o que seria instalado (dry-run)
set -euo pipefail

CHECK="${1:-}"

# Todas as releases do opencode2 são marcadas como pre-release no guysoft,
# então pegamos a mais recente que tenha um deb, sem filtrar por stable.
read -r TAG DEB_URL SHA_URL <<< "$(curl -fsSL -m 25 'https://api.github.com/repos/guysoft/opencode-termux/releases?per_page=30' 2>/dev/null | python3 -c '
import sys,json
rels=json.load(sys.stdin)
for r in rels:
    deb=None; sha=None
    for a in r.get("assets",[]):
        n=a["name"]
        if n.startswith("opencode2_") and n.endswith("_aarch64.deb"): deb=a["browser_download_url"]
        if n=="SHA256SUMS": sha=a["browser_download_url"]
    if deb:
        print(r["tag_name"], deb, sha or "")
        break
')"

if [ -z "$DEB_URL" ]; then
  echo "[!] Não foi possível descobrir a última release Android." >&2
  exit 1
fi

DEB_NAME="$(basename "$DEB_URL")"
installed="$(dpkg-query -W -f='${Version}' opencode2 2>/dev/null || echo none)"

echo "Última release Android: $TAG ($DEB_NAME)"
echo "Versão instalada (dpkg): $installed"

if [ "$CHECK" = "--check" ]; then
  echo "[dry-run] Nada foi baixado nem instalado."
  exit 0
fi

# Já está na última? (compara tag sem o prefixo 'v' com a versão dpkg)
tag_ver="${TAG#v}"
if [ "$installed" = "$tag_ver" ]; then
  echo "[*] Já está na última versão ($tag_ver). Nada a fazer."
  exit 0
fi

: "${PREFIX:=/data/data/com.termux/files/usr}"
TMP="$(mktemp -d "${TMPDIR:-${PREFIX}/tmp}/opencode-update.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

echo "[*] Baixando $DEB_NAME..."
curl -fL --retry 3 -o "$TMP/$DEB_NAME" "$DEB_URL"

if [ -n "$SHA_URL" ]; then
  curl -fsSL --retry 3 -o "$TMP/SHA256SUMS" "$SHA_URL"
  expected="$(awk -v f="$DEB_NAME" '$2==f {print $1}' "$TMP/SHA256SUMS")"
  if [ -n "$expected" ]; then
    echo "[*] Verificando sha256..."
    echo "$expected  $TMP/$DEB_NAME" > "$TMP/check.sha"
    sha256sum -c "$TMP/check.sha"
  else
    echo "[!] sha do deb não encontrado no SHA256SUMS; instalando sem verificação." >&2
  fi
fi

echo "[*] Instalando..."
dpkg -i "$TMP/$DEB_NAME"

echo "[*] Re-linkando 'opencode' -> 'opencode2'..."
ln -sf opencode2 "$PREFIX/bin/opencode"

echo "[*] Concluído."
opencode --version
