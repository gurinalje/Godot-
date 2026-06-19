---
name: create-stories
description: "Break a single epic into implementable story files. Reads the epic, its GDD, governing ADRs, and control manifest. Each story embeds its GDD requirement TR-ID, ADR guidance, acceptance criteria, story type, and test evidence path. Run after /create-epics for each epic."
argument-hint: "[epic-slug | epic-path] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Task, question
agent: lead-programmer
---

# Create Stories

A story is a single implementable behaviour â€?small enough to complete in one
focused session, self-contained, and fully traceable to a GDD requirement and
an ADR decision. Stories are what developers pick up. Epics are what architects
define.

**Run this skill per epic**, not per layer. Run it for Foundation epics first,
then Core, and so on â€?matching the dependency order.

**Output:** `production/epics/[epic-slug]/story-NNN-[slug].md` files

**Previous step:** `/create-epics [system]`
**Next step after stories exist:** `/story-readiness [story-path]` then `/dev-story [story-path]`

---

## 1. Parse Argument

Extract `--review [full|lean|solo]` if present and store as the review mode
override for this run. If not provided, read `production/review-mode.txt`
(default `full` if missing). This resolved mode applies to all gate spawns
in this skill â€?apply the check pattern from `.opencode/docs/director-gates.md`
before every gate invocation.

- `/create-stories [epic-slug]` â€?e.g. `/create-stories combat`
- `/create-stories production/epics/combat/EPIC.md` â€?full path also accepted
- No argument â€?ask: "Which epic would you like to break into stories?"
  Glob `production/epics/*/EPIC.md` and list available epics with their status.

---

## 2. Load Everything for This Epic

Read in full:

- `production/epics/[epic-slug]/EPIC.md` â€?epic overview, governing ADRs, GDD requirements table
- The epic's GDD (`game/design/gdd/[filename].md`) â€?read all 8 sections, especially Acceptance Criteria, Formulas, and Edge Cases
- All governing ADRs listed in the epic â€?read the Decision, Implementation Guidelines, Engine Compatibility, and Engine Notes sections
- `docs/architecture/control-manifest.md` â€?extract rules for this epic's layer; note the Manifest Version date from the header
- `docs/architecture/tr-registry.yaml` â€?load all TR-IDs for this system

**ADR existence validation**: After reading the governing ADRs list from the epic, confirm each ADR file exists on disk. If any ADR file cannot be found, **stop immediately** before decomposing any story:

> "Epic references [ADR-NNNN: title] but `docs/architecture/[adr-file].md` was not found.
> Check the filename in the epic's Governing ADRs list, or run `/architecture-decision`
> to create it. Cannot create stories until all referenced ADR files are present."

Do not proceed to Step 3 until all referenced ADR files are confirmed present.

Report: "Loaded epic [name], GDD [filename], [N] governing ADRs (all confirmed present), control manifest v[date]."

---

## 3. Classify Stories by Type

**Story Type Classification** â€?assign each story a type based on its acceptance criteria:

| Story Type | Assign when criteria reference... |
|---|---|
| **Logic** | Formulas, numerical thresholds, state transitions, AI decisions, calculations |
| **Integration** | Two or more systems interacting, signals crossing boundaries, save/load round-trips |
| **Visual/Feel** | Animation behaviour, VFX, "feels responsive", timing, screen shake, audio sync |
| **UI** | Menus, HUD elements, buttons, screens, dialogue boxes, tooltips |
| **Config/Data** | Balance tuning values, data file changes only â€?no new code logic |

Mixed stories: assign the type that carries the highest implementation risk.
The type determines what test evidence is required before `/story-done` can close the story.

---

## 4. Decompose the GDD into Stories

For each GDD acceptance criterion:

1. Group related criteria that require the same core implementation
2. Each group = one story
3. Order stories: foundational behaviour first, edge cases last, UI last

**Story sizing rule:** one story = one focused session (~2-4 hours). If a
group of criteria would take longer, split into two stories.

