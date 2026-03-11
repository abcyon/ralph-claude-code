# Loop Scripts Reference

## Minimal Loop

> ⚠️ `PROMPT_build.md` 또는 `PROMPT_plan.md`를 명시해서 실행할 것.
> `PROMPT.md`라는 파일은 존재하지 않는다.

```bash
# Building 모드
while :; do cat PROMPT_build.md | claude -p --dangerously-skip-permissions; done

# Planning 모드
while :; do cat PROMPT_plan.md | claude -p --dangerously-skip-permissions; done
```

---

## Enhanced Loop (권장)

plan/build 모드 선택, max-iterations, 브랜치 guard, git push 안전 처리 포함.

> ⚠️ **macOS:** `plan-work` 모드는 `envsubst` 필요.
> `brew install gettext && brew link gettext`
>
> ⚠️ **--verbose 주의:** 장기 루프(수십~수백 이터레이션)에서는 stdout 로그가 수십 MB에 달할 수 있음.
> 초기 디버깅 시에만 `--verbose` 사용. 안정화 후에는 제거 권장.

```bash
#!/bin/bash
# set -e는 의도적으로 사용하지 않음:
#   - git push 실패 시 에러 메시지 없이 종료되는 문제 방지
#   - claude CLI 일시적 오류(rate limit 등) 시 재시도 가능하게 유지
set -uo pipefail

# Usage:
#   ./loop.sh                    # Build mode, unlimited
#   ./loop.sh 20                 # Build mode, max 20 iterations
#   ./loop.sh plan               # Plan mode, unlimited
#   ./loop.sh plan 5             # Plan mode, max 5 iterations
#   ./loop.sh plan-work "desc"   # Scoped plan on current branch, max 5 iterations

MODE="build"
PROMPT_FILE="PROMPT_build.md"
MAX_ITERATIONS=0

if [ "${1:-}" = "plan" ]; then
    MODE="plan"
    PROMPT_FILE="PROMPT_plan.md"
    MAX_ITERATIONS=${2:-0}

elif [ "${1:-}" = "plan-work" ]; then
    if [ -z "${2:-}" ]; then
        echo "Error: plan-work requires a work description"
        echo "Usage: ./loop.sh plan-work \"description of the work\""
        exit 1
    fi
    MODE="plan-work"
    WORK_DESCRIPTION="$2"
    PROMPT_FILE="PROMPT_plan_work.md"
    MAX_ITERATIONS=${3:-5}

elif [[ "${1:-}" =~ ^[0-9]+$ ]]; then
    MAX_ITERATIONS=$1
fi

ITERATION=0
# 브랜치 변경 guard: 시작 브랜치를 고정하고 루프 중 변경되면 즉시 중단
STARTING_BRANCH=$(git branch --show-current)

# PID 기록 — /ralph-plan, /ralph-loop 커맨드에서 kill 용도로 사용
echo $$ > .ralph_pid

# Temp file for claude output (retry-after parsing)
CLAUDE_OUTPUT_FILE=".ralph_claude_output.tmp"
trap 'rm -f "$CLAUDE_OUTPUT_FILE"' EXIT

# plan-work: main/master 브랜치에서 실행 방지
if [ "$MODE" = "plan-work" ]; then
    if [ "$STARTING_BRANCH" = "main" ] || [ "$STARTING_BRANCH" = "master" ]; then
        echo "Error: plan-work should run on a work branch, not main/master"
        echo "Create a branch first: git checkout -b ralph/your-feature"
        exit 1
    fi
    if ! command -v envsubst &> /dev/null; then
        echo "Error: envsubst not found."
        echo "macOS: brew install gettext && brew link gettext"
        echo "Linux: apt-get install gettext-base"
        exit 1
    fi
    export WORK_SCOPE="$WORK_DESCRIPTION"
fi

if [ ! -f "$PROMPT_FILE" ]; then
    echo "Error: $PROMPT_FILE not found"
    exit 1
fi

# ── Helper: IMPLEMENTATION_PLAN.md에서 태스크 목록 추출 ──
# $1 = "running" → 첫 번째 [ ] 항목을 [→]로 표시, 그 외 → 현재 상태 그대로
write_tasks() {
    local mark_running="${1:-running}"
    if [ -f "IMPLEMENTATION_PLAN.md" ]; then
        sed '/<details>/,$d' IMPLEMENTATION_PLAN.md | awk -v mark="$mark_running" '
            /^[[:space:]]*- \[x\]/ {
                line = $0
                sub(/^[[:space:]]*- \[x\] /, "", line)
                print "[x] " line
                next
            }
            /^[[:space:]]*- \[→\]/ {
                line = $0
                sub(/^[[:space:]]*- \[→\] /, "", line)
                # In-progress items already marked — preserve as-is
                print "[→] " line
                found_running = 1
                next
            }
            /^[[:space:]]*- \[ \]/ {
                line = $0
                sub(/^[[:space:]]*- \[ \] /, "", line)
                if (mark == "running" && !first && !found_running) {
                    print "[→] " line " — running..."
                    first = 1
                } else {
                    print "[ ] " line
                }
            }
        '
    fi
}

# ── Helper: .ralph_status 업데이트 ──
# $1 = optional extra line (e.g. retry info)
update_status() {
    local extra="${1:-}"
    {
        echo "Mode: $MODE | Iteration: $ITERATION | Branch: $STARTING_BRANCH"
        echo "Started: $START_TIME"
        [ -n "$extra" ] && echo "$extra"
        echo ""
        write_tasks "running"
    } > .ralph_status
}

# ── Helper: 완료 상태 기록 ──
update_status_done() {
    local finish_time
    finish_time=$(date "+%Y-%m-%d %H:%M:%S")
    {
        echo "Mode: $MODE | Iteration: $ITERATION | Branch: $STARTING_BRANCH"
        echo "Started: $START_TIME | Finished: $finish_time"
        echo ""
        write_tasks "done"
        echo ""
        echo "Done."
    } > .ralph_status
}

# ── Helper: retry-after 파싱 → 대기 시간(초) 반환 ──
# 성공: target_time + 5분, 실패: 5분 고정
parse_retry_wait() {
    local output_file="$1"
    local retry_seconds=""

    # JSON output에서 retry-after / retry_after 값(초) 탐색
    retry_seconds=$(grep -oi '"retry[_-]after"[[:space:]]*:[[:space:]]*[0-9]*' "$output_file" 2>/dev/null \
        | grep -o '[0-9]*' | tail -1)

    if [ -n "$retry_seconds" ] && [ "$retry_seconds" -gt 0 ] 2>/dev/null; then
        # target_time + 5분
        echo $((retry_seconds + 300))
        return 0
    fi

    # 파싱 실패: 5분 고정
    echo 300
    return 1
}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Mode:   $MODE | Branch: $STARTING_BRANCH"
[ "$MODE" = "plan-work" ] && echo "Work:   $WORK_DESCRIPTION"
[ "$MAX_ITERATIONS" -gt 0 ] && echo "Max:    $MAX_ITERATIONS iterations"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 초기 .ralph_status 작성
START_TIME=$(date "+%Y-%m-%d %H:%M:%S")
update_status

while true; do
    if [ "$MAX_ITERATIONS" -gt 0 ] && [ "$ITERATION" -ge "$MAX_ITERATIONS" ]; then
        echo "Reached max iterations: $MAX_ITERATIONS"
        [ "$MODE" = "plan-work" ] && echo "Scoped plan created. Run: ./loop.sh 20"
        update_status_done
        break
    fi

    # .ralph_status — 현재 이터레이션 실행 중 표시
    update_status

    # Claude 실행 — output을 tee로 파일 + stdout에 동시 출력
    if [ "$MODE" = "plan-work" ]; then
        envsubst < "$PROMPT_FILE" | claude -p \
            --dangerously-skip-permissions \
            --output-format=stream-json \
            --model opus \
            --verbose 2>&1 | tee "$CLAUDE_OUTPUT_FILE"
        CLAUDE_EXIT=${PIPESTATUS[1]:-0}
    else
        cat "$PROMPT_FILE" | claude -p \
            --dangerously-skip-permissions \
            --output-format=stream-json \
            --model opus \
            --verbose 2>&1 | tee "$CLAUDE_OUTPUT_FILE"
        CLAUDE_EXIT=${PIPESTATUS[1]:-0}
    fi

    if [ "$CLAUDE_EXIT" -ne 0 ]; then
        echo "Warning: claude exited with code $CLAUDE_EXIT"

        # Rate limit / token 관련 오류 감지
        if grep -qiE 'rate.limit|overloaded|too.many.requests|retry|429|capacity' "$CLAUDE_OUTPUT_FILE" 2>/dev/null; then
            WAIT_SECONDS=$(parse_retry_wait "$CLAUDE_OUTPUT_FILE") || WAIT_SECONDS=300

            # 재시도 예정 시각 계산 (macOS / Linux 호환)
            RETRY_TIME=$(date -v+"${WAIT_SECONDS}"S "+%H:%M:%S" 2>/dev/null \
                || date -d "+${WAIT_SECONDS} seconds" "+%H:%M:%S" 2>/dev/null \
                || echo "unknown")
            RETRY_MINUTES=$(( (WAIT_SECONDS + 59) / 60 ))

            echo "Rate limit detected. Waiting ${RETRY_MINUTES}분 (until $RETRY_TIME)..."

            # .ralph_status에 대기 상태 표시
            update_status "[!] Token limit — retrying at $RETRY_TIME (${RETRY_MINUTES}분 후)"

            sleep "$WAIT_SECONDS"
        else
            echo "Non-rate-limit error. Retrying in 5 seconds..."
            sleep 5
        fi

        # 동일 이터레이션 재시도 (ITERATION 증가 없음)
        echo -e "\n\n======================== LOOP $((ITERATION + 1)) (retry) ========================\n"
        continue
    fi

    # 브랜치 변경 guard: Claude가 루프 중 브랜치를 바꿨는지 검증
    CURRENT_BRANCH=$(git branch --show-current)
    if [ "$CURRENT_BRANCH" != "$STARTING_BRANCH" ]; then
        echo "Error: Branch changed during loop!"
        echo "Started: '$STARTING_BRANCH' → Now: '$CURRENT_BRANCH'"
        echo "Stopping loop. Run: git checkout $STARTING_BRANCH"
        exit 1
    fi

    # git push — set +e로 일시 해제해 에러 메시지 출력 보장 (set -e와 충돌 방지)
    set +e
    git push origin "$STARTING_BRANCH" 2>/dev/null
    PUSH_EXIT=$?
    set -e

    if [ "$PUSH_EXIT" -ne 0 ]; then
        echo "Push failed. Attempting to set upstream..."
        set +e
        git push -u origin "$STARTING_BRANCH"
        PUSH_EXIT2=$?
        set -e
        if [ "$PUSH_EXIT2" -ne 0 ]; then
            echo "Error: git push failed. Check remote configuration and credentials."
            echo "Stopping loop to prevent cost accumulation."
            exit 1
        fi
    fi

    ITERATION=$((ITERATION + 1))
    echo -e "\n\n======================== LOOP $ITERATION ========================\n"

    # 구현 완료 시 루프 자동 종료: 미완료 항목(`- [ ]` + `- [→]`) 0개이면 Done
    if [ -f "IMPLEMENTATION_PLAN.md" ]; then
        PENDING=$(grep -c '^\s*- \[ \]\|^\s*- \[→\]' IMPLEMENTATION_PLAN.md 2>/dev/null || echo "0")
        if [ "$PENDING" -eq 0 ]; then
            echo "All tasks complete. Stopping loop."
            update_status_done
            break
        fi
    fi

    # .ralph_status — IMPLEMENTATION_PLAN.md 최신 상태 반영
    update_status
done
```

