# Ralph Wiggum Workflow — Claude Code Setup

Claude Code에서 Ralph Wiggum Technique을 바로 쓸 수 있는 글로벌 설정 패키지.

## 설치

**curl (권장):**
```bash
curl -fsSL https://raw.githubusercontent.com/abcyon/ralph-claude-code/main/install.sh | bash
```

**git clone:**
```bash
git clone https://github.com/abcyon/ralph-claude-code
cd ralph-claude-code && ./install.sh
```

**zip 다운로드:**
```bash
unzip ralph-claude-code.zip
cd ralph-claude-code && ./install.sh
```

---

## 사용 흐름

```
1. /ralph-spec     대화로 JTBD 파악 → specs/ 작성 + 자동 검증
2. /ralph-setup    loop.sh, PROMPT_*.md, AGENTS.md 생성
3. ./loop.sh plan  IMPLEMENTATION_PLAN.md 생성
4. ./loop.sh       무한 빌드 (무개입)
```

---

## 슬래시 커맨드

| 커맨드 | 역할 |
|---|---|
| `/ralph-spec` | JTBD 파악 → specs 작성 → 자동 검증 및 수정 |
| `/ralph-setup` | 루프 실행에 필요한 파일 일괄 생성 |
| `/ralph-plan [n]` | Claude Code 내에서 plan 실행 (기본 1회) |
| `/ralph-loop [n]` | Claude Code 내에서 build 실행 (기본 5회) |

---

## 새 프로젝트 전체 흐름

```bash
# 1. 프로젝트 초기화
mkdir my-project && cd my-project
git init
git commit --allow-empty -m "initial commit"
git remote add origin [REPO_URL]
git push -u origin main

# 2. Claude Code 열기
claude

# 3. 요구사항 정의 (대화)
/ralph-spec

# 4. 루프 파일 생성
/ralph-setup

# 5. 터미널에서 루프 실행
./loop.sh plan
./loop.sh
```

---

## 재설치 / 업데이트

```bash
curl -fsSL https://raw.githubusercontent.com/abcyon/ralph-claude-code/main/install.sh | bash
```

`~/.claude/ralph/` 와 `~/.claude/commands/` 는 항상 최신으로 덮어씁니다.
기존 `CLAUDE.md`가 있으면 Ralph 섹션만 추가합니다.

---

## 설치 위치

```
~/.claude/
├── CLAUDE.md
├── commands/
│   ├── ralph-spec.md
│   ├── ralph-setup.md
│   ├── ralph-plan.md
│   └── ralph-loop.md
└── ralph/
    ├── spec-principles.md
    ├── prompt-templates.md
    ├── loop-scripts.md
    ├── backpressure.md
    └── slc-release.md
```

---

> Based on the [Ralph Wiggum Technique](https://github.com/ghuntley/how-to-ralph-wiggum) by Geoffrey Huntley.
