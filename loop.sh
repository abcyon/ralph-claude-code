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

# PID 기록 — /ralph_plan, /ralph_loop 커맨드에서 kill 용도로 사용
echo $$ > .ralph_pid

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

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Mode:   $MODE | Branch: $STARTING_BRANCH"
[ "$MODE" = "plan-work" ] && echo "Work:   $WORK_DESCRIPTION"
[ "$MAX_ITERATIONS" -gt 0 ] && echo "Max:    $MAX_ITERATIONS iterations"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 초기 .ralph_status 작성
MAX_DISPLAY=${MAX_ITERATIONS:-"∞"}
START_TIME=$(date "+%Y-%m-%d %H:%M:%S")
{
    echo "Mode: $MODE | Iterations: 0/${MAX_DISPLAY} | Branch: $STARTING_BRANCH"
    echo "Started: $START_TIME"
    echo ""
} > .ralph_status

while true; do
    if [ "$MAX_ITERATIONS" -gt 0 ] && [ "$ITERATION" -ge "$MAX_ITERATIONS" ]; then
        echo "Reached max iterations: $MAX_ITERATIONS"
        [ "$MODE" = "plan-work" ] && echo "Scoped plan created. Run: ./loop.sh 20"
        # .ralph_status 완료 표시
        FINISH_TIME=$(date "+%Y-%m-%d %H:%M:%S")
        {
            echo "Mode: $MODE | Iterations: ${ITERATION}/${MAX_DISPLAY} | Branch: $STARTING_BRANCH"
            echo "Started: $START_TIME | Finished: $FINISH_TIME"
            echo ""
            for i in $(seq 1 "$ITERATION"); do echo "[✓] Iteration $i — complete"; done
            echo "Done."
        } > .ralph_status
        break
    fi

    # .ralph_status — 현재 이터레이션 실행 중 표시
    NEXT=$((ITERATION + 1))
    {
        echo "Mode: $MODE | Iterations: ${ITERATION}/${MAX_DISPLAY} | Branch: $STARTING_BRANCH"
        echo "Started: $START_TIME"
        echo ""
        for i in $(seq 1 "$ITERATION"); do echo "[✓] Iteration $i — complete"; done
        echo "[→] Iteration $NEXT — running..."
    } > .ralph_status

    # Claude 실행 — 실패해도 루프 계속 (rate limit, 일시 오류 등 재시도 가능)
    CLAUDE_EXIT=0
    if [ "$MODE" = "plan-work" ]; then
        envsubst < "$PROMPT_FILE" | claude -p \
            --dangerously-skip-permissions \
            --output-format=stream-json \
            --model opus \
            --verbose || CLAUDE_EXIT=$?
    else
        cat "$PROMPT_FILE" | claude -p \
            --dangerously-skip-permissions \
            --output-format=stream-json \
            --model opus \
            --verbose || CLAUDE_EXIT=$?
    fi

    if [ "$CLAUDE_EXIT" -ne 0 ]; then
        echo "Warning: claude exited with code $CLAUDE_EXIT (rate limit or transient error). Retrying..."
        sleep 5
        ITERATION=$((ITERATION + 1))
        echo -e "\n\n======================== LOOP $ITERATION (retry) ========================\n"
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

    # .ralph_status — 완료된 이터레이션 업데이트
    {
        echo "Mode: $MODE | Iterations: ${ITERATION}/${MAX_DISPLAY} | Branch: $STARTING_BRANCH"
        echo "Started: $START_TIME"
        echo ""
        for i in $(seq 1 "$ITERATION"); do echo "[✓] Iteration $i — complete"; done
    } > .ralph_status
done
