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

## 설치

### 방법 1: 한 줄 명령어 (권장)

```
npx skills add https://github.com/hello-yunshu/Xray_bash_onekey_skill --skill xray-setup
```

### 방법 2: AI에게 이 메시지를 보내세요

`xray-setup` 스킬을 설치해 주세요. 다음 단계를 따라주세요:

1. `~/.claude/skills/` 디렉토리가 있는지 확인하세요 (없으면 생성)
2. `git clone https://github.com/hello-yunshu/Xray_bash_onekey_skill.git ~/.claude/skills/xray-setup` 실행
3. 확인: `ls ~/.claude/skills/xray-setup/` 에서 `SKILL.md`, `assets/`, `references/` 가 보여야 합니다
4. 설치가 완료되면 알려주세요. "Xray 설정 도와줘"라고 말하면 이 스킬이 활성화됩니다

이 메시지를 Claude Code / Cursor / 쉘 접근 권한이 있는 AI 에이전트에 복사하여 붙여넣으면 자동으로 설치됩니다.

### 방법 3: 수동 명령줄

```
git clone https://github.com/hello-yunshu/Xray_bash_onekey_skill.git ~/.claude/skills/xray-setup
```

### 트리거

설치 후 AI가 자동으로 이 스킬을 발견하고 호출합니다. 트리거 키워드:

- "서버에 Xray 설정 도와주세요"
- "Reality 프로토콜 프록시 배포"
- "set up Xray proxy"
- "deploy Xray proxy"
- "Xray 원클릭 설치"

## 사용 흐름

스킬은 구조화된 워크플로우입니다. AI가 다음 단계로 안내합니다:

1. **사전 확인** — 서버 환경 확인 (OS, 아키텍처, 루트 접근, 포트 가용성)
2. **요구사항** — 설치 모드 선택, 필요한 매개변수 수집 (2-3개 질문)
3. **소스 읽기** — AI가 install.sh를 읽어 설치 흐름과 함수 시그니처 이해
4. **스크립트 생성** — 소스 이해를 기반으로 비상호작용 설정 스크립트 생성
5. **배포** — SSH를 통해 서버에서 실행
6. **검증** — 체크리스트의 P0 항목 확인
7. **보고** — VLESS 링크 + 클라이언트 설정 가이드 + 보안 강화 권장 사항

자세한 내용은 [`SKILL.md`](/SKILL.md)를 참조하세요.

## 파일 구조

```
xray-setup/
├── SKILL.md                          ← 스킬 메인 파일: 워크플로우, 원칙, 핵심 규칙
├── README.md                         ← 이 파일
├── LICENSE                           ← GPL-3.0
├── assets/
│   ├── setup-reality.sh              ← Reality 모드 설치 스크립트 템플릿
│   └── setup-tls.sh                  ← TLS 모드 설치 스크립트 템플릿
├── references/
│   ├── checklist.md                  ← 배포 품질 체크리스트 (P0/P1/P2/P3 등급)
│   ├── modes.md                      ← 4가지 설치 모드 상세 참조 (호출 체인, 변수, 매개변수)
│   └── troubleshooting.md            ← 문제 해결 참조 (일반적인 문제 및 해결 방법)
└── i18n/
    └── languages/
        ├── en/README.md              ← English
        ├── fr/README.md              ← Français
        ├── ru/README.md              ← Русский
        ├── fa/README.md              ← فارسی
        └── ko/README.md              ← 한국어
```

## 관련 프로젝트

- [Xray_bash_onekey](https://github.com/hello-yunshu/Xray_bash_onekey) — 메인 프로젝트, Xray 원클릭 설치 및 관리 스크립트
- [Xray_bash_onekey_Nginx](https://github.com/hello-yunshu/Xray_bash_onekey_Nginx) — 미리 컴파일된 Nginx 바이너리

## 라이선스

[GPL-3.0](LICENSE)
