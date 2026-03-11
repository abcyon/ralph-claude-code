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
MAX_TOTAL=0
# 브랜치 변경 guard: 시작 브랜치를 고정하고 루프 중 변경되면 즉시 중단
STARTING_BRANCH=$(git branch --show-current)

# PID 기록 — /ralph-plan, /ralph-loop 커맨드에서 kill 용도로 사용
echo $$ > .ralph_pid

# Temp file for claude output (retry-after parsing)
CLAUDE_OUTPUT_FILE=".ralph_claude_output.tmp"
trap 'rm -f "$CLAUDE_OUTPUT_FILE" ".ralph_pid"' EXIT

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
                if (line ~ /^=/) next
                print "[x] " line
                next
            }
            /^[[:space:]]*- \[→\]/ {
                line = $0
                sub(/^[[:space:]]*- \[→\] /, "", line)
                if (line ~ /^=/) next
                if (mark == "done") {
                    # Done state: revert in-progress to pending (no running marker)
                    print "[ ] " line
                } else {
                    print "[→] " line
                    found_running = 1
                }
                next
            }
            /^[[:space:]]*- \[ \]/ {
                line = $0
                sub(/^[[:space:]]*- \[ \] /, "", line)
                if (line ~ /^=/) next
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
    # High-water mark: track max total tasks (never decreases)
    if [ -f "IMPLEMENTATION_PLAN.md" ]; then
        local current_total
        current_total=$(write_tasks "done" | wc -l | tr -d ' ')
        if [ "$current_total" -gt "$MAX_TOTAL" ]; then
            MAX_TOTAL=$current_total
        fi
    fi
    {
        echo "Mode: $MODE | Iteration: $ITERATION | Branch: $STARTING_BRANCH"
        echo "Started: $START_TIME"
        echo "Total: $MAX_TOTAL"
        [ -n "$extra" ] && echo "$extra"
        echo ""
        write_tasks "running"
    } > .ralph_status
}

# ── Helper: 완료 상태 기록 ──
update_status_done() {
    local finish_time
    finish_time=$(date "+%Y-%m-%d %H:%M:%S")
    # Update high-water mark one final time
    if [ -f "IMPLEMENTATION_PLAN.md" ]; then
        local current_total
        current_total=$(write_tasks "done" | wc -l | tr -d ' ')
        if [ "$current_total" -gt "$MAX_TOTAL" ]; then
            MAX_TOTAL=$current_total
        fi
    fi
    {
        echo "Mode: $MODE | Iteration: $ITERATION | Branch: $STARTING_BRANCH"
        echo "Started: $START_TIME | Finished: $finish_time"
        echo "Total: $MAX_TOTAL"
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
        update_status_done
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
        PENDING=$(grep -Ec '^\s*- \[ \]|^\s*- \[→\]' IMPLEMENTATION_PLAN.md 2>/dev/null || echo "0")
        if [ "$PENDING" -eq 0 ]; then
            echo "All tasks complete. Stopping loop."
            update_status_done
            break
        fi
    fi

    # .ralph_status — IMPLEMENTATION_PLAN.md 최신 상태 반영
    update_status
done