For each story, determine:
- **GDD requirement**: which acceptance criterion(ia) does this satisfy?
- **TR-ID**: look up in `tr-registry.yaml`. Use the stable ID. If no match, use `TR-[system]-???` and warn.
- **Governing ADR**: which ADR governs how to implement this?
  - `Status: Accepted` â†?embed normally
  - `Status: Proposed` â†?set story `Status: Blocked` with note: "BLOCKED: ADR-NNNN is Proposed â€?run `/architecture-decision` to advance it"
- **Story Type**: from Step 3 classification
- **Engine risk**: from the ADR's Knowledge Risk field

---

## 4b. QA Lead Story Readiness Gate

**Review mode check** â€?apply before spawning QL-STORY-READY:
- `solo` â†?skip. Note: "QL-STORY-READY skipped â€?Solo mode." Proceed to Step 5 (present stories for review).
- `lean` â†?skip (not a PHASE-GATE). Note: "QL-STORY-READY skipped â€?Lean mode." Proceed to Step 5 (present stories for review).
- `full` â†?spawn as normal.

After decomposing all stories (Step 4 complete) but before presenting them for write approval, spawn `qa-lead` via Task using gate **QL-STORY-READY** (`.opencode/docs/director-gates.md`).

Pass: the full story list with acceptance criteria, story types, and TR-IDs; the epic's GDD acceptance criteria for reference.

Present the QA lead's assessment. For each story flagged as GAPS or INADEQUATE, revise the acceptance criteria before proceeding â€?stories with untestable criteria cannot be implemented correctly. Once all stories reach ADEQUATE, proceed.

**After ADEQUATE**: for every Logic and Integration story, ask the qa-lead to produce concrete test case specifications â€?one per acceptance criterion â€?in this format:

```
Test: [criterion text]
  Given: [precondition]
  When: [action]
  Then: [expected result / assertion]
  Edge cases: [boundary values or failure states to test]
```

For Visual/Feel and UI stories, produce manual verification steps instead:
```
Manual check: [criterion text]
  Setup: [how to reach the state]
  Verify: [what to look for]
  Pass condition: [unambiguous pass description]
```

These test case specs are embedded directly into each story's `## QA Test Cases` section. The developer implements against these cases. The programmer does not write tests from scratch â€?QA has already defined what "done" looks like.

---

## 5. Present Stories for Review

Before writing any files, present the full story list:

```
## Stories for Epic: [name]

Story 001: [title] â€?Logic â€?ADR-NNNN
  Covers: TR-[system]-001 ([1-line summary of requirement])
  Test required: game/tests/unit/[system]/[slug]_test.[ext]

Story 002: [title] â€?Integration â€?ADR-MMMM
  Covers: TR-[system]-002, TR-[system]-003
  Test required: game/tests/integration/[system]/[slug]_test.[ext]

Story 003: [title] â€?Visual/Feel â€?ADR-NNNN
  Covers: TR-[system]-004
  Evidence required: production/qa/evidence/[slug]-evidence.md

[N stories total: N Logic, N Integration, N Visual/Feel, N UI, N Config/Data]
```

Use `question`:
- Prompt: "May I write these [N] stories to `production/epics/[epic-slug]/`?"
- Options: `[A] Yes â€?write all [N] stories` / `[B] Not yet â€?I want to review or adjust first`

---

## 6. Write Story Files

For each story, write `production/epics/[epic-slug]/story-[NNN]-[slug].md`:

```markdown
# Story [NNN]: [title]

> **Epic**: [epic name]
> **Status**: Ready
> **Layer**: [Foundation / Core / Feature / Presentation]
> **Type**: [Logic | Integration | Visual/Feel | UI | Config/Data]
> **Manifest Version**: [date from control-manifest.md header]

## Context

**GDD**: `game/design/gdd/[filename].md`
**Requirement**: `TR-[system]-NNN`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` â€?read fresh at review time)*

**ADR Governing Implementation**: [ADR-NNNN: title]
**ADR Decision Summary**: [1-2 sentence summary of what the ADR decided]

