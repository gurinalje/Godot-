# ADR-0002: Event Bus Architecture

> **Status**: Accepted  
> **Date**: 2026-06-03  
> **Deciders**: Technical Director, Lead Programmer

---

## Context

《命运卡牌局》有29个系统需要相互通信。系统间通信方式需要平衡松耦合和性能。

**Key Requirements**:
- 系统间需要松耦合通信
- 避免循环依赖
- 支持跨层通信
- 性能要好（60FPS）

---

## Decision

采用**混合通信策略**：
1. **全局事件总线 (Autoload)** — 用于跨层通信
2. **直接信号** — 用于同层/父子关系通信
3. **直接方法调用** — 用于紧耦合系统（性能关键）

### 事件总线设计

```
EventBus (Autoload)
├─ signals/
│  ├─ battle_started(enemy_id: String)
│  ├─ battle_ended(result: BattleResult)
│  ├─ choice_made(choice_id: String, option: int)
│  ├─ story_mark_added(mark_type: MarkType)
│  ├─ world_unlocked(world_id: String)
│  ├─ card_played(card: CardData)
│  ├─ damage_dealt(amount: int, target: Node)
│  └─ ...
```

### 通信规则

| 场景 | 方式 | 示例 |
|------|------|------|
| 跨层通信 | EventBus | 战斗系统 → UI系统 |
| 同层通信 | 直接信号 | 伤害计算 → 状态效果 |
| 父子通信 | 直接方法 | 战斗管理器 → 卡牌实体 |
| 性能关键 | 直接方法 | 伤害计算内部 |

---

## Consequences

### 正面影响
- ✅ 系统间松耦合
- ✅ 避免循环依赖
- ✅ 易于调试（EventBus可记录事件）
- ✅ 符合Godot信号最佳实践

### 负面影响
- ⚠️ EventBus可能成为性能瓶颈
- ⚠️ 事件流难以追踪
- ⚠️ 需要管理信号连接生命周期

### 风险缓解
- 限制EventBus事件数量
- 提供事件调试工具
- 使用弱引用避免内存泄漏

---

## ADR Dependencies

- 无（基础ADR）

---

## Engine Compatibility

| 特性 | Godot 4.6.3 | 风险 |
|------|-------------|------|
| Signal | ✅ 稳定 | 低 |
| Autoload | ✅ 稳定 | 低 |
| Callable | ✅ 稳定 | 低 |

---

## GDD Requirements Addressed

| Requirement ID | GDD | System |
|----------------|-----|--------|
| TR-combat-001 | 卡牌战斗系统 | 战斗事件广播 |
| TR-choice-001 | 选择系统 | 选择事件广播 |
| TR-story-001 | 剧情追踪系统 | 剧情事件广播 |

---

## Implementation Notes

```gdscript
# event_bus.gd (Autoload)
extends Node

# 战斗事件
signal battle_started(enemy_id: String)
signal battle_ended(result: BattleResult)
signal card_played(card: CardData)
signal damage_dealt(amount: int, target: Node)

# 选择事件
signal choice_made(choice_id: String, option: int)
signal story_mark_added(mark_type: MarkType)

# 世界事件
signal world_unlocked(world_id: String)
signal area_entered(area_id: String)

# UI事件
signal ui_shown(ui_name: String)
signal ui_hidden(ui_name: String)

# 调试模式
var _debug_mode: bool = false

func emit_signal(signal_name: StringName, ...) -> void:
    if _debug_mode:
        print("[EventBus] ", signal_name, " ", args)
    super.emit_signal(signal_name, ...)
```
