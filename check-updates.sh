#!/usr/bin/env bash
# Verifica se o OpenCode (Android/Termux) está atrás do upstream.
# Somente leitura. Dependências: curl, python3 (já presentes no Termux).
# Saída: 0 = atualizado / sem deriva detectável; 1 = há deriva (upstream à frente).
set -euo pipefail

installed="$(opencode --version 2>/dev/null | head -1 || true)"

npm_ver="$(curl -fsSL -m 20 https://registry.npmjs.org/@opencode/cli/latest 2>/dev/null \
  | python3 -c 'import sys,json;print(json.load(sys.stdin).get("version","n/a"))' 2>/dev/null || echo n/a)"

gh_ver="$(curl -fsSL -m 20 https://api.github.com/repos/anomalyco/opencode/releases/latest 2>/dev/null \
  | python3 -c 'import sys,json;print(json.load(sys.stdin).get("tag_name","n/a"))' 2>/dev/null || echo n/a)"

guysoft="$(curl -fsSL -m 25 'https://api.github.com/repos/guysoft/opencode-termux/releases?per_page=30' 2>/dev/null \
  | python3 -c '
import sys,json
rels=json.load(sys.stdin)
def has_deb(r): return any(a["name"].startswith("opencode2_") and a["name"].endswith("_aarch64.deb") for a in r.get("assets",[]))
stable=[r for r in rels if not r.get("prerelease") and has_deb(r)]
pre=[r for r in rels if r.get("prerelease") and has_deb(r)]
def f(r): return r["tag_name"] + " (" + r["published_at"][:10] + ")"
print("estavel:    " + (f(stable[0]) if stable else "n/a"))
print("prerelease: " + (f(pre[0]) if pre else "n/a"))
' 2>/dev/null || echo 'estavel: n/a
prerelease: n/a')"

echo "=== OpenCode Android/Termux — status de atualização ==="
echo "Instalado (app):   ${installed:-n/a}"
echo "Upstream v2 (npm): $npm_ver"
echo "Upstream v1 (gh):  $gh_ver"
echo "Guysoft Android:"
echo "$guysoft"

# Heurística de deriva: compara major.minor do app instalado com o npm v2.
app="$(printf '%s' "$installed" | grep -oE '[0-9]+\.[0-9]+' | head -1)"
up="$(printf '%s' "$npm_ver" | grep -oE '[0-9]+\.[0-9]+' | head -1)"
drift=0
if [ -n "$app" ] && [ -n "$up" ]; then
  # compara numéricamente major.minor
  app_major="${app%%.*}"; app_minor="${app##*.}"
  up_major="${up%%.*}"; up_minor="${up##*.}"
  if [ "$up_major" -gt "$app_major" ] || { [ "$up_major" -eq "$app_major" ] && [ "$up_minor" -gt "$app_minor" ]; }; then
    echo "VEREDITO: upstream v2 ($npm_ver) está À FRENTE do build Android ($installed)."
    drift=1
  else
    echo "VEREDITO: build Android ($installed) acompanha o upstream v2 ($npm_ver)."
  fi
else
  echo "VEREDITO: não foi possível comparar versões (instalado=$installed, npm=$npm_ver)."
fi
exit $drift
