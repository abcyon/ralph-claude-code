# Overview

## Project Goal

Claude 사용자가 Ralph Workflow(Idea → Specs → Loop)를 쉽게 설치하고 활용할 수 있도록,
슬래시 커맨드와 스크립트를 패키징해서 배포한다.

## Tech Stack

- **Language**: Bash, Markdown
- **Distribution**: `install.sh` → `~/.claude/` 설치
- **Deploy**: 로컬 (개인 개발자 환경)
- **Scale**: 개인 사용자 단위

## Key Features

1. **설치** — `install.sh`로 `~/.claude/`에 파일 배포 (로컬 클론 / curl 양방향 지원)
2. **스펙 작성** — `/ralph-spec`: 대화형으로 specs/ 파일 작성 (새 프로젝트 / 기능 추가 / 기능 변경 / 버그 픽스)
3. **프로젝트 초기 설정** — `/ralph-setup`: loop.sh, PROMPT_*.md, AGENTS.md 생성
4. **Claude Code 내 loop 실행** — `/ralph-plan [n]`, `/ralph-loop [n]`: 외부 쉘 없이 loop.sh 실행, 컨텍스트 소모 없음
5. **레퍼런스 문서** — spec-principles.md, prompt-templates.md, loop-scripts.md, backpressure.md

## Non-Goals

- 웹 UI / 대시보드
- 팀 / 멀티유저 기능
- CI/CD 파이프라인 연동
- Ralph Workflow 외 다른 워크플로우 지원
