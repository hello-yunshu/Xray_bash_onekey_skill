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

## نحوه استفاده

در ابزار هوش مصنوعی که از Skills پشتیبانی می‌کند (مثل Trae)، به سادگی به هوش مصنوعی بگویید:

```
به من کمک کنید Xray را روی سرورم تنظیم کنید
```

هوش مصنوعی به طور خودکار:

1. جمع‌آوری اطلاعات سرور و ترجیحات شما (2-3 سوال)
2. خواندن کد منبع پروژه برای درک جریان نصب
3. تولید اسکریپت تنظیم غیرتعاملی
4. اجرا از طریق SSH
5. بازگشت لینک VLESS و راهنمای پیکربندی مشتری

## ساختار فایل

```
.
├── SKILL.md    # فایل تعریف Skill، هوش مصنوعی این فایل را می‌خواند تا قابلیت مستقرسازی را به دست آورد
├── LICENSE     # GPL-3.0
└── README.md   # این فایل
```

## پروژه‌های مرتبط

- [Xray_bash_onekey](https://github.com/hello-yunshu/Xray_bash_onekey) — پروژه اصلی، اسکریپت نصب و مدیریت یک کلیک Xray
- [Xray_bash_onekey_Nginx](https://github.com/hello-yunshu/Xray_bash_onekey_Nginx) — باینری‌های Nginx کامپایل‌شده

## مجوز

[GPL-3.0](LICENSE)