---

## `status.sh` — 실시간 진행 상황 확인

```bash
#!/bin/bash
INTERVAL=${1:-2}

while true; do
    clear

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    if [ ! -f ".ralph_status" ]; then
        echo "ralph가 실행 중이지 않아"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        sleep "$INTERVAL"
        continue
    fi

    # Started 시각에서 elapsed 계산
    STARTED=$(grep '^Started:' .ralph_status | head -1 | sed 's/Started: //' | sed 's/ |.*//')
    ELAPSED="--:--:--"
    if [ -n "$STARTED" ]; then
        START_EPOCH=$(date -j -f "%Y-%m-%d %H:%M:%S" "$STARTED" "+%s" 2>/dev/null \
            || date -d "$STARTED" "+%s" 2>/dev/null || echo "0")
        NOW_EPOCH=$(date "+%s")
        if [ "$START_EPOCH" -gt 0 ] 2>/dev/null; then
            ELAPSED_SEC=$((NOW_EPOCH - START_EPOCH))
            printf -v ELAPSED "%02d:%02d:%02d" $((ELAPSED_SEC/3600)) $(((ELAPSED_SEC%3600)/60)) $((ELAPSED_SEC%60))
        fi
    fi

    echo "Ralph Status  [$(date '+%Y-%m-%d %H:%M:%S')]  Elapsed: $ELAPSED"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    cat .ralph_status

    # 로그 파일 마지막 5줄 표시 (.ralph_plan.log → .ralph_loop.log 순)
    LOG_FILE=""
    if [ -f ".ralph_plan.log" ] && [ -f ".ralph_loop.log" ]; then
        if [ ".ralph_plan.log" -nt ".ralph_loop.log" ]; then
            LOG_FILE=".ralph_plan.log"
        else
            LOG_FILE=".ralph_loop.log"
        fi
    elif [ -f ".ralph_plan.log" ]; then
        LOG_FILE=".ralph_plan.log"
    elif [ -f ".ralph_loop.log" ]; then
        LOG_FILE=".ralph_loop.log"
    fi

    if [ -n "$LOG_FILE" ]; then
        echo ""
        echo "── Log (last 5 lines) ─────────────────"
        tail -5 "$LOG_FILE" 2>/dev/null
    fi

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    sleep "$INTERVAL"
done
```

