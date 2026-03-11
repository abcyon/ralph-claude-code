#!/bin/bash
set -euo pipefail

REPO="abcyon/ralph-claude-code"
BRANCH="main"
TARGET="$HOME/.claude"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Ralph Wiggum Workflow — Claude Code Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# curl로 실행됐는지 로컬 클론에서 실행됐는지 판단
SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_SRC="$SCRIPT_PATH/dot-claude"

if [ -d "$LOCAL_SRC" ]; then
    # 로컬 클론에서 실행
    MODE="local"
    echo "→ Mode: local clone"
else
    # curl 파이프로 실행 — GitHub에서 직접 다운로드
    MODE="curl"
    echo "→ Mode: remote (downloading from GitHub...)"

    # 임시 디렉토리에 다운로드
    TMP_DIR=$(mktemp -d)
    trap "rm -rf $TMP_DIR" EXIT

    BASE_URL="https://raw.githubusercontent.com/$REPO/$BRANCH/dot-claude"

    download() {
        local path="$1"
        local dest="$2"
        mkdir -p "$(dirname "$dest")"
        curl -fsSL "$BASE_URL/$path" -o "$dest"
    }

    echo "→ Downloading files..."
    download "CLAUDE.md"                          "$TMP_DIR/CLAUDE.md"
    download "commands/ralph-spec.md"             "$TMP_DIR/commands/ralph-spec.md"
    download "commands/ralph-setup.md"            "$TMP_DIR/commands/ralph-setup.md"
    download "commands/ralph-plan.md"             "$TMP_DIR/commands/ralph-plan.md"
    download "commands/ralph-loop.md"             "$TMP_DIR/commands/ralph-loop.md"
    download "ralph/spec-principles.md"           "$TMP_DIR/ralph/spec-principles.md"
    download "ralph/prompt-templates.md"          "$TMP_DIR/ralph/prompt-templates.md"
    download "ralph/loop-scripts.md"              "$TMP_DIR/ralph/loop-scripts.md"
    download "ralph/backpressure.md"              "$TMP_DIR/ralph/backpressure.md"
    download "ralph/slc-release.md"               "$TMP_DIR/ralph/slc-release.md"

    LOCAL_SRC="$TMP_DIR"
fi

# ~/.claude 디렉토리 생성
mkdir -p "$TARGET/ralph"
mkdir -p "$TARGET/commands"

# ralph/ 참조 파일 복사 (항상 최신으로 덮어씀)
echo "→ Copying ralph reference files..."
cp -r "$LOCAL_SRC/ralph/." "$TARGET/ralph/"

# 슬래시 커맨드 복사 (항상 최신으로 덮어씀)
echo "→ Copying slash commands..."
cp "$LOCAL_SRC/commands/"*.md "$TARGET/commands/"

# CLAUDE.md — 기존 파일이 있으면 병합, 없으면 새로 설치
if [ -f "$TARGET/CLAUDE.md" ]; then
    if grep -q "Ralph Wiggum Workflow" "$TARGET/CLAUDE.md"; then
        echo "→ Updating Ralph section in CLAUDE.md..."
        # Remove existing Ralph section (from "# Ralph Wiggum Workflow" to end of file or next top-level section)
        # Strategy: delete the Ralph block and re-append the latest version
        # Uses awk to handle both mid-file and last-section cases (sed range fails at EOF)
        awk '
            /^# Ralph Wiggum Workflow$/ { skip=1; next }
            skip && /^# / { skip=0 }
            !skip { print }
        ' "$TARGET/CLAUDE.md" > "$TARGET/CLAUDE.md.tmp"
        mv "$TARGET/CLAUDE.md.tmp" "$TARGET/CLAUDE.md"
        # Remove trailing blank lines
        sed -i.bak -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$TARGET/CLAUDE.md"
        printf "\n---\n\n" >> "$TARGET/CLAUDE.md"
        cat "$LOCAL_SRC/CLAUDE.md" >> "$TARGET/CLAUDE.md"
        rm -f "$TARGET/CLAUDE.md.bak"
        echo "  ✓ Updated Ralph section in CLAUDE.md"
    else
        echo "→ Appending Ralph section to existing CLAUDE.md..."
        printf "\n---\n\n" >> "$TARGET/CLAUDE.md"
        cat "$LOCAL_SRC/CLAUDE.md" >> "$TARGET/CLAUDE.md"
        echo "  ✓ Appended to existing CLAUDE.md"
    fi
else
    echo "→ Installing CLAUDE.md..."
    cp "$LOCAL_SRC/CLAUDE.md" "$TARGET/CLAUDE.md"
    echo "  ✓ Created ~/.claude/CLAUDE.md"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Installation complete!"
echo ""
echo "Usage in Claude Code:"
echo "  /ralph-spec    — 대화로 specs/ 작성 (새 프로젝트 / 기능 추가 / 기능 변경 / 버그 픽스)"
echo "  /ralph-setup   — 프로젝트 초기 구성 (loop.sh + PROMPT_*.md + AGENTS.md)"
echo "  /ralph-plan    — Claude Code 내에서 plan 실행 (기본 1회)"
echo "  /ralph-loop    — Claude Code 내에서 build 실행 (기본 5회)"
echo ""
echo "Then in terminal:"
echo "  ./loop.sh plan   # IMPLEMENTATION_PLAN.md 생성"
echo "  ./loop.sh        # 무한 빌드 (무개입)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
