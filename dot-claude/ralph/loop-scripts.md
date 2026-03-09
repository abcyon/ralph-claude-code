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

while true; do
    if [ "$MAX_ITERATIONS" -gt 0 ] && [ "$ITERATION" -ge "$MAX_ITERATIONS" ]; then
        echo "Reached max iterations: $MAX_ITERATIONS"
        [ "$MODE" = "plan-work" ] && echo "Scoped plan created. Run: ./loop.sh 20"
        break
    fi

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
