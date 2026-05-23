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

## 使用方式

在支持 Skill 的 AI 工具（如 Trae）中，直接对 AI 说：

```
帮我在服务器上搭建 Xray
```

AI 会自动：

1. 收集服务器信息和你的偏好（2-3 个问题）
2. 阅读项目源码理解安装流程
3. 生成非交互式安装脚本
4. 通过 SSH 执行安装
5. 返回 VLESS 链接和客户端配置指南

## 文件结构

```
.
├── SKILL.md    # Skill 定义文件，AI 读取后获得部署能力
├── LICENSE     # GPL-3.0
└── README.md   # 本文件
```

## 相关项目

- [Xray_bash_onekey](https://github.com/hello-yunshu/Xray_bash_onekey) — 主项目，Xray 一键安装管理脚本
- [Xray_bash_onekey_Nginx](https://github.com/hello-yunshu/Xray_bash_onekey_Nginx) — 预编译 Nginx 二进制

## License

[GPL-3.0](LICENSE)
