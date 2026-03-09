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
| `/ralph-setup` | 프로젝트 초기 구성 시 | loop.sh, PROMPT_plan/build.md, AGENTS.md 생성 |

After spec, run in terminal:
```
# 새 프로젝트라면 먼저
/ralph-setup     # loop.sh, PROMPT 파일, AGENTS.md 생성

# 이후 (또는 기존 프로젝트라면 바로)
./loop.sh plan   # IMPLEMENTATION_PLAN.md 생성
./loop.sh        # 무한 빌드 (무개입)
```

## Reference (load on demand)
- Spec principles → `@~/.claude/ralph/spec-principles.md`
- Prompt templates → `@~/.claude/ralph/prompt-templates.md`
- loop.sh script → `@~/.claude/ralph/loop-scripts.md`
- Backpressure → `@~/.claude/ralph/backpressure.md`
