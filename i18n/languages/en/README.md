# Xray Bash Onekey Skill — AI Auto Deploy Xray Proxy

[简体中文](/README.md) | English | [Français](/i18n/languages/fr/README.md) | [Русский](/i18n/languages/ru/README.md) | [فارسی](/i18n/languages/fa/README.md) | [한국어](/i18n/languages/ko/README.md)

[![GitHub stars](https://img.shields.io/github/stars/hello-yunshu/Xray_bash_onekey_skill?color=%230885ce)](https://github.com/hello-yunshu/Xray_bash_onekey_skill/stargazers) [![GitHub forks](https://img.shields.io/github/forks/hello-yunshu/Xray_bash_onekey_skill?color=%230885ce)](https://github.com/hello-yunshu/Xray_bash_onekey_skill/network) [![GitHub issues](https://img.shields.io/github/issues/hello-yunshu/Xray_bash_onekey_skill)](https://github.com/hello-yunshu/Xray_bash_onekey_skill/issues)

AI Skill for [Xray_bash_onekey](https://github.com/hello-yunshu/Xray_bash_onekey) — Let AI automatically deploy Xray proxy for you without manual interaction.

## How It Works

Traditional way: User SSH to server → Run installation script → Answer interactive questions one by one → Manually copy connection info

Skill way: User tells AI their needs → AI generates non-interactive script → Auto execute → Directly return VLESS link

Core technology: Uses install.sh's built-in `_TEST_MODE=1` mechanism. After sourcing all functions, override interactive functions and directly call installation functions to complete deployment.

## Supported Installation Modes

| Mode | Domain | Nginx | SSL | Disguise | Best For |
|------|--------|-------|-----|----------|----------|
| Reality | No | Optional | No | ✅ | General use (recommended) |
| TLS | Yes | Yes | Auto | ✅ | Full features |
| ws ONLY | No | No | No | ❌ | Load balancing |
| XTLS ONLY | No | No | No | ❌ | Transit/relay |

## Install

### Option 1: One-line command (Recommended)

```
npx skills add https://github.com/hello-yunshu/Xray_bash_onekey_skill --skill xray-setup
```

### Option 2: Send this message to AI

Help me install the `xray-setup` Skill. Follow these steps:

1. Make sure `~/.claude/skills/` directory exists (create it if not)
2. Run `git clone https://github.com/hello-yunshu/Xray_bash_onekey_skill.git ~/.claude/skills/xray-setup`
3. Verify: `ls ~/.claude/skills/xray-setup/` should show `SKILL.md`, `assets/`, `references/`
4. Tell me it's installed, and I'll be able to trigger this Skill by saying "help me set up Xray"

Copy and paste this message to Claude Code / Cursor / any AI Agent with shell access, and it will install automatically.

### Option 3: Manual command line

```
git clone https://github.com/hello-yunshu/Xray_bash_onekey_skill.git ~/.claude/skills/xray-setup
```

### Trigger

Once installed, the AI will automatically discover and invoke this Skill. Trigger keywords:

- "Help me set up Xray on my server"
- "Deploy a Reality protocol proxy"
- "set up Xray proxy"
- "deploy Xray proxy"
- "Xray one-click install"

## Usage Flow

The Skill is a structured workflow. The AI will guide you through:

1. **Pre-flight** — Verify server environment (OS, architecture, root access, port availability)
2. **Requirements** — Choose installation mode, collect necessary parameters (2-3 questions)
3. **Read source** — AI reads install.sh to understand installation flow and function signatures
4. **Generate script** — Create non-interactive setup script based on source understanding
5. **Deploy** — Execute on server via SSH
6. **Verify** — Check P0 items against checklist
7. **Report** — VLESS link + client configuration guide + security hardening recommendations

See [`SKILL.md`](/SKILL.md) for details.

## Directory Structure

```
xray-setup/
├── SKILL.md                          ← Skill definition: workflow, principles, critical rules
├── README.md                         ← This file
├── LICENSE                           ← GPL-3.0
├── assets/
│   ├── setup-reality.sh              ← Reality mode setup script template
│   └── setup-tls.sh                  ← TLS mode setup script template
├── references/
│   ├── checklist.md                  ← Deployment quality checklist (P0/P1/P2/P3 graded)
│   ├── modes.md                      ← 4 installation modes detailed reference (call chains, variables, parameters)
│   └── troubleshooting.md            ← Troubleshooting reference (common issues and solutions)
└── i18n/
    └── languages/
        ├── en/README.md              ← English
        ├── fr/README.md              ← Français
        ├── ru/README.md              ← Русский
        ├── fa/README.md              ← فارسی
        └── ko/README.md              ← 한국어
```

## Related Projects

- [Xray_bash_onekey](https://github.com/hello-yunshu/Xray_bash_onekey) — Main project, Xray one-click installation and management script
- [Xray_bash_onekey_Nginx](https://github.com/hello-yunshu/Xray_bash_onekey_Nginx) — Precompiled Nginx binaries

## License

[GPL-3.0](LICENSE)