**Engine**: [name + version] | **Risk**: [LOW / MEDIUM / HIGH]
**Engine Notes**: [from ADR Engine Compatibility section â€?post-cutoff APIs, verification required]

**Control Manifest Rules (this layer)**:
- Required: [relevant required pattern]
- Forbidden: [relevant forbidden pattern]
- Guardrail: [relevant performance guardrail]

---

## Acceptance Criteria

*From GDD `game/design/gdd/[filename].md`, scoped to this story:*

- [ ] [criterion 1 â€?directly from GDD]
- [ ] [criterion 2]
- [ ] [performance criterion if applicable]

---

## Implementation Notes

*Derived from ADR-NNNN Implementation Guidelines:*

[Specific, actionable guidance from the ADR. Do not paraphrase in ways that
change meaning. This is what the programmer reads instead of the ADR.]

---

## Out of Scope

*Handled by neighbouring stories â€?do not implement here:*

- [Story NNN+1]: [what it handles]

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these â€?do not invent new test cases during implementation.*

**[For Logic / Integration stories â€?automated test specs]:**

- **AC-1**: [criterion text]
  - Given: [precondition]
  - When: [action]
  - Then: [assertion]
  - Edge cases: [boundary values / failure states]

**[For Visual/Feel / UI stories â€?manual verification steps]:**

- **AC-1**: [criterion text]
  - Setup: [how to reach the state]
  - Verify: [what to look for]
  - Pass condition: [unambiguous pass description]

---

## Test Evidence

**Story Type**: [type]
**Required evidence**:
- Logic: `game/tests/unit/[system]/[story-slug]_test.[ext]` â€?must exist and pass
- Integration: `game/tests/integration/[system]/[story-slug]_test.[ext]` OR playtest doc
- Visual/Feel: `production/qa/evidence/[story-slug]-evidence.md` + sign-off
- UI: `production/qa/evidence/[story-slug]-evidence.md` or interaction test
- Config/Data: smoke check pass (`production/qa/smoke-*.md`)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: [Story NNN-1 must be DONE, or "None"]
- Unlocks: [Story NNN+1, or "None"]
```

### Also update `production/epics/[epic-slug]/EPIC.md`

Replace the "Stories: Not yet created" line with a populated table:

```markdown
## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [title] | Logic | Ready | ADR-NNNN |
| 002 | [title] | Integration | Ready | ADR-MMMM |
```

---

## 7. After Writing

Use `question` to close with context-aware next steps:

Check:
- Are there other epics in `production/epics/` without stories yet? List them.
- Is this the last epic? If so, include `/sprint-plan` as an option.

Widget:
- Prompt: "[N] stories written to `production/epics/[epic-slug]/`. What next?"
- Options (include all that apply):
  - `[A] Start implementing â€?run /story-readiness [first-story-path]` (Recommended)
  - `[B] Create stories for [next-epic-slug] â€?run /create-stories [slug]` (only if other epics have no stories yet)
  - `[C] Plan the sprint â€?run /sprint-plan` (only if all epics have stories)
  - `[D] Stop here for this session`

Note in output: "Work through stories in order â€?each story's `Depends on:` field tells you what must be DONE before you can start it."

---

## Collaborative Protocol

1. **Read before presenting** â€?load all inputs silently before showing the story list
2. **Ask once** â€?present all stories for the epic in one summary, not one at a time
3. **Warn on blocked stories** â€?flag any story with a Proposed ADR before writing
4. **Ask before writing** â€?get approval for the full story set before writing files
5. **No invention** â€?acceptance criteria come from GDDs, implementation notes from ADRs, rules from the manifest
6. **Never start implementation** â€?this skill stops at the story file level

After writing (or declining):

- **Verdict: COMPLETE** â€?[N] stories written to `production/epics/[epic-slug]/`. Run `/story-readiness` â†?`/dev-story` to begin implementation.
- **Verdict: BLOCKED** â€?user declined. No story files written.
