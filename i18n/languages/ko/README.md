# Xray Bash Onekey Skill — AI 자동 배포 Xray 프록시

[简体中文](/README.md) | [English](/i18n/languages/en/README.md) | [Français](/i18n/languages/fr/README.md) | [Русский](/i18n/languages/ru/README.md) | [فارسی](/i18n/languages/fa/README.md) | 한국어

[![GitHub stars](https://img.shields.io/github/stars/hello-yunshu/Xray_bash_onekey_skill?color=%230885ce)](https://github.com/hello-yunshu/Xray_bash_onekey_skill/stargazers) [![GitHub forks](https://img.shields.io/github/forks/hello-yunshu/Xray_bash_onekey_skill?color=%230885ce)](https://github.com/hello-yunshu/Xray_bash_onekey_skill/network) [![GitHub issues](https://img.shields.io/github/issues/hello-yunshu/Xray_bash_onekey_skill)](https://github.com/hello-yunshu/Xray_bash_onekey_skill/issues)

[Xray_bash_onekey](https://github.com/hello-yunshu/Xray_bash_onekey)를 위한 AI 스킬 — AI가 수동 상호작용 없이 자동으로 Xray 프록시를 배포하도록 하세요.

## 작동 원리

기존 방식: 사용자가 SSH로 서버에 접속 → 설치 스크립트 실행 → 상호작용식 질문에 하나씩 답변 → 연결 정보를 수동으로 복사

스킬 방식: 사용자가 AI에게 필요 사항을 말함 → AI가 비상호작용 스크립트 생성 → 자동 실행 → VLESS 링크 직접 반환

핵심 기술: install.sh에 내장된 `_TEST_MODE=1` 메커니즘을 사용합니다. 모든 함수를 소스한 후 상호작용 함수를 재정의하고 설치 함수를 직접 호출하여 배포를 완료합니다.

## 지원되는 설치 모드

| 모드 | 도메인 | Nginx | SSL | 위장 | 적합한 용도 |
|------|--------|-------|-----|------|------------|
| Reality | 아니요 | 선택 사항 | 아니요 | ✅ | 일반 사용(권장) |
| TLS | 예 | 예 | 자동 | ✅ | 전체 기능 |
| ws ONLY | 아니요 | 아니요 | 아니요 | ❌ | 로드 밸런싱 |
| XTLS ONLY | 아니요 | 아니요 | 아니요 | ❌ | 트랜짓/릴레이 |

## 사용 방법

스킬을 지원하는 AI 도구(예: Trae)에서 AI에게 간단히 말합니다:

```
서버에 Xray 설정 도와주세요
```

AI는 자동으로:

1. 서버 정보와 사용자 선호도 수집(2-3개의 질문)
2. 설치 흐름을 이해하기 위해 프로젝트 소스 코드 읽기
3. 비상호작용 설정 스크립트 생성
4. SSH를 통해 실행
5. VLESS 링크와 클라이언트 설정 가이드 반환

## 파일 구조

```
.
├── SKILL.md    # 스킬 정의 파일, AI가 이 파일을 읽어 배포 기능을 획득
├── LICENSE     # GPL-3.0
└── README.md   # 이 파일
```

## 관련 프로젝트

- [Xray_bash_onekey](https://github.com/hello-yunshu/Xray_bash_onekey) — 메인 프로젝트, Xray 원클릭 설치 및 관리 스크립트
- [Xray_bash_onekey_Nginx](https://github.com/hello-yunshu/Xray_bash_onekey_Nginx) — 미리 컴파일된 Nginx 바이너리

## 라이선스

[GPL-3.0](LICENSE)
