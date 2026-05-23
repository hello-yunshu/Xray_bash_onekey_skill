# Xray Bash Onekey Skill — استقرار خودکار پروکسی Xray توسط هوش مصنوعی

[简体中文](/README.md) | [English](/i18n/languages/en/README.md) | [Français](/i18n/languages/fr/README.md) | [Русский](/i18n/languages/ru/README.md) | فارسی | [한국어](/i18n/languages/ko/README.md)

[![GitHub stars](https://img.shields.io/github/stars/hello-yunshu/Xray_bash_onekey_skill?color=%230885ce)](https://github.com/hello-yunshu/Xray_bash_onekey_skill/stargazers) [![GitHub forks](https://img.shields.io/github/forks/hello-yunshu/Xray_bash_onekey_skill?color=%230885ce)](https://github.com/hello-yunshu/Xray_bash_onekey_skill/network) [![GitHub issues](https://img.shields.io/github/issues/hello-yunshu/Xray_bash_onekey_skill)](https://github.com/hello-yunshu/Xray_bash_onekey_skill/issues)

Skill هوش مصنوعی برای [Xray_bash_onekey](https://github.com/hello-yunshu/Xray_bash_onekey) — به هوش مصنوعی اجازه دهید به طور خودکار پروکسی Xray را برای شما مستقر کند، بدون تعامل دستی.

## نحوه کار

روش سنتی: کاربر SSH به سرور → اجرای اسکریپت نصب → پاسخ به سوالات تعاملی یکی یکی → کپی دستی اطلاعات اتصال

روش Skill: کاربر نیازهای خود را به هوش مصنوعی می‌گوید → هوش مصنوعی اسکریپت غیرتعاملی تولید می‌کند → اجرای خودکار → بازگشت مستقیم لینک VLESS

تکنولوژی اصلی: از مکانیزم داخلی `_TEST_MODE=1` install.sh استفاده می‌کند. پس از بارگذاری تمام توابع، توابع تعاملی را بازنویسی می‌کند و مستقیماً توابع نصب را فراخوانی می‌کند تا مستقرسازی کامل شود.

## حالت‌های نصب پشتیبانی شده

| حالت | دامنه | Nginx | SSL | پوشش | بهترین برای |
|------|-------|-------|-----|-------|-------------|
| Reality | خیر | اختیاری | خیر | ✅ | استفاده کلی (توصیه می‌شود) |
| TLS | بله | بله | خودکار | ✅ | تمام ویژگی‌ها |
| ws ONLY | خیر | خیر | خیر | ❌ | بارگذاری متوازن |
| XTLS ONLY | خیر | خیر | خیر | ❌ | گذر/ریلے |

## نصب

### روش ۱: دستور یک خطی (توصیه می‌شود)

```
npx skills add https://github.com/hello-yunshu/Xray_bash_onekey_skill --skill xray-setup
```

### روش ۲: این پیام را به هوش مصنوعی بفرستید

لطفاً Skill `xray-setup` را برای من نصب کنید. مراحل زیر را دنبال کنید:

1. مطمئن شوید دایرکتوری `~/.claude/skills/` وجود دارد (اگر نیست، ایجاد کنید)
2. دستور `git clone https://github.com/hello-yunshu/Xray_bash_onekey_skill.git ~/.claude/skills/xray-setup` را اجرا کنید
3. تأیید کنید: `ls ~/.claude/skills/xray-setup/` باید `SKILL.md`، `assets/`، `references/` را نشان دهد
4. به من بگویید نصب کامل شده، و با گفتن "کمکم Xray را راه‌اندازی کن" این Skill فعال می‌شود

این پیام را در Claude Code / Cursor / هر Agent هوش مصنوعی با دسترسی shell کپی و پیست کنید تا به طور خودکار نصب شود.

### روش ۳: خط فرمان دستی

```
git clone https://github.com/hello-yunshu/Xray_bash_onekey_skill.git ~/.claude/skills/xray-setup
```

### فعال‌سازی

پس از نصب، هوش مصنوعی به طور خودکار این Skill را کشف و فراخوانی می‌کند. کلمات کلیدی فعال‌سازی:

- "کمکم Xray را روی سرورم راه‌اندازی کن"
- "استقرار پروکسی پروتکل Reality"
- "set up Xray proxy"
- "deploy Xray proxy"
- "نصب یک کلیک Xray"

## جریان استفاده

Skill یک جریان کاری ساختاریافته است. هوش مصنوعی شما را از طریق مراحل زیر راهنمایی می‌کند:

1. **پیش‌بررسی** — تأیید محیط سرور (سیستم‌عامل، معماری، دسترسی root، در دسترس بودن پورت)
2. **نیازها** — انتخاب حالت نصب، جمع‌آوری پارامترهای لازم (۲-۳ سوال)
3. **خواندن منبع** — هوش مصنوعی install.sh را می‌خواند تا جریان نصب و امضاهای توابع را درک کند
4. **تولید اسکریپت** — ایجاد اسکریپت نصب غیرتعاملی بر اساس درک کد منبع
5. **استقرار** — اجرا روی سرور از طریق SSH
6. **تأیید** — بررسی موارد P0 بر اساس چک‌لیست
7. **گزارش** — لینک VLESS + راهنمای پیکربندی کلاینت + توصیه‌های تقویت امنیتی

جزئیات بیشتر در [`SKILL.md`](/SKILL.md).

## ساختار فایل

```
xray-setup/
├── SKILL.md                          ← فایل اصلی Skill: جریان کاری، اصول، قوانین حیاتی
├── README.md                         ← این فایل
├── LICENSE                           ← GPL-3.0
├── assets/
│   ├── setup-reality.sh              ← الگوی اسکریپت نصب حالت Reality
│   └── setup-tls.sh                  ← الگوی اسکریپت نصب حالت TLS
├── references/
│   ├── checklist.md                  ← چک‌لیست کیفیت استقرار (سطح‌بندی P0/P1/P2/P3)
│   ├── modes.md                      ← مرجع تفصیلی ۴ حالت نصب (زنجیره فراخوانی، متغیرها، پارامترها)
│   └── troubleshooting.md            ← مرجع عیب‌یابی (مشکلات رایج و راه‌حل‌ها)
└── i18n/
    └── languages/
        ├── en/README.md              ← English
        ├── fr/README.md              ← Français
        ├── ru/README.md              ← Русский
        ├── fa/README.md              ← فارسی
        └── ko/README.md              ← 한국어
```

## پروژه‌های مرتبط

- [Xray_bash_onekey](https://github.com/hello-yunshu/Xray_bash_onekey) — پروژه اصلی، اسکریپت نصب و مدیریت یک کلیک Xray
- [Xray_bash_onekey_Nginx](https://github.com/hello-yunshu/Xray_bash_onekey_Nginx) — باینری‌های Nginx کامپایل‌شده

## مجوز

[GPL-3.0](LICENSE)
