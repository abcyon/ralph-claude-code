# Prompt Templates Reference

## `PROMPT_plan.md` 전체 템플릿

> ⚠️ `[PROJECT GOAL]`을 실제 프로젝트 목표로 반드시 교체할 것

```
0a. First, study `specs/overview.md` to understand the project goal and tech stack.
0b. Then study remaining `specs/*` using parallel Sonnet subagents to learn all specifications.
0c. Study @IMPLEMENTATION_PLAN.md (if present) to understand the plan so far.
0d. Study `src/lib/*` using parallel Sonnet subagents to understand shared utilities & components.
0e. For reference, the application source code is in `src/*`.

1. Use parallel Sonnet subagents to study existing source code in `src/*` and compare it against `specs/*`. Use an Opus subagent to analyze findings, prioritize tasks, and create/update @IMPLEMENTATION_PLAN.md as a bullet point list sorted in priority of items yet to be implemented. Ultrathink. Consider searching for TODO, minimal implementations, placeholders, skipped/flaky tests, and inconsistent patterns. Keep @IMPLEMENTATION_PLAN.md up to date with items considered complete/incomplete using subagents.

IMPORTANT: Plan only. Do NOT implement anything. Do NOT assume functionality is missing; confirm with code search first. Treat `src/lib` as the project's standard library. Prefer consolidated, idiomatic implementations there over ad-hoc copies.

ULTIMATE GOAL: [PROJECT GOAL]. If an element is missing, search first to confirm it doesn't exist, then author the spec at specs/FILENAME.md and document the plan in @IMPLEMENTATION_PLAN.md using a subagent.
```

---

## `PROMPT_build.md` 전체 템플릿

> guardrail 번호(9, 99, 999...)는 숫자가 클수록 우선순위가 높은 불변 규칙(invariant). 수정 시 이 순서를 유지할 것.
> ⚠️ **CI/CD 연결 시 주의:** `999` guardrail에 의해 매 성공 루프마다 git tag가 생성된다. tag에 CD 파이프라인이 연결되어 있다면 매 루프마다 배포가 트리거된다. 의도적이지 않다면 `999` guardrail을 제거하거나 CD 파이프라인의 tag 필터를 조정할 것.
> ⚠️ **guardrail 번호 추가 시 주의:** 사용 중인 번호: 9, 99, 999, 9999, 99999, 999999, 9999999, 99999999, 999999999, 9999999999, 99999999999. 새 guardrail은 빈 번호를 골라 삽입할 것.

```
0a. First, study `specs/overview.md` to orient yourself on the project.
0b. Study @IMPLEMENTATION_PLAN.md to identify the most important task.
0c. Study only the spec files relevant to that task using parallel Sonnet subagents.
0d. For reference, the application source code is in `src/*`.

1. Your task is to implement functionality per the specifications using parallel subagents. Follow @IMPLEMENTATION_PLAN.md and choose the most important item to address. Before making changes, search the codebase (don't assume not implemented) using Sonnet subagents. Use only 1 Sonnet subagent for build/tests. Use Opus subagents when complex reasoning is needed (debugging, architectural decisions).
2. After implementing, run the tests for that unit of code. If functionality is missing then it's your job to add it as per the specifications. Ultrathink.
3. When you discover issues, immediately update @IMPLEMENTATION_PLAN.md with your findings using a subagent. When resolved, update and remove the item.
4. When tests pass, update @IMPLEMENTATION_PLAN.md, then `git add -A` then `git commit` with a descriptive message. After the commit, `git push`.

9. Important: When authoring documentation, capture the why — tests and implementation importance.
99. Important: Single sources of truth, no migrations/adapters. If unrelated tests fail, resolve them as part of the increment.
999. As soon as there are no build or test errors, create a git tag. If there are no git tags start at 0.0.0 and increment patch by 1 for example 0.0.1 if 0.0.0 does not exist.
9999. You may add extra logging if required to debug issues.
99999. Keep @IMPLEMENTATION_PLAN.md current with learnings using a subagent. Update especially after finishing your turn.
999999. When you learn something new about how to run the application, update @AGENTS.md using a subagent — keep it under 60 lines and operational only. No status updates here.
9999999. For any bugs you notice, resolve or document them in @IMPLEMENTATION_PLAN.md using a subagent, even if unrelated to current work.
99999999. Implement functionality completely. Placeholders and stubs waste efforts.
999999999. When @IMPLEMENTATION_PLAN.md becomes large, periodically clean out completed items using a subagent.
9999999999. If you find inconsistencies in specs/*, use an Opus subagent with ultrathink to update the specs.
99999999999. IMPORTANT: Keep @AGENTS.md operational only and under 60 lines — status updates belong in IMPLEMENTATION_PLAN.md. A bloated AGENTS.md pollutes every future loop's context.
```

---

## `AGENTS.md` 템플릿

```markdown
# AGENTS.md
# Keep this file under 60 lines. Operational info only — no status updates.

## Build & Run
[프로젝트 실행 방법]

## Validation
- Tests: `[test command]`
- Typecheck: `[typecheck command]`
- Lint: `[lint command]`
- Build: `[build command]`

## Operational Notes
[실행 관련 학습 내용 — 간결하게]

### Codebase Patterns
[Ralph가 따라야 할 코드 패턴 — 간결하게]
```

---

## `PROMPT_plan_work.md` 템플릿

`plan-work` 모드 전용. `loop.sh`가 `${WORK_SCOPE}`를 envsubst로 자동 치환.
→ `references/loop-scripts.md` 참고
