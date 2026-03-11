# Ralph Wiggum Workflow

This project uses the Ralph Wiggum Technique: **Idea → Specs → Loop**

## Core Rules
- Always read `specs/overview.md` first, then `IMPLEMENTATION_PLAN.md`
- Never assume functionality is missing — search the codebase first
- `AGENTS.md`: operational info only, under 60 lines, no status updates
- Status/progress → `IMPLEMENTATION_PLAN.md`, never `AGENTS.md`
- After implementation: run tests → commit → `git push`
- Plan is disposable: `rm IMPLEMENTATION_PLAN.md` and regenerate anytime

## Commands
| Slash Command | When | What it does |
|---|---|---|
| `/ralph-spec` | 언제든지 | 대화로 specs/ 파일 작성 — 새 프로젝트 / 기능 추가 / 기능 변경 / 버그 픽스 |
| `/ralph-setup` | 프로젝트 초기 구성 시 | loop.sh, status.sh, PROMPT_plan/build/plan_work.md, AGENTS.md 생성 |
| `/ralph-plan [n]` | plan 실행 시 | Claude Code 내에서 loop.sh plan 실행 (기본 1회) |
| `/ralph-loop [n]` | build 실행 시 | Claude Code 내에서 loop.sh 실행 (기본 5회) |

After spec, run in terminal or use slash commands directly:
```
# 새 프로젝트라면 먼저
/ralph-setup     # loop.sh, PROMPT 파일, AGENTS.md 생성

# 터미널 방식
./loop.sh plan   # IMPLEMENTATION_PLAN.md 생성
./loop.sh        # 무한 빌드 (무개입)

# Claude Code 내 방식 (컨텍스트 소모 없음)
/ralph-plan      # IMPLEMENTATION_PLAN.md 생성 (1회)
/ralph-loop      # 빌드 시작 (5회)
```

## Reference (load on demand)
- Spec principles → `@~/.claude/ralph/spec-principles.md`
- Prompt templates → `@~/.claude/ralph/prompt-templates.md`
- loop.sh script → `@~/.claude/ralph/loop-scripts.md`
- Backpressure → `@~/.claude/ralph/backpressure.md`
- SLC release workflow → `@~/.claude/ralph/slc-release.md`
