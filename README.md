# Xray Bash Onekey Skill — AI 自动部署 Xray 代理

简体中文 | [English](/i18n/languages/en/README.md) | [Français](/i18n/languages/fr/README.md) | [Русский](/i18n/languages/ru/README.md) | [فارسی](/i18n/languages/fa/README.md) | [한국어](/i18n/languages/ko/README.md)

[![GitHub stars](https://img.shields.io/github/stars/hello-yunshu/Xray_bash_onekey_skill?color=%230885ce)](https://github.com/hello-yunshu/Xray_bash_onekey_skill/stargazers) [![GitHub forks](https://img.shields.io/github/forks/hello-yunshu/Xray_bash_onekey_skill?color=%230885ce)](https://github.com/hello-yunshu/Xray_bash_onekey_skill/network) [![GitHub issues](https://img.shields.io/github/issues/hello-yunshu/Xray_bash_onekey_skill)](https://github.com/hello-yunshu/Xray_bash_onekey_skill/issues)

[Xray_bash_onekey](https://github.com/hello-yunshu/Xray_bash_onekey) 的 AI Skill — 让 AI 自动帮你部署 Xray 代理，无需手动交互。

## 工作原理

传统方式：用户 SSH 到服务器 → 运行安装脚本 → 逐个回答交互式问题 → 手动复制连接信息

Skill 方式：用户告诉 AI 需求 → AI 生成非交互式脚本 → 自动执行 → 直接返回 VLESS 链接

核心技术：利用 install.sh 内置的 `_TEST_MODE=1` 机制，source 加载全部函数后覆盖交互函数，直接调用安装函数完成部署。

## 支持的安装模式

| 模式 | 域名 | Nginx | SSL | 伪装 | 适用场景 |
|------|------|-------|-----|------|----------|
| Reality | 不需要 | 可选 | 不需要 | ✅ | 日常使用（推荐） |
| TLS | 需要 | 需要 | 自动签发 | ✅ | 全功能 |
| ws ONLY | 不需要 | 不需要 | 不需要 | ❌ | 负载均衡 |
| XTLS ONLY | 不需要 | 不需要 | 不需要 | ❌ | 中转/流量转发 |

## 安装

### 方式一：一行命令安装（推荐）

```
npx skills add https://github.com/hello-yunshu/Xray_bash_onekey_skill --skill xray-setup
```

### 方式二：把下面这段话直接发给 AI

帮我安装 `xray-setup` 这个 Skill。请按下面步骤做：

1. 确保 `~/.claude/skills/` 目录存在（不存在就创建）
2. 执行 `git clone https://github.com/hello-yunshu/Xray_bash_onekey_skill.git ~/.claude/skills/xray-setup`
3. 验证：`ls ~/.claude/skills/xray-setup/` 应该看到 `SKILL.md`、`assets/`、`references/` 三项
4. 告诉我安装好了，之后我说"帮我搭建 Xray"之类的话就会触发这个 Skill

把这段话复制粘贴给 Claude Code / Cursor / 任何有 shell 权限的 AI Agent，它会自动完成安装。

### 方式三：手动命令行

```
git clone https://github.com/hello-yunshu/Xray_bash_onekey_skill.git ~/.claude/skills/xray-setup
```

### 触发方式

装好后，AI 会在对话里自动发现并调用这个 Skill。触发关键词：

- "帮我在服务器上搭建 Xray"
- "部署一个 Reality 协议的代理"
- "set up Xray on my server"
- "deploy Xray proxy"
- "Xray 一键安装"

## 使用流程

Skill 本身是结构化工作流，AI 会逐步引导：

1. **预检** — 验证服务器环境（OS、架构、root 权限、端口可用性）
2. **需求澄清** — 选择安装模式，收集必要参数（2-3 个问题）
3. **阅读源码** — AI 读取 install.sh 理解安装流程和函数签名
4. **生成脚本** — 基于源码理解生成非交互式安装脚本
5. **执行部署** — 通过 SSH 在服务器上执行
6. **验证结果** — 对照 checklist 检查 P0 项
7. **返回信息** — VLESS 链接 + 客户端配置指南 + 安全加固建议

详细说明见 [`SKILL.md`](SKILL.md)。

## 目录结构

```
xray-setup/
├── SKILL.md                          ← Skill 主文件：工作流、原则、关键规则
├── README.md                         ← 本文件
├── LICENSE                           ← GPL-3.0
├── assets/
│   ├── setup-reality.sh              ← Reality 模式安装脚本模板
│   └── setup-tls.sh                  ← TLS 模式安装脚本模板
├── references/
│   ├── checklist.md                  ← 部署质量检查清单（P0/P1/P2/P3 分级）
│   ├── modes.md                      ← 4 种安装模式详细参考（调用链、变量、参数）
│   └── troubleshooting.md            ← 故障排查参考（常见问题与解决方案）
└── i18n/
    └── languages/
        ├── en/README.md              ← English
        ├── fr/README.md              ← Français
        ├── ru/README.md              ← Русский
        ├── fa/README.md              ← فارسی
        └── ko/README.md              ← 한국어
```

## 相关项目

- [Xray_bash_onekey](https://github.com/hello-yunshu/Xray_bash_onekey) — 主项目，Xray 一键安装管理脚本
- [Xray_bash_onekey_Nginx](https://github.com/hello-yunshu/Xray_bash_onekey_Nginx) — 预编译 Nginx 二进制

## License

[GPL-3.0](LICENSE)
