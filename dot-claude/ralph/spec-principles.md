# Ralph Spec Writing Principles

## JTBD → Topics of Concern → Specs

- 1 JTBD → multiple Topics of Concern
- 1 Topic of Concern → 1 spec file
- 1 spec → multiple tasks in IMPLEMENTATION_PLAN.md

**Topic scope test — "One sentence without 'and'?"**
- ✅ "User authentication system"
- ✅ "Dashboard data visualization"
- ❌ "User system" — too broad (auth + profile + settings mixed)
- ❌ "Login and payment and dashboard" — needs splitting

## Spec File Structure

```
specs/
├── overview.md       # Entry point: goal + tech stack + Non-goals (REQUIRED)
├── auth.md           # One topic of concern per file
├── dashboard.md
└── payment.md
```

**overview.md is special** — Ralph reads this first every loop. Must include:
- Project goal
- Tech stack decision
- Key feature list
- Non-goals (what we are NOT building)

**Feature-based (recommended) vs Layer-based (avoid):**
```
✅ specs/auth.md, specs/dashboard.md, specs/payment.md
❌ specs/api.md, specs/frontend.md, specs/database.md
```
Exception: 3 or fewer features → layer-based is fine if each file stays under 200 lines.

## Each Spec File Principles
- Detailed enough that a developer can implement without questions
- Concrete examples, no ambiguity
- Testable acceptance criteria
- **Never specify how to implement** — how is Ralph's decision

## Tech Stack Decision Checklist
Confirm before writing specs:
- Experience level (beginner / intermediate / expert)
- Preferred language/framework (if any)
- Deploy environment (Vercel, AWS, self-hosted, etc.)
- Expected scale (users, data volume)

Record the final decision in `specs/overview.md`.

## Spec Validation (5 angles — check before running loop)
Fix specs and regenerate plan if issues found:

1. **Completeness** — Missing features, undefined behaviors
2. **Consistency** — Contradictions between specs, terminology mismatches
3. **Feasibility** — Impossible or unrealistic performance requirements
4. **Testability** — Are acceptance criteria clear and verifiable?
5. **Dependencies** — Clear dependency order, no circular dependencies
