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

## Utilisation

Dans un outil AI qui prend en charge les Skills (comme Trae), dites simplement à l'AI :

```
Aide-moi à configurer Xray sur mon serveur
```

L'AI fera automatiquement :

1. Collecter les informations du serveur et les préférences (2-3 questions)
2. Lire le code source du projet pour comprendre le flux d'installation
3. Générer un script d'installation non interactif
4. Exécuter via SSH
5. Retourner le lien VLESS et le guide de configuration client

## Structure des fichiers

```
.
├── SKILL.md    # Fichier de définition de Skill, l'AI lit ce fichier pour obtenir la capacité de déploiement
├── LICENSE     # GPL-3.0
└── README.md   # Ce fichier
```

## Projets connexes

- [Xray_bash_onekey](https://github.com/hello-yunshu/Xray_bash_onekey) — Projet principal, script d'installation et de gestion en un clic de Xray
- [Xray_bash_onekey_Nginx](https://github.com/hello-yunshu/Xray_bash_onekey_Nginx) — Binaires Nginx précompilés

## Licence

[GPL-3.0](LICENSE)
