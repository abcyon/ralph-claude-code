# IMPLEMENTATION PLAN

## Status Legend
- [ ] = not started
- [→] = in progress
- [x] = complete

---

## P0 — Critical Bugs

(none remaining)

## P1 — Important Gaps

(none remaining)

## P2 — Minor / Cosmetic

(none remaining)

---

## Completed (archived)

<details>
<summary>Click to expand</summary>

### Previous P0 items
- [x] **`loop.sh` — auto-termination uses raw grep, Status Legend inflates PENDING count** — Replaced `grep -Ec` with `write_tasks "done" | grep -Ec '^\[ \]|^\[→\]'` + `PENDING=${PENDING:-0}`. Synced `loop-scripts.md` template.
- [x] **`loop.sh` — `PIPESTATUS` index off-by-one (lines 206, 213)** — Changed `PIPESTATUS[1]` to `PIPESTATUS[0]` to capture claude's exit code instead of tee's. Synced `loop-scripts.md` template.
- [x] **`loop.sh` — branch-change guard writes `Done.` on abnormal exit (line 251)** — Replaced `update_status_done` with `update_status "[ERROR] ..."` so abnormal exits don't have `Done.`, preventing false auto-chaining in `/ralph-plan`. Synced `loop-scripts.md` template.
- [x] **`unset CLAUDECODE` missing from ralph-plan.md and ralph-loop.md** — Added `unset CLAUDECODE &&` to both command files.
- [x] **`status.sh` template missing from `loop-scripts.md`** — Added full `status.sh` script section to `loop-scripts.md`.
- [x] **`loop.sh` — task checklist missing from `.ralph_status`** — Replaced iteration-based status with IMPLEMENTATION_PLAN.md task list. Uses `write_tasks()` helper with `[→]` marker for first pending item.
- [x] **`loop.sh` — auto-termination on completion** — Added `grep -c '^\\s*- \\[ \\]'` check after each iteration. Exits with `Done.` when 0 pending items.
- [x] **`loop.sh` — smart retry-after parsing** — Added `parse_retry_wait()` helper that parses retry-after from claude output, waits `target + 5min`. Falls back to 5min fixed wait on parse failure.
- [x] **`status.sh` — missing progress bar, mode display, and ETA** — Rewrote `status.sh` with `▶ MODE` header, `── Progress ──` section (16-char progress bar + percent + ETA), `── Tasks ──` section. Handles all edge cases: 0 completed → "예측 중...", all complete → "완료!", no IMPLEMENTATION_PLAN.md → "plan 먼저 실행 필요".
- [x] **`status.sh` template in `loop-scripts.md` must match** — Synced `loop-scripts.md` status.sh template with the new implementation.
- [x] **`status.sh` — PENDING double-output crash when grep returns 0 matches** — Fixed `|| echo "0"` pattern to `${PENDING:-0}`.

