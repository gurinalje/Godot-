# Epic: summon-system

> **Layer**: core
> **GDD**: game/design/gdd/summon-system.md
> **Status**: Ready
> **Stories**: Not yet created â€?run `/create-stories summon-system`

## Overview

This epic implements the summon-system system as defined in the GDD.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0001 | Godot Engine Selection | LOW |
| ADR-0002 | GDScript Primary Language | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-summon-system-001 | Core implementation | ADR-0001 âœ?|
| TR-summon-system-002 | Integration with dependent systems | ADR-0002 âœ?|

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from the GDD are verified
- All Logic and Integration stories have passing test files in `tests/`

## Next Step

Run `/create-stories summon-system` to break this epic into implementable stories.
