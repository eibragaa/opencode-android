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

## Configuração de provedor

Defina a chave de API como variável de ambiente:

```bash
export ANTHROPIC_API_KEY="sua-chave"
# ou
export OPENAI_API_KEY="sua-chave"
```

Ou autentique de forma interativa:

```bash
opencode auth login
# ou
opencode providers
```

## Nota sobre versões

O upstream também mantém uma pré-release **v2** (`opencode2`), baseada no alvo Android oficial do Bun com correção de seccomp. Este repositório **fixa a v1 em 1.17.9** por estabilidade.

## Créditos

- [OpenCode](https://opencode.ai) — projeto upstream: [anomalyco/opencode](https://github.com/anomalyco/opencode)
- [guysoft/opencode-termux](https://github.com/guysoft/opencode-termux) — pacote Android/Termux pré-compilado usado por este repositório

Este projeto não é construído pela equipe do OpenCode nem afiliado a ela.
