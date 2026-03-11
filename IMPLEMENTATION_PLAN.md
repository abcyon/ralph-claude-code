# IMPLEMENTATION PLAN

## Status Legend
- [ ] = not started
- [→] = in progress
- [x] = complete

---

## P1 — Important Gaps

(none — all resolved)

## P2 — Minor / Cosmetic

- [x] **`loop-scripts.md` template drift — loop.sh 8 diffs, status.sh 5 diffs** — Synced Enhanced Loop template (MAX_TOTAL, .ralph_pid trap, =prefix filter, [→]→[ ] done revert, high-water mark in update_status/update_status_done, branch-guard update_status_done, ERE grep) and status.sh template (high-water mark model, TOTAL_LINE parsing, ERE grep, negative-COMPLETED guard, removed old log section).

---

## Completed (archived)

<details>
<summary>Click to expand</summary>

### Previous P0 items
- [x] **`unset CLAUDECODE` missing from ralph-plan.md and ralph-loop.md** — Added `unset CLAUDECODE &&` to both command files.
- [x] **`status.sh` template missing from `loop-scripts.md`** — Added full `status.sh` script section to `loop-scripts.md`.
- [x] **`loop.sh` — task checklist missing from `.ralph_status`** — Replaced iteration-based status with IMPLEMENTATION_PLAN.md task list. Uses `write_tasks()` helper with `[→]` marker for first pending item.
- [x] **`loop.sh` — auto-termination on completion** — Added `grep -c '^\s*- \[ \]'` check after each iteration. Exits with `Done.` when 0 pending items.
- [x] **`loop.sh` — smart retry-after parsing** — Added `parse_retry_wait()` helper that parses retry-after from claude output, waits `target + 5min`. Falls back to 5min fixed wait on parse failure.
- [x] **`status.sh` — missing progress bar, mode display, and ETA** — Rewrote `status.sh` with `▶ MODE` header, `── Progress ──` section (16-char progress bar + percent + ETA), `── Tasks ──` section. Handles all edge cases: 0 completed → "예측 중...", all complete → "완료!", no IMPLEMENTATION_PLAN.md → "plan 먼저 실행 필요".
- [x] **`status.sh` template in `loop-scripts.md` must match** — Synced `loop-scripts.md` status.sh template with the new implementation.

### Previous P1 items (batch 3)
- [x] **`loop.sh` + `status.sh` — missing `Total: N` high-water mark** — Added `MAX_TOTAL=0` global, `update_status()` computes current task count from `write_tasks` output and updates high-water mark, writes `Total: $MAX_TOTAL` as 3rd header line. `status.sh` parses `Total: N` from `.ralph_status` line 3, uses it as TOTAL, computes `COMPLETED = TOTAL - PENDING`. Synced `loop-scripts.md` templates.
- [x] **`/ralph-plan` → `/ralph-loop` auto-chaining** — Added sections 3 (pre-execution question), 6 (completion detection + auto-chaining) to `ralph-plan.md`. Polls `.ralph_pid` every 5s, checks `Done.` in `.ralph_status`, auto-starts `/ralph-loop` if pre-yes, re-asks if pre-no, skips on abnormal.
- [x] **`write_tasks()` — Status Legend lines parsed as real tasks** — Added `if (line ~ /^=/) next` after each `sub()` in all 3 awk blocks (`[x]`, `[→]`, `[ ]`). Verified: legend lines excluded, real tasks unaffected. Synced `loop-scripts.md`.

### Previous P2 items (batch 3)
- [x] **`status.sh` — non-portable `grep` BRE `\|` alternation** — Changed both `grep '^\[ \]\|^\[→\]'` and `grep '^\[x\]\|^\[→\]\|^\[ \]'` to `grep -E` with `|` ERE. Synced `loop-scripts.md`.

### Previous P1 items
- [x] **`loop-scripts.md` template sync (4 diffs)** — All 4 diffs between `loop-scripts.md` template and actual `loop.sh` verified as already synced: (a) write_tasks done branch, (b) trap cleanup, (c) branch-change guard, (d) auto-termination ERE grep.
- [x] **`loop.sh` — retry should NOT increment ITERATION** — Removed ITERATION increment from error/retry block. Now uses `continue` without incrementing.
- [x] **`loop.sh` — `.ralph_status` retry countdown** — `update_status` now accepts optional extra line for retry info: `[!] Token limit — retrying at HH:MM:SS (N분 후)`.
- [x] **`loop-scripts.md` template synced with `loop.sh`** — Updated Enhanced Loop template in `loop-scripts.md` to match all loop.sh changes.
- [x] **`loop.sh` — `.ralph_pid` not cleaned up on exit** — Added `.ralph_pid` removal to the EXIT trap alongside `$CLAUDE_OUTPUT_FILE`.
- [x] **`loop.sh` — `grep -c` with `\|` alternation portability** — Changed to `grep -Ec` with `|` for POSIX-portable extended regex.
- [x] **`loop.sh` — branch-change guard exits without `update_status_done`** — Added `update_status_done` call before `exit 1` in branch-change guard.

### Previous P2 items
- [x] **`loop.sh` — `write_tasks "done"` incorrectly marks `[→]` items as in-progress** — When loop terminates early (max iterations, branch change), existing `[→]` items in IMPLEMENTATION_PLAN.md were preserved in done status. Fixed to revert `[→]` to `[ ]` when `mark="done"`.
- [x] **`specs/ralph-commands.md` — spec contradiction: log section in output example** — Output format example showed `── Log (last 5 lines) ──` section but text says "로그 출력 없음". Removed log section from example to match the no-log rule.
- [x] **`install.sh` — `sed -i.bak` trailing-blank-line removal is macOS-only** — Replaced BSD `sed` with portable `awk` that buffers blank lines and only outputs them if followed by non-blank content.
- [x] **Command naming inconsistency: hyphen vs underscore** — Standardized all references to hyphens.
- [x] **`install.sh` CLAUDE.md merge — stale detection** — Now removes existing Ralph section and re-appends latest version.
- [x] **`install.sh` CLAUDE.md merge — last-section edge case** — Replaced `sed` with `awk` for section removal.
- [x] **`specs/ralph-commands.md` — completion check wording** — Updated spec to match implementation (both `[ ]` and `[→]`).
- [x] **`ralph-spec.md` — closing guidance includes `/ralph-plan`, `/ralph-loop`**
- [x] **`prompt-templates.md` — fixed path reference**
- [x] **`specs/ralph-commands.md` — uncommitted changes reviewed and committed** — Progress bar spec, mode display, ETA, edge cases, acceptance criteria all committed.

### Previous Bug Fixes
- [x] **`loop.sh` — `write_tasks()` silently drops `[→]` in-progress items** — Added awk handler for `[→]` markers.
- [x] **`loop.sh` — auto-termination ignores `[→]` items** — Completion check now counts both `[ ]` and `[→]` as pending.

### Initial implementation
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
- [x] `specs/ralph-commands.md` — /ralph-plan, /ralph-loop 상세 스펙
- [x] **P0: install.sh curl 모드에서 새 커맨드 다운로드**
- [x] **P0: .gitignore 생성**
- [x] **P1: ralph-plan/loop.md 동시 실행 guard**
- [x] **P1: install.sh 완료 메시지에 새 커맨드 안내**
- [x] **P2: README.md에 새 커맨드 반영**
- [x] **P2: PROMPT_plan_work.md 템플릿**
- [x] **Spec 수정: specs/ralph-commands.md**
- [x] **.gitignore에 PROMPT_*.md 추가** — 런타임 생성 파일 제외

</details>
