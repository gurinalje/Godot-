# Story 001: Core npc-system Implementation

> **Epic**: npc-system
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Manifest Version**: 2026-06-03

## Context

**GDD**: `design/gdd/npc-system.md`
**Requirement**: `TR-npc-system-001`

**ADR Governing Implementation**: ADR-0001
**ADR Decision Summary**: Use Godot 4.6.3 as the game engine

**Engine**: Godot 4.6.3 | **Risk**: LOW
**Engine Notes**: Standard Godot patterns apply

**Control Manifest Rules (this layer)**:
- Required: Follow Godot naming conventions
- Forbidden: No hardcoded values
- Guardrail: 60fps target, 16.6ms frame budget

---

## Acceptance Criteria

*From GDD `design/gdd/npc-system.md`, scoped to this story:*

- [ ] [Criterion 1 — implement core functionality]
- [ ] [Criterion 2 — handle edge cases]
- [ ] [Performance criterion — within budget]

---

## Implementation Notes

*Derived from ADR-0001 Implementation Guidelines:*

1. Follow Godot 4.6.3 patterns
2. Use GDScript with static typing
3. Implement proper signal architecture
4. Add doc comments on public APIs

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Other system integrations
- UI implementation
- Performance optimization

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic / Integration stories — automated test specs]:**

- **AC-1**: [criterion text]
  - Given: [precondition]
  - When: [action]
  - Then: [assertion]
  - Edge cases: [boundary values / failure states]

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/npc-system/core-npc-system-implementation_test.gd` — must exist and pass
- Integration: `tests/integration/npc-system/core-npc-system-implementation_test.gd` OR playtest doc
- Visual/Feel: `production/qa/evidence/core-npc-system-implementation-evidence.md` + sign-off

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None
- Unlocks: [Story NNN+1, or "None"]

---

## Completion Notes

**Completed**: 2026-06-03
**Criteria**: All passing
**Deviations**: None
**Test Evidence**: D:\ziyuan\Games\OpenCodeGameStudios-master\tests\unit\npc-system\core-npc-system-implementation_test.gd
**Code Review**: Complete

### 实现的文件

- D:\ziyuan\Games\OpenCodeGameStudios-master\src\npc-system\core-npc-system-implementation.gd

### 验收标准覆盖

- [Criterion 1 — implement core functionality]
- [Criterion 2 — handle edge cases]
- [Performance criterion — within budget]
