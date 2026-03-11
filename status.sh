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

    # ── Parse .ralph_status header ──
    MODE_LINE=$(head -1 .ralph_status)
    STARTED_LINE=$(sed -n '2p' .ralph_status)

    # Extract mode, iteration, branch from "Mode: build | Iteration: 3 | Branch: main"
    RAW_MODE=$(echo "$MODE_LINE" | sed 's/Mode: //' | sed 's/ |.*//')
    ITERATION=$(echo "$MODE_LINE" | grep -o 'Iteration: [0-9]*' | grep -o '[0-9]*')
    BRANCH=$(echo "$MODE_LINE" | grep -o 'Branch: .*' | sed 's/Branch: //')

    # Format mode display
    case "$RAW_MODE" in
        plan)      MODE_DISPLAY="▶ PLAN MODE" ;;
        build)     MODE_DISPLAY="▶ BUILD MODE" ;;
        plan-work) MODE_DISPLAY="▶ PLAN-WORK MODE" ;;
        *)         MODE_DISPLAY="▶ ${RAW_MODE:-UNKNOWN} MODE" ;;
    esac

    # Extract started time
    STARTED=$(echo "$STARTED_LINE" | sed 's/Started: //' | sed 's/ |.*//')

    # Calculate elapsed time
    ELAPSED="--:--:--"
    ELAPSED_SEC=0
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

    # Mode / Iteration / Branch
    echo "$MODE_DISPLAY  |  Iteration: ${ITERATION:-0}  |  Branch: ${BRANCH:-unknown}"
    echo "$STARTED_LINE"

    # ── Progress section ──
    echo ""
    echo "── Progress ────────────────────────────"

    if [ ! -f "IMPLEMENTATION_PLAN.md" ]; then
        echo "IMPLEMENTATION_PLAN.md 없음 — ./loop.sh plan 먼저 실행 필요"
    else
        # Count tasks from .ralph_status (already parsed by loop.sh)
        COMPLETED=$(grep -c '^\[x\]' .ralph_status 2>/dev/null || echo "0")
        PENDING=$(grep -c '^\[ \]\|^\[→\]' .ralph_status 2>/dev/null || echo "0")
        TOTAL=$((COMPLETED + PENDING))

        if [ "$TOTAL" -eq 0 ]; then
            # Fallback: count from IMPLEMENTATION_PLAN.md directly
            COMPLETED=$(sed '/<details>/,$d' IMPLEMENTATION_PLAN.md | grep -c '^\s*- \[x\]' 2>/dev/null || echo "0")
            PENDING=$(sed '/<details>/,$d' IMPLEMENTATION_PLAN.md | grep -Ec '^\s*- \[ \]|^\s*- \[→\]' 2>/dev/null || echo "0")
            TOTAL=$((COMPLETED + PENDING))
        fi

        if [ "$TOTAL" -eq 0 ]; then
            echo "[░░░░░░░░░░░░░░░░]  0/0   0%  ETA: 예측 중..."
        elif [ "$COMPLETED" -eq "$TOTAL" ]; then
            echo "[████████████████]  $TOTAL/$TOTAL  100%  완료!"
        else
            # Calculate progress bar (16 chars)
            FILLED=$((COMPLETED * 16 / TOTAL))
            EMPTY=$((16 - FILLED))
            BAR=""
            for ((i=0; i<FILLED; i++)); do BAR+="█"; done
            for ((i=0; i<EMPTY; i++)); do BAR+="░"; done

            PERCENT=$((COMPLETED * 100 / TOTAL))
            REMAINING=$((TOTAL - COMPLETED))

            # ETA calculation
            if [ "$COMPLETED" -eq 0 ]; then
                ETA_DISPLAY="예측 중..."
            else
                # ETA = elapsed / completed * remaining
                ETA_SEC=$((ELAPSED_SEC * REMAINING / COMPLETED))
                ETA_MIN=$(( (ETA_SEC + 59) / 60 ))
                ETA_DISPLAY="~${ETA_MIN}분"
            fi

            printf "[%s]  %d/%d  %d%%  ETA: %s\n" "$BAR" "$COMPLETED" "$TOTAL" "$PERCENT" "$ETA_DISPLAY"
        fi
    fi

    # ── Tasks section ──
    echo ""
    echo "── Tasks ───────────────────────────────"

    # Extract task lines from .ralph_status (lines starting with [x], [→], [ ])
    grep '^\[x\]\|^\[→\]\|^\[ \]' .ralph_status 2>/dev/null || echo "(태스크 없음)"

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    sleep "$INTERVAL"
done
