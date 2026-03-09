# JTBD → Story Map → SLC Release

Use this workflow for **product-focused projects** where you want to define audience, map user journeys, and release in SLC slices.

---

## Core Concepts

**SLC = Simple, Lovable, Complete**
- **Simple**: Narrow scope you can ship fast
- **Lovable**: People actually want to use it (not just "minimum viable")
- **Complete**: Fully accomplishes a job within its scope — not a broken preview

*Why SLC over MVP?* MVPs optimize for learning at the customer's expense. SLC delivers real value while learning.

---

## Workflow

### Phase 1a — Define Audience & JTBDs

Create `AUDIENCE_JTBD.md`:

```markdown
## Audience: [Name]
Who they are and context.

### Jobs to Be Done
- JTBD 1: [Outcome they want to achieve]
- JTBD 2: ...
```

### Phase 1b — Define Activities (Topics of Concern)

For each JTBD, identify **activities** (verbs in a user journey, not capabilities):

| Topics of Concern (capability) | Activities (journey) |
|---|---|
| "color extraction system" | "see extracted colors" |
| "layout engine" | "arrange layout" |
| "upload module" | "upload photo" |

For each activity, determine:
- **Capability depths**: basic → enhanced → advanced
- **Desired outcome** at each depth

Create one `specs/[activity-name].md` per activity.

### Phase 2 — Story Map

Arrange activities as columns (the journey backbone), capability depths as rows:

```
UPLOAD    →   EXTRACT    →   ARRANGE     →   SHARE

basic         auto           manual          export
bulk          palette        templates       collab
batch         AI themes      auto-layout     embed
```

### Phase 3 — Define SLC Slices

Horizontal slices through the story map = candidate releases:

```
                  UPLOAD    →   EXTRACT    →   ARRANGE     →   SHARE

Palette Picker:   basic         auto                           export
                  ─────────────────────────────────────────────────
Mood Board:                     palette        manual
                  ─────────────────────────────────────────────────
Design Studio:    batch         AI themes      templates       embed
```

Each slice should be Simple + Lovable + Complete within its scope.

---

## SLC Planning Prompt

Use this variant of `PROMPT_plan.md` to have Ralph recommend the next SLC release:

```
0a. Study @AUDIENCE_JTBD.md to understand who we're building for and their Jobs to Be Done.
0b. Study `specs/*` with up to 250 parallel Sonnet subagents to learn JTBD activities.
0c. Study @IMPLEMENTATION_PLAN.md (if present) to understand the plan so far.
0d. Study `src/lib/*` with up to 250 parallel Sonnet subagents to understand shared utilities & components.
0e. For reference, the application source code is in `src/*`.

1. Sequence the activities in `specs/*` into a user journey map for the audience in @AUDIENCE_JTBD.md. Consider how activities flow and what dependencies exist.

2. Determine the next SLC release. Use up to 500 Sonnet subagents to compare `src/*` against `specs/*`. Use an Opus subagent with Ultrathink to recommend which activities (at what capability depths) form the most valuable next release. Prefer thin horizontal slices — the narrowest scope that still delivers real value. A good slice is Simple (narrow, achievable), Lovable (people want to use it), and Complete (fully accomplishes a meaningful job, not a broken preview).

3. Use an Opus subagent (ultrathink) to prioritize tasks and create/update @IMPLEMENTATION_PLAN.md as a bullet point list. Begin with a summary of the recommended SLC release (what's included and why), then list prioritized tasks. Note discoveries outside scope as future work.

IMPORTANT: Plan only. Do NOT implement anything. Do NOT assume functionality is missing; confirm with code search first. Treat `src/lib` as the project's standard library.

ULTIMATE GOAL: Recommend and plan the most valuable next SLC release for the audience in @AUDIENCE_JTBD.md.
```

---

## Key Cardinalities

- 1 Audience → many JTBDs
- 1 JTBD → many Activities
- 1 Activity → can serve multiple JTBDs
- 1 Activity → 1 spec file
- 1 Story Map slice → 1 SLC release → 1 `IMPLEMENTATION_PLAN.md`

---

## Why `AUDIENCE_JTBD.md` as Separate File

- Single source of truth — prevents drift across specs
- Enables holistic reasoning: "What does this audience need MOST?"
- Referenced in both spec creation AND SLC planning
- Keeps activity specs focused on WHAT, not repeating WHO
