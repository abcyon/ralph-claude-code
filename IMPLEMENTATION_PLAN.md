# IMPLEMENTATION PLAN

## Status Legend
- [ ] = not started
- [→] = in progress
- [x] = complete

---

## Current: All items complete

No open work items. All features implemented and validated:
- install.sh (local + curl modes)
- /ralph-spec, /ralph-setup, /ralph_plan, /ralph_loop commands
- loop.sh (build, plan, plan-work modes with .ralph_status tracking)
- Reference documents (spec-principles, prompt-templates, loop-scripts, backpressure, slc-release)
- .gitignore for runtime files (PROMPT_*.md, IMPLEMENTATION_PLAN.md, .ralph_pid, .ralph_status, *.log)

---

## Completed (archived)

<details>
<summary>Click to expand</summary>

- [x] `dot-claude/commands/ralph-spec.md` — 4가지 작업 유형 분기, 자동 검증 포함
- [x] `dot-claude/commands/ralph-setup.md` — loop.sh, PROMPT_*.md, AGENTS.md 생성
- [x] `dot-claude/commands/ralph-plan.md` — Claude Code 내 plan 실행 (기본 1회)
- [x] `dot-claude/commands/ralph-loop.md` — Claude Code 내 build 실행 (기본 5회)
- [x] `dot-claude/CLAUDE.md` — 4개 커맨드 모두 포함된 Commands 표
- [x] `dot-claude/ralph/spec-principles.md` — JTBD → Topics → Specs 원칙
- [x] `dot-claude/ralph/prompt-templates.md` — PROMPT_plan/build/AGENTS.md 템플릿
- [x] `dot-claude/ralph/loop-scripts.md` — loop.sh 전체 스크립트 + plan-work 모드
- [x] `dot-claude/ralph/backpressure.md` — 3단계 backpressure 가이드
- [x] `dot-claude/ralph/slc-release.md` — SLC 릴리스 워크플로우
- [x] `loop.sh` — .ralph_status 기록, PID 기록, branch guard, plan-work 모드 포함
- [x] `install.sh` — 로컬/curl 양방향 설치, curl 모드 파일 목록 완비
- [x] `specs/overview.md` — 프로젝트 목표, 기술 스택, 핵심 기능, 비목표
- [x] `specs/ralph-commands.md` — /ralph_plan, /ralph_loop 상세 스펙
- [x] **P0: install.sh curl 모드에서 새 커맨드 다운로드**
- [x] **P0: .gitignore 생성**
- [x] **P1: ralph-plan/loop.md 동시 실행 guard**
- [x] **P1: install.sh 완료 메시지에 새 커맨드 안내**
- [x] **P2: README.md에 새 커맨드 반영**
- [x] **P2: PROMPT_plan_work.md 템플릿**
- [x] **Spec 수정: specs/ralph-commands.md**
- [x] **.gitignore에 PROMPT_*.md 추가** — 런타임 생성 파일 제외

</details>
