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

## Usage

In an AI tool that supports Skills (like Trae), simply tell the AI:

```
Help me set up Xray on my server
```

The AI will automatically:

1. Collect server info and preferences (2-3 questions)
2. Read project source code to understand the installation flow
3. Generate a non-interactive setup script
4. Execute via SSH
5. Return VLESS link and client configuration guide

## File Structure

```
.
├── SKILL.md    # Skill definition file, AI reads this to gain deployment capability
├── LICENSE     # GPL-3.0
└── README.md   # This file
```

## Related Projects

- [Xray_bash_onekey](https://github.com/hello-yunshu/Xray_bash_onekey) — Main project, Xray one-click installation and management script
- [Xray_bash_onekey_Nginx](https://github.com/hello-yunshu/Xray_bash_onekey_Nginx) — Precompiled Nginx binaries

## License

[GPL-3.0](LICENSE)
