# Epic: ui-system

> **Layer**: core
> **GDD**: design/gdd/ui-system.md
> **Status**: Ready
> **Stories**: Not yet created — run `/create-stories ui-system`

## Overview

This epic implements the ui-system system as defined in the GDD.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0001 | Godot Engine Selection | LOW |
| ADR-0002 | GDScript Primary Language | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-ui-system-001 | Core implementation | ADR-0001 ✅ |
| TR-ui-system-002 | Integration with dependent systems | ADR-0002 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from the GDD are verified
- All Logic and Integration stories have passing test files in `tests/`

## Next Step

Run `/create-stories ui-system` to break this epic into implementable stories.
