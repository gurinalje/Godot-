# Epic: 角色属性系统

> **Layer**: Foundation  
> **GDD**: design/gdd/character-attributes.md  
> **Architecture Module**: CharacterAttributes  
> **Status**: Ready  
> **Stories**: Not yet created — run `/create-stories character-attributes`

## Overview

角色属性系统是游戏的RPG基础层，负责定义玩家角色的核心属性、成长曲线和属性计算规则。系统使用Godot Resource系统存储属性数据，提供属性查询和修改接口。角色属性系统是伤害计算和成长系统的基础。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0004: Card Data Structure | 使用Resource系统存储数据 | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-attr-001 | 6个基础属性（STR/DEX/INT/CON/PER/LCK） | ❌ No ADR |
| TR-attr-002 | 属性计算规则（基础值+装备+Buff+等级） | ❌ No ADR |
| TR-attr-003 | 等级系统（1-100级） | ❌ No ADR |
| TR-attr-004 | 属性上限（149） | ❌ No ADR |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/character-attributes.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

Run `/create-stories character-attributes` to break this epic into implementable stories.
