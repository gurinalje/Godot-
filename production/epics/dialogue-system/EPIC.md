# Epic: dialogue-system

> **Layer**: core
> **GDD**: design/gdd/dialogue-system.md
> **Status**: Ready
> **Stories**: Not yet created — run `/create-stories dialogue-system`

## Overview

This epic implements the dialogue-system system as defined in the GDD.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0001 | Godot Engine Selection | LOW |
| ADR-0002 | GDScript Primary Language | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-dialogue-system-001 | Core implementation | ADR-0001 ✅ |
| TR-dialogue-system-002 | Integration with dependent systems | ADR-0002 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from the GDD are verified
- All Logic and Integration stories have passing test files in `tests/`

## Next Step

Run `/create-stories dialogue-system` to break this epic into implementable stories.
