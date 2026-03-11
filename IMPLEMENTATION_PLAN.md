# IMPLEMENTATION PLAN

## Status Legend
- [ ] = not started
- [→] = in progress
- [x] = complete

---

## P0 — Spec Violations (Critical)

- [x] **`unset CLAUDECODE` missing from ralph-plan.md and ralph-loop.md** — Added `unset CLAUDECODE &&` to both command files.

- [x] **`status.sh` template missing from `loop-scripts.md`** — Added full `status.sh` script section to `loop-scripts.md`.

- [x] **`loop.sh` — task checklist missing from `.ralph_status`** — Replaced iteration-based status with IMPLEMENTATION_PLAN.md task list. Uses `write_tasks()` helper with `[→]` marker for first pending item.

- [x] **`loop.sh` — auto-termination on completion** — Added `grep -c '^\s*- \[ \]'` check after each iteration. Exits with `Done.` when 0 pending items.

- [x] **`loop.sh` — smart retry-after parsing** — Added `parse_retry_wait()` helper that parses retry-after from claude output, waits `target + 5min`. Falls back to 5min fixed wait on parse failure.

## P1 — Important Gaps

- [x] **`loop.sh` — retry should NOT increment ITERATION** — Removed ITERATION increment from error/retry block. Now uses `continue` without incrementing.

- [x] **`loop.sh` — `.ralph_status` retry countdown** — `update_status` now accepts optional extra line for retry info: `[!] Token limit — retrying at HH:MM:SS (N분 후)`.

- [x] **`loop-scripts.md` template synced with `loop.sh`** — Updated Enhanced Loop template in `loop-scripts.md` to match all loop.sh changes.

## P2 — Minor / Cosmetic

- [ ] **Command naming inconsistency: hyphen vs underscore** — Command files use hyphens (`ralph-plan.md`, `ralph-loop.md`) but spec, README, install.sh echo, and CLAUDE.md reference them with underscores (`/ralph_plan`, `/ralph_loop`). Claude Code resolves by filename → actual invocation is `/ralph-plan` and `/ralph-loop`. Either rename the files to `ralph_plan.md`/`ralph_loop.md` or update all docs to use hyphens.
  - Files: `dot-claude/commands/ralph-plan.md`, `ralph-loop.md`, `specs/ralph-commands.md`, `README.md`, `install.sh`, `dot-claude/CLAUDE.md`

- [ ] **`install.sh` CLAUDE.md merge — stale detection** — If `~/.claude/CLAUDE.md` already contains "Ralph Wiggum Workflow", install.sh skips the update entirely (line 68). This means re-running install.sh won't update CLAUDE.md even if the repo version has new content (e.g., `/ralph_plan`, `/ralph_loop` rows). Needs a version-aware merge or replace strategy.
  - File: `install.sh` (lines 66-79)

- [ ] **`ralph-spec.md` — closing guidance doesn't mention /ralph_plan, /ralph_loop** — The closing block only shows terminal commands (`./loop.sh plan`, `./loop.sh`), doesn't mention the new slash command alternatives.
  - File: `dot-claude/commands/ralph-spec.md`

- [ ] **`prompt-templates.md` — wrong path reference for PROMPT_plan_work.md** — References `references/loop-scripts.md` instead of `~/.claude/ralph/loop-scripts.md`.
  - File: `dot-claude/ralph/prompt-templates.md`

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
