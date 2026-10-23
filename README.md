# opencode-android

Instalador de um passo + configuração para rodar o [OpenCode](https://opencode.ai) — o agente de
programação com IA open-source (upstream: [anomalyco/opencode](https://github.com/anomalyco/opencode))
— **nativamente no Android/Termux**, exposto como o comando **`opencode`**.

Baseado no pacote pré-compilado de [guysoft/opencode-termux](https://github.com/guysoft/opencode-termux).

> **Aviso:** este projeto **NÃO** é construído pela equipe do OpenCode, nem é afiliado a ela.

---

## Por que funciona no Termux

O Android usa **bionic libc** (não glibc). O pacote traz um runtime **Bun** compilado para
Android/aarch64 + a lib nativa do renderizador TUI (`libopentui.so`) e o fix de **seccomp**
(`SIGSYS` → `ENOSYS`), permitindo rodar o binário nativamente no Termux.

## Testado em

| Item | Valor |
| --- | --- |
| Plataforma | Android aarch64, API 37, Termux |
| Binário | OpenCode 2 (`opencode2`) — app 2.0.0-android-termux.2 |
| Comando | `opencode` (symlink para `opencode2`) |

## Como instalar

### Opção 1 — Instalador de um passo

```bash
curl -fsSL https://raw.githubusercontent.com/eibragaa/opencode-android/main/install.sh | bash
```

### Opção 2 — Passo a passo

```bash
# 1. Dependência de busca
pkg install ripgrep

# 2. Baixa e instala o pacote
curl -LO https://github.com/guysoft/opencode-termux/releases/download/v1.0.3/opencode2_1.0.3_aarch64.deb
dpkg -i opencode2_1.0.3_aarch64.deb

# 3. Expõe como 'opencode'
ln -sf opencode2 "$PREFIX/bin/opencode"

# 4. Verifica
opencode --version
```

## Autenticação (plano Go — fronteira/flash)

O OpenCode 2 tem o provedor nativo **OpenCode Go**, que envia automaticamente o header de sessão
exigido pelo plano. Com sua chave do [console OpenCode](https://opencode.ai/auth):

```bash
opencode service set env OPENCODE_API_KEY "oc_sk_..."
opencode service restart

opencode auth list      # deve mostrar: OpenCode Go  OPENCODE_API_KEY  environment
opencode models         # catálogo do plano Go (deepseek-v4-pro, kimi-k3, gpt-6-luna, ...)
```

Alternativa interativa: `opencode auth login opencode-go --method key`.

## Config (fronteira planeja, flash executa)

Copie `opencode.example.json` para `~/.config/opencode/opencode.json`:

| Papel | Modelo |
| --- | --- |
| `model` (padrão) | `opencode-go/deepseek-v4-pro` (fronteira) |
| `small_model` → título | `opencode-go/deepseek-v4.1-flash` (flash) |
| agente `plan` | `opencode-go/deepseek-v4-pro` (fronteira) |
| agente `build` | `opencode-go/deepseek-v4.1-flash` (flash) |

## Como usar

```bash
opencode                 # abre a TUI (Tab alterna build/plan)
opencode run "mensagem"  # execução headless
opencode models          # lista modelos
opencode auth list       # credenciais
opencode serve           # servidor v2
```

## Créditos

- [OpenCode](https://opencode.ai) — upstream: [anomalyco/opencode](https://github.com/anomalyco/opencode)
- [guysoft/opencode-termux](https://github.com/guysoft/opencode-termux) — build Android/Termux usado aqui

Este projeto não é construído pela equipe do OpenCode nem afiliado a ela.
