# Xray Bash Onekey Skill — Автоматическое развертывание прокси Xray через AI

[简体中文](/README.md) | [English](/i18n/languages/en/README.md) | [Français](/i18n/languages/fr/README.md) | Русский | [فارسی](/i18n/languages/fa/README.md) | [한국어](/i18n/languages/ko/README.md)

[![GitHub stars](https://img.shields.io/github/stars/hello-yunshu/Xray_bash_onekey_skill?color=%230885ce)](https://github.com/hello-yunshu/Xray_bash_onekey_skill/stargazers) [![GitHub forks](https://img.shields.io/github/forks/hello-yunshu/Xray_bash_onekey_skill?color=%230885ce)](https://github.com/hello-yunshu/Xray_bash_onekey_skill/network) [![GitHub issues](https://img.shields.io/github/issues/hello-yunshu/Xray_bash_onekey_skill)](https://github.com/hello-yunshu/Xray_bash_onekey_skill/issues)

AI-скилл для [Xray_bash_onekey](https://github.com/hello-yunshu/Xray_bash_onekey) — Позвольте AI автоматически развернуть прокси Xray для вас без ручного взаимодействия.

## Как это работает

Традиционный способ: Пользователь через SSH на сервер → Запустить установочный скрипт → Ответить на интерактивные вопросы по очереди → Вручную скопировать данные подключения

Способ через Skill: Пользователь говорит AI о своих потребностях → AI генерирует неинтерактивный скрипт → Автоматическое выполнение → Прямой возврат ссылки VLESS

Ядро технологии: Использует встроенный механизм `_TEST_MODE=1` из install.sh. После загрузки всех функций заменяет интерактивные функции и напрямую вызывает установочные функции для завершения развертывания.

## Поддерживаемые режимы установки

| Режим | Домен | Nginx | SSL | Маскировка | Для чего подходит |
|-------|-------|-------|-----|-----------|------------------|
| Reality | Нет | Опционально | Нет | ✅ | Общее использование (рекомендовано) |
| TLS | Да | Да | Автоматически | ✅ | Полный набор функций |
| ws ONLY | Нет | Нет | Нет | ❌ | Балансировка нагрузки |
| XTLS ONLY | Нет | Нет | Нет | ❌ | Транзит/ретрансляция |

## Установка

### Способ 1: Одна команда (Рекомендуется)

```
npx skills add https://github.com/hello-yunshu/Xray_bash_onekey_skill --skill xray-setup
```

### Способ 2: Отправьте это сообщение AI

Помоги мне установить скилл `xray-setup`. Выполни следующие шаги:

1. Убедись, что директория `~/.claude/skills/` существует (создай, если нет)
2. Выполни `git clone https://github.com/hello-yunshu/Xray_bash_onekey_skill.git ~/.claude/skills/xray-setup`
3. Проверь: `ls ~/.claude/skills/xray-setup/` должен показать `SKILL.md`, `assets/`, `references/`
4. Скажи мне, что установка завершена, и я смогу активировать этот скилл, сказав "помоги настроить Xray"

Скопируй и вставь это сообщение в Claude Code / Cursor / любой AI-агент с доступом к shell, и он автоматически выполнит установку.

### Способ 3: Ручная командная строка

```
git clone https://github.com/hello-yunshu/Xray_bash_onekey_skill.git ~/.claude/skills/xray-setup
```

### Активация

После установки AI автоматически обнаружит и вызовет этот скилл. Ключевые слова для активации:

- "Помоги мне настроить Xray на моём сервере"
- "Развернуть прокси протокола Reality"
- "set up Xray proxy"
- "deploy Xray proxy"
- "Xray установка в один клик"

## Рабочий процесс

Скилл представляет собой структурированный рабочий процесс. AI проведёт вас через:

1. **Предварительная проверка** — Проверка окружения сервера (ОС, архитектура, root-доступ, доступность портов)
2. **Требования** — Выбор режима установки, сбор необходимых параметров (2-3 вопроса)
3. **Чтение исходного кода** — AI читает install.sh для понимания процесса установки и сигнатур функций
4. **Генерация скрипта** — Создание неинтерактивного установочного скрипта на основе понимания исходного кода
5. **Развёртывание** — Выполнение на сервере через SSH
6. **Проверка** — Проверка элементов P0 по чеклисту
7. **Отчёт** — Ссылка VLESS + руководство по настройке клиента + рекомендации по усилению безопасности

Подробности см. в [`SKILL.md`](/SKILL.md).

## Структура файлов

```
xray-setup/
├── SKILL.md                          ← Основной файл скилла: рабочий процесс, принципы, критические правила
├── README.md                         ← Этот файл
├── LICENSE                           ← GPL-3.0
├── assets/
│   ├── setup-reality.sh              ← Шаблон скрипта установки режима Reality
│   └── setup-tls.sh                  ← Шаблон скрипта установки режима TLS
├── references/
│   ├── checklist.md                  ← Чеклист качества развёртывания (уровни P0/P1/P2/P3)
│   ├── modes.md                      ← Подробный справочник по 4 режимам установки (цепочки вызовов, переменные, параметры)
│   └── troubleshooting.md            ← Справочник по устранению неполадок (частые проблемы и решения)
└── i18n/
    └── languages/
        ├── en/README.md              ← English
        ├── fr/README.md              ← Français
        ├── ru/README.md              ← Русский
        ├── fa/README.md              ← فارسی
        └── ko/README.md              ← 한국어
```

## Связанные проекты

- [Xray_bash_onekey](https://github.com/hello-yunshu/Xray_bash_onekey) — Основной проект, скрипт одношаговой установки и управления Xray
- [Xray_bash_onekey_Nginx](https://github.com/hello-yunshu/Xray_bash_onekey_Nginx) — Предкомпилированные бинарники Nginx

## Лицензия

[GPL-3.0](LICENSE)
