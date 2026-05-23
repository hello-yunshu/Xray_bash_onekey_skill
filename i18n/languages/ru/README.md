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

## Использование

В AI-инструменте, поддерживающем Skills (например, Trae), просто скажите AI:

```
Помоги мне настроить Xray на моем сервере
```

AI автоматически:

1. Соберет информацию о сервере и ваши предпочтения (2-3 вопроса)
2. Прочитает исходный код проекта для понимания процесса установки
3. Сгенерирует неинтерактивный установочный скрипт
4. Выполнит через SSH
5. Вернет ссылку VLESS и руководство по настройке клиента

## Структура файлов

```
.
├── SKILL.md    # Файл определения Skill, AI читает его для получения возможности развертывания
├── LICENSE     # GPL-3.0
└── README.md   # Этот файл
```

## Связанные проекты

- [Xray_bash_onekey](https://github.com/hello-yunshu/Xray_bash_onekey) — Основной проект, скрипт одношаговой установки и управления Xray
- [Xray_bash_onekey_Nginx](https://github.com/hello-yunshu/Xray_bash_onekey_Nginx) — Предкомпилированные бинарники Nginx

## Лицензия

[GPL-3.0](LICENSE)
