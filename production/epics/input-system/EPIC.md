# Epic: 输入系统

> **Layer**: Foundation  
> **GDD**: design/gdd/input-system.md  
> **Architecture Module**: InputSystem  
> **Status**: Ready  
> **Stories**: Not yet created — run `/create-stories input-system`

## Overview

输入系统是游戏的基础设施层，负责处理玩家输入和映射。系统使用Godot InputMap，支持键鼠/手柄双模式，提供输入缓冲和上下文管理。输入系统是所有交互系统的基础，因为所有玩家操作都需要通过输入系统处理。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0002: Event Bus Architecture | 使用全局EventBus进行跨层通信 | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-input-001 | 默认键位映射（9个动作） | ❌ No ADR |
| TR-input-002 | 输入缓冲机制（100ms窗口） | ❌ No ADR |
| TR-input-003 | 上下文管理（菜单>对话>战斗>探索） | ❌ No ADR |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/input-system.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

Run `/create-stories input-system` to break this epic into implementable stories.
