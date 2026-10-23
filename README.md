# opencode-android

Repositório companheiro + instalador de um passo para rodar o [OpenCode](https://opencode.ai) — o agente de programação com IA open-source (repositório upstream: [anomalyco/opencode](https://github.com/anomalyco/opencode)) — **nativamente no Android/Termux**.

Ele instala o pacote Android/Termux pré-compilado de [guysoft/opencode-termux](https://github.com/guysoft/opencode-termux).

> **Aviso:** este projeto **NÃO** é construído pela equipe do OpenCode, nem é afiliado a ela (conforme o próprio README do OpenCode).

---

## Por que funciona no Termux

O Android usa **bionic libc**, e não glibc — por isso binários Linux tradicionais não rodam no Termux. O pacote contorna isso trazendo um conjunto próprio de bibliotecas compiladas para Android/aarch64:

- Runtime **Bun** com patch
- **WebKit/JSC**
- `libopentui.so`
- `libtagfix.so`
- `libc++_shared.so`

## Testado em

| Item | Valor |
| --- | --- |
| Plataforma | Android aarch64, API 37, Termux |
| Versão | opencode 1.17.9 |

`opencode --version` imprime `1.17.9` e a ajuda/TUI renderizam corretamente.

## Como instalar

### Opção 1 — Instalador de um passo

```bash
curl -fsSL https://raw.githubusercontent.com/eibragaa/opencode-android/main/install.sh | bash
```

### Opção 2 — Passo a passo manual

```bash
# 1. Baixe o pacote pré-compilado
curl -LO https://github.com/guysoft/opencode-termux/releases/download/v0.2.1/opencode_1.17.9_aarch64.deb

# 2. Instale o pacote
dpkg -i opencode_1.17.9_aarch64.deb

# 3. Instale o ripgrep (dependência de busca)
pkg install ripgrep
```

Verifique a instalação:

```bash
opencode --version
```

## Como usar

```bash
opencode                  # abre a TUI
opencode run "mensagem"   # execução headless (sem interface)
opencode models           # lista os modelos disponíveis
opencode providers        # autenticação / gerenciamento de provedores
opencode serve            # sobe o servidor
opencode web              # interface web
opencode agent            # gerenciamento de agentes
```

## Configuração de provedor (plano Go / fronteira+flash)

O **OpenCode 2** (`opencode2`) tem o provedor nativo **OpenCode Go**, que envia
automaticamente o header de sessão exigido pelo plano. Autentique com a sua chave do
[console OpenCode](https://opencode.ai/auth):

```bash
# 1. Registra a chave no ambiente do serviço em background
opencode2 service set env OPENCODE_API_KEY "oc_sk_..."
opencode2 service restart

# 2. (alternativa interativa) login com a chave
opencode2 auth login opencode-go --method key

# 3. Confirma
opencode2 auth list      # deve mostrar: OpenCode Go  OPENCODE_API_KEY  environment
opencode2 models         # lista o catálogo do plano Go (deepseek-v4-pro, kimi-k3, gpt-6-luna, ...)
```

Copie `opencode.example.json` para `~/.config/opencode/opencode.json` para espelhar a
estratégia fronteira/flash:

| Papel | Modelo |
|---|---|
| `model` (padrão) | `opencode-go/deepseek-v4-pro` (fronteira) |
| `small_model` → título | `opencode-go/deepseek-v4.1-flash` (flash) |
| agente `plan` | `opencode-go/deepseek-v4-pro` (fronteira) |
| agente `build` | `opencode-go/deepseek-v4.1-flash` (flash) |

> O v1 (`opencode`, free tier) também aceita `OPENCODE_API_KEY`, mas expõe apenas os
> modelos gratuitos. O plano Go (modelos de fronteira pagos) exige o `opencode2`.

## Como usar

```bash
opencode2                 # abre a TUI (Tab alterna build/plan)
opencode2 run "mensagem"  # execução headless
opencode2 models          # lista modelos
opencode2 auth list       # credenciais
opencode2 serve           # servidor v2
```

Legado (v1):

```bash
opencode                  # abre a TUI do v1
opencode run "mensagem"   # execução headless
opencode models           # lista os modelos
opencode providers        # autenticação / gerenciamento de provedores
opencode serve            # sobe o servidor
opencode web              # interface web
opencode agent            # gerenciamento de agentes
```

## Nota sobre versões

Há dois binários, instalados lado a lado:

- **`opencode` (v1, 1.17.9)** — estável, TUI clássica. Só expõe os modelos gratuitos do provedor `opencode`.
- **`opencode2` (v2, 2.0.0-android-termux.2)** — preview com o provedor nativo **OpenCode Go**
  (suporta o plano pago de fronteira/flash, com header de sessão e fix de seccomp). É o caminho recomendado aqui.

## Créditos

- [OpenCode](https://opencode.ai) — projeto upstream: [anomalyco/opencode](https://github.com/anomalyco/opencode)
- [guysoft/opencode-termux](https://github.com/guysoft/opencode-termux) — pacote Android/Termux pré-compilado usado por este repositório

Este projeto não é construído pela equipe do OpenCode nem afiliado a ela.
