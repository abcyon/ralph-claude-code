# AGENTS.md
# Keep this file under 60 lines. Operational info only — no status updates.

## Project Structure

```
dot-claude/
├── CLAUDE.md                  # 전역 Claude Code 워크플로우 지침
├── commands/                  # 슬래시 커맨드 정의 (*.md)
└── ralph/                     # 레퍼런스 문서
install.sh                     # ~/.claude/ 에 파일 설치
specs/                         # 프로젝트 스펙
```

## Build & Run

이 프로젝트는 Bash + Markdown 기반. 별도 빌드 없음.

설치 테스트:
```bash
bash install.sh   # 로컬 클론에서 설치
```

## Validation

- 슬래시 커맨드 동작: Claude Code에서 `/ralph-spec`, `/ralph-setup`, `/ralph-plan`, `/ralph-loop` 실행
- loop.sh 문법: `bash -n loop.sh`
- install.sh 문법: `bash -n install.sh`

## Operational Notes

- `dot-claude/commands/*.md` — 모두 자동으로 `~/.claude/commands/`에 복사됨 (install.sh 수정 불필요)
- `dot-claude/ralph/*.md` — 레퍼런스 문서, load on demand
- `.ralph_status`, `.ralph_pid`, `*.log` — 런타임 생성 파일, .gitignore 대상

### Codebase Patterns

- 슬래시 커맨드는 Claude에게 주는 Markdown 프롬프트 (실행 로직 없음)
- loop.sh는 `/ralph-setup`이 프로젝트별로 복사하는 템플릿 소스
- install.sh는 local/curl 양방향 실행 지원
