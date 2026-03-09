# Backpressure Reference

Backpressure = signals that reject invalid work and force Ralph to fix issues before committing.

---

## Standard Backpressure

Wire test/build commands into `AGENTS.md` under `## Validation`. The build prompt says "run tests" generically; `AGENTS.md` makes it project-specific.

```markdown
## Validation
- Tests: `npm test`
- Typecheck: `npx tsc --noEmit`
- Lint: `npx eslint src/`
- Build: `npm run build`
```

---

## Acceptance-Driven Backpressure

Explicitly connect specs → test requirements → implementation.

**In specs:** Define acceptance criteria as behavioral outcomes:
- ✅ "Extracts 5-10 dominant colors from any uploaded image"
- ✅ "Processes images <5MB in <100ms"
- ❌ "Use K-means clustering with LAB color space" (implementation, not acceptance)

**In `PROMPT_plan.md`**, add after the main instruction:
```
For each task in the plan, derive required tests from acceptance criteria in specs — what specific outcomes need verification (behavior, performance, edge cases). Tests verify WHAT works, not HOW it's implemented. Include as part of task definition.
```

**In `PROMPT_build.md`**, add to the guardrail sequence at an **unused number**:

> ⚠️ `999`는 이미 git tag guardrail로 사용 중. 충돌을 피하려면 비어있는 번호를 골라 삽입할 것.
> 기본 템플릿에서 사용 중인 번호: 9, 99, 999, 9999, 99999, 999999, 9999999, 99999999, 999999999, 9999999999, 99999999999
> 예: `9` 앞에 새 guardrail을 추가하거나, 현재 미사용 자리(예: `99`)에 삽입.

```
[비어있는 번호]. Required tests derived from acceptance criteria must exist and pass before committing. Tests are part of implementation scope, not optional.
```

---

## Non-Deterministic Backpressure (LLM-as-Judge)

For subjective acceptance criteria that resist programmatic validation:
- Creative quality (writing tone, narrative flow)
- Aesthetic judgments (visual harmony, design balance)
- UX quality (intuitive navigation, information hierarchy)
- Content appropriateness (context-aware messaging)

### Setup: Create `src/lib/llm-review.ts`

```typescript
interface ReviewResult {
  pass: boolean;
  feedback?: string; // Only when pass=false
}

// Single function, clean API
// artifact: text content OR path to screenshot (.png, .jpg, .jpeg)
// intelligence: 'fast' (default) or 'smart' for nuanced judgment
async function createReview(config: {
  criteria: string;
  artifact: string;
  intelligence?: "fast" | "smart";
}): Promise<ReviewResult>
```

### Create `src/lib/llm-review.test.ts` (Ralph learns from these)

```typescript
import { createReview } from "@/lib/llm-review";

// Text evaluation
test("welcome message tone", async () => {
  const message = generateWelcomeMessage();
  const result = await createReview({
    criteria: "Message uses warm, conversational tone appropriate for design professionals while clearly conveying value proposition",
    artifact: message,
  });
  expect(result.pass).toBe(true);
});

// Vision evaluation (screenshot)
test("dashboard visual hierarchy", async () => {
  await page.screenshot({ path: "./tmp/dashboard.png" });
  const result = await createReview({
    criteria: "Layout demonstrates clear visual hierarchy with obvious primary action",
    artifact: "./tmp/dashboard.png",
  });
  expect(result.pass).toBe(true);
});

// Smart intelligence for complex aesthetic judgment
test("brand visual consistency", async () => {
  await page.screenshot({ path: "./tmp/homepage.png" });
  const result = await createReview({
    criteria: "Visual design maintains professional brand identity suitable for financial services while avoiding corporate sterility",
    artifact: "./tmp/homepage.png",
    intelligence: "smart",
  });
  expect(result.pass).toBe(true);
});
```

Ralph discovers this pattern from `src/lib` exploration (Phase 0c) — no additional prompt changes needed.

**Note on non-determinism:** LLM reviews may give different judgments across runs. This is intentional — eventual consistency through iteration. The loop runs until pass.

---

## Remind Ralph to Use Backpressure

Add to prompts when implementing documentation or complex features:
```
Important: When authoring documentation, capture the why — tests and implementation importance.
```
