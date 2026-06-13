# Epic: 卡牌数据库

> **Layer**: Foundation  
> **GDD**: design/gdd/card-database.md  
> **Architecture Module**: CardDatabase  
> **Status**: Ready  
> **Stories**: Not yet created — run `/create-stories card-database`

## Overview

卡牌数据库是游戏的卡牌数据定义层，负责管理所有卡牌的定义、属性和效果数据。系统使用Godot Resource系统(.tres)存储卡牌数据，提供查询接口。卡牌数据库是所有卡牌系统的基础，因为所有卡牌相关系统都需要从卡牌数据库获取卡牌数据。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0004: Card Data Structure | 使用Resource系统定义卡牌数据，每张卡牌是一个.tres文件 | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-card-001 | 卡牌数据结构（CardData Resource） | ADR-0004 ✅ |
| TR-card-002 | 四大卡牌类型规则 | ADR-0004 ✅ |
| TR-card-003 | 卡牌生命周期状态机 | ❌ No ADR |
| TR-card-004 | 与8个系统的交互接口 | ❌ No ADR |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/card-database.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

Run `/create-stories card-database` to break this epic into implementable stories.