---

## `PROMPT_plan_work.md` 템플릿

> ⚠️ `${WORK_SCOPE}`는 `envsubst`가 자동으로 치환한다. 직접 편집 금지.

```
0a. First, study `specs/overview.md` to understand the project goal and tech stack.
0b. Then study remaining `specs/*` using parallel Sonnet subagents to learn all specifications.
0c. Study @IMPLEMENTATION_PLAN.md (if present) to understand the plan so far.
0d. Study `src/lib/*` using parallel Sonnet subagents to understand shared utilities & components.
0e. For reference, the application source code is in `src/*`.

1. You are creating a SCOPED implementation plan for work: "${WORK_SCOPE}". Use parallel Sonnet subagents to study existing source code in `src/*` and compare it against specs relevant to this work scope. Use an Opus subagent to analyze findings, prioritize tasks, and create/update @IMPLEMENTATION_PLAN.md as a bullet point list sorted in priority. Ultrathink.

IMPORTANT: SCOPED PLANNING for "${WORK_SCOPE}" only. Include ONLY tasks directly related to this work scope. Plan only. Do NOT implement anything. Do NOT assume functionality is missing; confirm with code search first.

ULTIMATE GOAL: Achieve the scoped work "${WORK_SCOPE}". If an element is missing, search first, then author the spec at specs/FILENAME.md and document the plan in @IMPLEMENTATION_PLAN.md.
```

---

## 모드 요약

| 명령 | 모드 | 기본 반복 | 용도 |
|---|---|---|---|
| `./loop.sh` | build | 무제한 | 전체 빌드 |
| `./loop.sh 20` | build | 20 | 제한된 빌드 |
| `./loop.sh plan` | plan | 무제한 | 전체 plan 생성 |
| `./loop.sh plan 5` | plan | 5 | plan (횟수 지정) |
| `./loop.sh plan-work "desc"` | plan-work | 5 | 브랜치 스코프 plan |
