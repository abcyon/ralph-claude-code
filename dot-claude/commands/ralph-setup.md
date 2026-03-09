@~/.claude/ralph/prompt-templates.md 와 @~/.claude/ralph/loop-scripts.md 를 참고해서 이 프로젝트 루트에 아래 파일들을 생성해줘.

1. `loop.sh` — loop-scripts.md의 Enhanced Loop 스크립트 그대로 복사
2. `PROMPT_plan.md` — prompt-templates.md의 PROMPT_plan.md 템플릿에서 [PROJECT GOAL]을 specs/overview.md 내용 기반으로 채워서
3. `PROMPT_build.md` — prompt-templates.md의 PROMPT_build.md 템플릿 그대로 복사
4. `AGENTS.md` — 현재 프로젝트 기술스택(specs/overview.md 참고)에 맞는 빌드/테스트/lint 명령어로 채워서. 60줄 이내.

모든 파일 생성 후:
- `chmod +x loop.sh` 실행
- 생성된 파일 목록과 다음 실행 명령어를 알려줄 것:
  ```
  ./loop.sh plan   # IMPLEMENTATION_PLAN.md 생성
  ./loop.sh        # 무한 빌드 시작
  ```
