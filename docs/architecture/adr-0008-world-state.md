# ADR-0008: World State Persistence

> **Status**: Accepted  
> **Date**: 2026-06-03  
> **Deciders**: Technical Director, Lead Programmer

---

## Context

《命运卡牌局》有多个世界和区域，需要持久化保存世界状态和进度。

**Key Requirements**:
- 支持多世界状态管理
- 支持区域解锁/完成状态
- 支持隐藏内容发现状态
- 支持存档/读档

---

## Decision

使用**分层状态管理**，世界状态存储在Resource中，通过存档系统序列化。

### 世界状态结构

```gdscript
# world_state.gd
class_name WorldState
extends Resource

@export var world_id: String = ""
@export var unlocked: bool = false
@export var completed: bool = false
@export var completion_percentage: float = 0.0
@export var areas: Dictionary = {}  # area_id -> AreaState
@export var discovered_hidden: Array[String] = []
@export var unlocked_cards: Array[String] = []
```

### 区域状态结构

```gdscript
# area_state.gd
class_name AreaState
extends Resource

@export var area_id: String = ""
@export var unlocked: bool = false
@export var explored: bool = false
@export var completed: bool = false
@export var nodes_visited: Array[String] = []
@export var nodes_discovered: Array[String] = []
@export var current_node: String = ""
```

### 状态持久化流程

```
游戏状态变更
    ↓
WorldStateSystem._update_state()
    ↓
标记为"脏"（需要保存）
    ↓
SaveSystem.save_game()
    ↓
序列化为JSON
    ↓
写入文件
```

---

## Consequences

### 正面影响
- ✅ 世界状态管理清晰
- ✅ 支持复杂解锁条件
- ✅ 易于扩展新世界
- ✅ 支持存档/读档

### 负面影响
- ⚠️ 状态数据可能很大
- ⚠️ 需要管理状态版本
- ⚠️ 调试困难

### 风险缓解
- 使用增量保存减少数据量
- 实现状态版本迁移
- 提供状态调试工具

---

## ADR Dependencies

- ADR-0003 (Save/Load Serialization) — 存档格式
- ADR-0004 (Card Data Structure) — Resource格式

---

## Engine Compatibility

| 特性 | Godot 4.6.3 | 风险 |
|------|-------------|------|
| Resource | ✅ 稳定 | 低 |
| Dictionary | ✅ 稳定 | 低 |
| JSON | ✅ 稳定 | 低 |

---

## GDD Requirements Addressed

| Requirement ID | GDD | System |
|----------------|-----|--------|
| TR-world-001 | 世界状态系统 | 世界状态管理 |
| TR-world-002 | 世界状态系统 | 区域解锁条件 |
| TR-world-003 | 世界状态系统 | 隐藏内容发现 |

---

## Implementation Notes

```gdscript
# world_state_manager.gd
class_name WorldStateManager
extends Node

var _world_states: Dictionary = {}  # world_id -> WorldState
var _dirty: bool = false

func unlock_world(world_id: String) -> void:
    if _world_states.has(world_id):
        _world_states[world_id].unlocked = true
        _dirty = true
        EventBus.world_unlocked.emit(world_id)

func unlock_area(world_id: String, area_id: String) -> void:
    if _world_states.has(world_id):
        var world_state = _world_states[world_id]
        if world_state.areas.has(area_id):
            world_state.areas[area_id].unlocked = true
            _dirty = true

func visit_node(world_id: String, area_id: String, node_id: String) -> void:
    if _world_states.has(world_id):
        var world_state = _world_states[world_id]
        if world_state.areas.has(area_id):
            var area_state = world_state.areas[area_id]
            if not area_state.nodes_visited.has(node_id):
                area_state.nodes_visited.append(node_id)
                _dirty = true

func serialize() -> Dictionary:
    var data = {}
    for world_id in _world_states:
        data[world_id] = _serialize_world_state(_world_states[world_id])
    return data

func deserialize(data: Dictionary) -> void:
    for world_id in data:
        _world_states[world_id] = _deserialize_world_state(data[world_id])
```
