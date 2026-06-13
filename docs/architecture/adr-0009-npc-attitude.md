# ADR-0009: NPC Attitude System

> **Status**: Accepted  
> **Date**: 2026-06-03  
> **Deciders**: Technical Director, Lead Programmer

---

## Context

《命运卡牌局》有NPC关系系统，需要管理NPC对玩家的态度变化。

**Key Requirements**:
- 支持NPC态度值（-100到+100）
- 支持态度影响对话和价格
- 支持态度变化动画
- 支持态度存档/读档

---

## Decision

使用**数值化态度系统**，NPC态度存储在Resource中。

### NPC态度数据

```gdscript
# npc_attitude.gd
class_name NPCAttitude
extends Resource

@export var npc_id: String = ""
@export var base_attitude: int = 0  # 基础态度 -50~+50
@export var current_attitude: int = 0  # 当前态度 -100~+100
@export var attitude_history: Array[AttitudeChange] = []
@export var unlocked_dialogues: Array[String] = []
@export var unlocked_items: Array[String] = []
```

### 态度影响规则

| 态度范围 | 对话选项 | 价格折扣 | 解锁内容 |
|----------|----------|----------|----------|
| -100 ~ -50 | 敌对 | +50% | 无 |
| -49 ~ -1 | 冷淡 | +20% | 基础对话 |
| 0 ~ 49 | 中立 | 0% | 标准对话 |
| 50 ~ 79 | 友好 | -20% | 额外对话 |
| 80 ~ 100 | 亲密 | -50% | 隐藏对话/物品 |

### 态度变化公式

```
attitude_change = base_value × choice_multiplier × mark_multiplier

base_value: 选择的基础值（-10~+10）
choice_multiplier: 选择乘数（0.5~2.0）
mark_multiplier: 印记乘数（0.8~1.2）
```

---

## Consequences

### 正面影响
- ✅ NPC关系系统清晰
- ✅ 支持复杂关系变化
- ✅ 易于平衡调整
- ✅ 支持存档/读档

### 负面影响
- ⚠️ 态度值可能溢出
- ⚠️ 需要管理态度历史
- ⚠️ 调试困难

### 风险缓解
- 限制态度值范围
- 使用态度历史追踪
- 提供态度调试工具

---

## ADR Dependencies

- ADR-0004 (Card Data Structure) — Resource格式

---

## Engine Compatibility

| 特性 | Godot 4.6.3 | 风险 |
|------|-------------|------|
| Resource | ✅ 稳定 | 低 |
| Signal | ✅ 稳定 | 低 |

---

## GDD Requirements Addressed

| Requirement ID | GDD | System |
|----------------|-----|--------|
| TR-npc-001 | NPC系统 | 态度系统 |
| TR-npc-002 | NPC系统 | 态度影响 |
| TR-npc-003 | NPC系统 | 态度历史 |

---

## Implementation Notes

```gdscript
# npc_attitude_manager.gd
class_name NPCAttitudeManager
extends Node

signal attitude_changed(npc_id: String, old_value: int, new_value: int)

var _attitudes: Dictionary = {}  # npc_id -> NPCAttitude

func change_attitude(npc_id: String, change: int, reason: String = "") -> void:
    if _attitudes.has(npc_id):
        var attitude = _attitudes[npc_id]
        var old_value = attitude.current_attitude
        var new_value = clamp(old_value + change, -100, 100)
        
        attitude.current_attitude = new_value
        attitude.attitude_history.append(AttitudeChange.new(change, reason))
        
        attitude_changed.emit(npc_id, old_value, new_value)
        
        # 检查解锁条件
        _check_unlocks(npc_id, new_value)

func get_attitude(npc_id: String) -> int:
    if _attitudes.has(npc_id):
        return _attitudes[npc_id].current_attitude
    return 0

func get_price_modifier(npc_id: String) -> float:
    var attitude = get_attitude(npc_id)
    if attitude <= -50:
        return 1.5  # +50%
    elif attitude <= -1:
        return 1.2  # +20%
    elif attitude <= 49:
        return 1.0  # 0%
    elif attitude <= 79:
        return 0.8  # -20%
    else:
        return 0.5  # -50%

func _check_unlocks(npc_id: String, attitude: int) -> void:
    # 检查对话解锁
    # 检查物品解锁
    pass
```