### Previous P1 items
- [x] **`PROMPT_build.md` + `PROMPT_plan.md` — missing IMPLEMENTATION_PLAN.md format rule comments** — Added format rule notes to `prompt-templates.md` for both PROMPT_plan.md and PROMPT_build.md templates.
- [x] **Uncommitted spec/command changes committed** — `ralph-plan.md` (polling 30s, 30min timeout, auto-loop skip checks 2.0/2.3), `specs/ralph-commands.md` (auto-termination Legend bug spec, acceptance criteria updates), and P0 fix all committed together.
- [x] **`status.sh` — stale-state detection not implemented** — Added `.ralph_pid` existence + `kill -0` check before displaying status. Stale status from crashed/killed loops now shows "ralph가 동작 중이지 않아 (stale status)". Synced `loop-scripts.md` template.
- [x] **`status.sh` — Tasks title truncation not implemented** — Added sed post-processing to strip text after ` — ` separator and remove `**` bold markers in display layer only. Synced `loop-scripts.md` template.
- [x] **`loop.sh` + `status.sh` — missing `Total: N` high-water mark** — Added `MAX_TOTAL=0` global, `update_status()` computes current task count from `write_tasks` output and updates high-water mark, writes `Total: $MAX_TOTAL` as 3rd header line. `status.sh` parses `Total: N` from `.ralph_status` line 3, uses it as TOTAL, computes `COMPLETED = TOTAL - PENDING`. Synced `loop-scripts.md` templates.
- [x] **`/ralph-plan` → `/ralph-loop` auto-chaining** — Added sections 3 (pre-execution question), 6 (completion detection + auto-chaining) to `ralph-plan.md`. Polls `.ralph_pid` every 5s, checks `Done.` in `.ralph_status`, auto-starts `/ralph-loop` if pre-yes, re-asks if pre-no, skips on abnormal.
- [x] **`write_tasks()` — Status Legend lines parsed as real tasks** — Added `if (line ~ /^=/) next` after each `sub()` in all 3 awk blocks (`[x]`, `[→]`, `[ ]`). Verified: legend lines excluded, real tasks unaffected. Synced `loop-scripts.md`.
- [x] **`loop-scripts.md` template sync (4 diffs)** — All 4 diffs between `loop-scripts.md` template and actual `loop.sh` verified as already synced.
- [x] **`loop.sh` — retry should NOT increment ITERATION** — Removed ITERATION increment from error/retry block. Now uses `continue` without incrementing.
- [x] **`loop.sh` — `.ralph_status` retry countdown** — `update_status` now accepts optional extra line for retry info.
- [x] **`loop-scripts.md` template synced with `loop.sh`** — Updated Enhanced Loop template in `loop-scripts.md` to match all loop.sh changes.
- [x] **`loop.sh` — `.ralph_pid` not cleaned up on exit** — Added `.ralph_pid` removal to the EXIT trap alongside `$CLAUDE_OUTPUT_FILE`.
- [x] **`loop.sh` — `grep -c` with `\\|` alternation portability** — Changed to `grep -Ec` with `|` for POSIX-portable extended regex.
- [x] **`loop.sh` — branch-change guard exits without `update_status_done`** — Added `update_status_done` call before `exit 1` in branch-change guard.

### Previous P2 items (batch 2)
- [x] **`dot-claude/CLAUDE.md` command table — `/ralph-setup` description incomplete** — Updated to include status.sh and PROMPT_plan_work.md.
- [x] **`install.sh` curl mode — hardcoded file list asymmetry** — Added comment reminder for manual edits when adding new files.
- [x] **`README.md` — `status.sh` not mentioned** — Added status.sh to usage flow and new project flow sections.
- [x] **`README.md` — `/ralph-plan` and `/ralph-loop` not shown as alternative workflow** — Integrated slash command alternatives into workflow narrative.
- [x] **`install.sh` CLAUDE.md merge — `##` heading edge case** — Changed awk pattern to match both `#` and `##` headings.

### Previous P2 items
- [x] **`CLAUDE.md` — `slc-release.md` missing from Reference section** — Added to the "Reference (load on demand)" list.
- [x] **`loop-scripts.md` template drift — loop.sh 8 diffs, status.sh 5 diffs** — Synced Enhanced Loop template and status.sh template.
- [x] **`loop.sh` — `write_tasks "done"` incorrectly marks `[→]` items as in-progress** — Fixed to revert `[→]` to `[ ]` when `mark="done"`.
- [x] **`specs/ralph-commands.md` — spec contradiction: log section in output example** — Removed log section from example to match the no-log rule.
- [x] **`install.sh` — `sed -i.bak` trailing-blank-line removal is macOS-only** — Replaced BSD `sed` with portable `awk`.
- [x] **Command naming inconsistency: hyphen vs underscore** — Standardized all references to hyphens.
- [x] **`install.sh` CLAUDE.md merge — stale detection** — Now removes existing Ralph section and re-appends latest version.
- [x] **`install.sh` CLAUDE.md merge — last-section edge case** — Replaced `sed` with `awk` for section removal.
- [x] **`specs/ralph-commands.md` — completion check wording** — Updated spec to match implementation.
- [x] **`ralph-spec.md` — closing guidance includes `/ralph-plan`, `/ralph-loop`**
- [x] **`prompt-templates.md` — fixed path reference**
- [x] **`specs/ralph-commands.md` — uncommitted changes reviewed and committed**
- [x] **`status.sh` — non-portable `grep` BRE `\\|` alternation** — Changed to `grep -E` with `|` ERE. Synced `loop-scripts.md`.

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
