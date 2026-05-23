# Xray Bash Onekey Skill — Déploiement automatique du proxy Xray par AI

[简体中文](/README.md) | [English](/i18n/languages/en/README.md) | Français | [Русский](/i18n/languages/ru/README.md) | [فارسی](/i18n/languages/fa/README.md) | [한국어](/i18n/languages/ko/README.md)

[![GitHub stars](https://img.shields.io/github/stars/hello-yunshu/Xray_bash_onekey_skill?color=%230885ce)](https://github.com/hello-yunshu/Xray_bash_onekey_skill/stargazers) [![GitHub forks](https://img.shields.io/github/forks/hello-yunshu/Xray_bash_onekey_skill?color=%230885ce)](https://github.com/hello-yunshu/Xray_bash_onekey_skill/network) [![GitHub issues](https://img.shields.io/github/issues/hello-yunshu/Xray_bash_onekey_skill)](https://github.com/hello-yunshu/Xray_bash_onekey_skill/issues)

Skill AI pour [Xray_bash_onekey](https://github.com/hello-yunshu/Xray_bash_onekey) — Laissez l'AI déployer automatiquement le proxy Xray pour vous sans interaction manuelle.

## Fonctionnement

Méthode traditionnelle : Utilisateur SSH sur serveur → Exécuter script d'installation → Répondre aux questions interactives une par une → Copier manuellement les informations de connexion

Méthode Skill : Utilisateur dit à l'AI ses besoins → AI génère un script non interactif → Exécution automatique → Retour direct du lien VLESS

Technologie centrale : Utilise le mécanisme intégré `_TEST_MODE=1` d'install.sh. Après avoir chargé toutes les fonctions, remplace les fonctions interactives et appelle directement les fonctions d'installation pour terminer le déploiement.

## Modes d'installation pris en charge

| Mode | Domaine | Nginx | SSL | Camouflage | Meilleur pour |
|------|---------|-------|-----|------------|---------------|
| Reality | Non | Optionnel | Non | ✅ | Usage général (recommandé) |
| TLS | Oui | Oui | Automatique | ✅ | Fonctionnalités complètes |
| ws ONLY | Non | Non | Non | ❌ | Équilibrage de charge |
| XTLS ONLY | Non | Non | Non | ❌ | Transit/relais |

## Installation

### Option 1 : Commande en une ligne (Recommandé)

```
npx skills add https://github.com/hello-yunshu/Xray_bash_onekey_skill --skill xray-setup
```

### Option 2 : Envoyez ce message à l'AI

Aidez-moi à installer le Skill `xray-setup`. Suivez ces étapes :

1. Assurez-vous que le répertoire `~/.claude/skills/` existe (créez-le si non)
2. Exécutez `git clone https://github.com/hello-yunshu/Xray_bash_onekey_skill.git ~/.claude/skills/xray-setup`
3. Vérifiez : `ls ~/.claude/skills/xray-setup/` devrait afficher `SKILL.md`, `assets/`, `references/`
4. Dites-moi que c'est installé, et je pourrai déclencher ce Skill en disant "aide-moi à configurer Xray"

Copiez et collez ce message à Claude Code / Cursor / tout Agent AI avec accès shell, et il installera automatiquement.

### Option 3 : Ligne de commande manuelle

```
git clone https://github.com/hello-yunshu/Xray_bash_onekey_skill.git ~/.claude/skills/xray-setup
```

### Déclenchement

Une fois installé, l'AI découvrira et invoquera automatiquement ce Skill. Mots-clés de déclenchement :

- "Aide-moi à configurer Xray sur mon serveur"
- "Déployer un proxy protocole Reality"
- "set up Xray proxy"
- "deploy Xray proxy"
- "Xray installation en un clic"

## Flux d'utilisation

Le Skill est un flux de travail structuré. L'AI vous guidera à travers :

1. **Pré-vérification** — Vérifier l'environnement du serveur (OS, architecture, accès root, disponibilité des ports)
2. **Exigences** — Choisir le mode d'installation, collecter les paramètres nécessaires (2-3 questions)
3. **Lecture source** — L'AI lit install.sh pour comprendre le flux d'installation et les signatures de fonctions
4. **Génération script** — Créer un script d'installation non interactif basé sur la compréhension du code source
5. **Déploiement** — Exécuter sur le serveur via SSH
6. **Vérification** — Vérifier les éléments P0 par rapport à la checklist
7. **Rapport** — Lien VLESS + guide de configuration client + recommandations de renforcement de sécurité

Voir [`SKILL.md`](/SKILL.md) pour plus de détails.

## Structure des fichiers

```
xray-setup/
├── SKILL.md                          ← Définition du Skill : flux de travail, principes, règles critiques
├── README.md                         ← Ce fichier
├── LICENSE                           ← GPL-3.0
├── assets/
│   ├── setup-reality.sh              ← Modèle de script d'installation mode Reality
│   └── setup-tls.sh                  ← Modèle de script d'installation mode TLS
├── references/
│   ├── checklist.md                  ← Checklist qualité de déploiement (graduée P0/P1/P2/P3)
│   ├── modes.md                      ← Référence détaillée des 4 modes d'installation (chaînes d'appel, variables, paramètres)
│   └── troubleshooting.md            ← Référence de dépannage (problèmes courants et solutions)
└── i18n/
    └── languages/
        ├── en/README.md              ← English
        ├── fr/README.md              ← Français
        ├── ru/README.md              ← Русский
        ├── fa/README.md              ← فارسی
        └── ko/README.md              ← 한국어
```

## Projets connexes

- [Xray_bash_onekey](https://github.com/hello-yunshu/Xray_bash_onekey) — Projet principal, script d'installation et de gestion en un clic de Xray
- [Xray_bash_onekey_Nginx](https://github.com/hello-yunshu/Xray_bash_onekey_Nginx) — Binaires Nginx précompilés

## Licence

[GPL-3.0](LICENSE)
