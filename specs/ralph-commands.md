# Spec: /ralph_plan & /ralph_loop Commands

## Overview

Two slash commands that run `loop.sh` from within Claude Code — no external shell needed.
Execution output is redirected to a log file to avoid context accumulation.
Progress is tracked in a compact `.ralph_status` file.

---

## Commands

### `/ralph_plan [n]`

Run `loop.sh` in plan mode from within Claude Code.

- **Argument**: `n` = number of iterations (default: `1`)
- **Prerequisite checks** (in order):
  1. `loop.sh` not found → show error, guide to `/ralph-spec` → `/ralph-setup`
  2. `PROMPT_plan.md` not found → show error, guide to `/ralph-setup`
- **Execution**: `./loop.sh plan [n]` 실행. 현재 Claude 컨텍스트에 출력이 누적되지 않아야 함
- **Logs**: Full output → `.ralph_plan.log` (overwrite on each run)
- **Status**: Progress written to `.ralph_status` by loop.sh
- **On launch**: Show confirmation message + how to check progress
- **IMPLEMENTATION_PLAN.md**: Overwrite without confirmation if already exists (plan mode always regenerates)

#### Acceptance Criteria

- [ ] `/ralph_plan` (no args) runs `./loop.sh plan 1`
- [ ] `/ralph_plan 3` runs `./loop.sh plan 3`
- [ ] Missing `loop.sh` → error message + "먼저 `/ralph-spec`로 스펙을 작성하고, `/ralph-setup`으로 초기 설정을 해줘" 안내
- [ ] Missing `PROMPT_plan.md` → error message + "`/ralph-setup`을 먼저 실행해줘" 안내
- [ ] Output does NOT accumulate in current Claude context (redirected to log file)
- [ ] `.ralph_plan.log` created/overwritten on run start
- [ ] `.ralph_status` updated at each loop iteration

---

### `/ralph_loop [n]`

Run `loop.sh` in build mode from within Claude Code.

- **Argument**: `n` = number of iterations (default: `5`)
- **Prerequisite checks** (in order):
  1. `loop.sh` not found → show error, guide to `/ralph-spec` → `/ralph-setup`
  2. `PROMPT_build.md` not found → show error, guide to `/ralph-setup`
  3. `IMPLEMENTATION_PLAN.md` not found → show warning, suggest running `/ralph_plan` first
- **Execution**: `./loop.sh [n]` 실행. 현재 Claude 컨텍스트에 출력이 누적되지 않아야 함
- **Logs**: Full output → `.ralph_loop.log` (overwrite on each run)
- **Status**: Progress written to `.ralph_status` by loop.sh
- **On launch**: Show confirmation message + how to check progress
- **Stop**: User can stop with Ctrl+C or `kill $(cat .ralph_pid)`

#### Acceptance Criteria

- [ ] `/ralph_loop` (no args) runs `./loop.sh 5`
- [ ] `/ralph_loop 20` runs `./loop.sh 20`
- [ ] Missing `loop.sh` → error + guide to `/ralph-spec` + `/ralph-setup`
- [ ] Missing `PROMPT_build.md` → error + guide to `/ralph-setup`
- [ ] Missing `IMPLEMENTATION_PLAN.md` → warning + suggest `/ralph_plan`
- [ ] Output does NOT accumulate in current Claude context
- [ ] `.ralph_loop.log` created/overwritten on run start
- [ ] `.ralph_status` updated at each loop iteration

---

## `.ralph_status` File Format

Updated by `loop.sh` after each iteration. Compact checklist format:

```
Mode: plan | Iterations: 2/3 | Branch: main
Started: 2026-03-11 14:32:01

[✓] Iteration 1 — complete
[✓] Iteration 2 — complete
[→] Iteration 3 — running...
```

On completion:
```
Mode: plan | Iterations: 3/3 | Branch: main
Started: 2026-03-11 14:32:01 | Finished: 2026-03-11 14:35:44

[✓] Iteration 1 — complete
[✓] Iteration 2 — complete
[✓] Iteration 3 — complete
Done.
```

---

## `loop.sh` 동작 요구사항

loop.sh는 실행 중 아래 정보를 `.ralph_status` 파일에 기록해야 함:

- 실행 시작 시: mode, max iterations, branch, 시작 시각
- 각 이터레이션 실행 중: 현재 진행 상황 (완료/실행중 구분)
- 이터레이션 완료 후: 완료 표시로 업데이트
- 전체 완료 시: 종료 시각 및 Done. 표기
- 실행 중인 프로세스를 중단할 수 있도록 프로세스 식별 정보를 파일로 기록

---

## Distribution

`dot-claude/commands/ralph-plan.md` and `dot-claude/commands/ralph-loop.md` are installed via `install.sh`.

`install.sh` copies all `dot-claude/commands/*.md` in local mode. Curl mode requires explicit file list — `ralph-plan.md` and `ralph-loop.md` must be included in the download section.

---

## Edge Cases

- **동시 실행**: `/ralph_plan` 또는 `/ralph_loop` 실행 중 같은 커맨드를 다시 실행하면 기존 프로세스 중단 여부를 경고하고 사용자에게 확인 요청
- **n=0**: 무제한 실행으로 처리 (loop.sh 기본 동작과 동일)

---

## Non-Goals

- No other new commands
- No changes to loop.sh logic beyond status file writes
- No web UI or dashboard
- No auto-restart after Ctrl+C
