# ADR-0003: Save/Load Serialization Format

> **Status**: Accepted  
> **Date**: 2026-06-03  
> **Deciders**: Technical Director, Lead Programmer

---

## Context

《命运卡牌局》需要保存玩家进度、卡牌收藏、世界状态等大量数据。需要选择合适的序列化格式。

**Key Requirements**:
- 支持复杂数据结构
- 人类可读（便于调试）
- 文件大小合理
- 跨平台兼容

---

## Decision

采用**JSON格式**进行存档序列化，使用Godot内置的`JSON`类。

### 存档结构

```json
{
  "version": "1.0",
  "timestamp": "2026-06-03T12:00:00",
  "player": {
    "level": 10,
    "experience": 1500,
    "attributes": {
      "strength": 25,
      "dexterity": 20,
      "intelligence": 30,
      "constitution": 22,
      "perception": 18,
      "luck": 15
    },
    "gold": 5000
  },
  "cards": {
    "collection": ["card_001", "card_002", ...],
    "deck": ["card_001", "card_003", ...],
    "levels": {"card_001": 3, "card_002": 1, ...}
  },
  "worlds": {
    "forest": {"unlocked": true, "completed": true},
    "castle": {"unlocked": true, "completed": false},
    ...
  },
  "stories": {
    "main_quest": {"progress": 5, "choices": [...]},
    ...
  },
  "marks": {
    "good": 3,
    "evil": 1,
    "neutral": 2
  }
}
```

### 存档槽管理

| 槽位 | 用途 | 自动保存 |
|------|------|----------|
| Slot 0 | 自动保存 | ✅ |
| Slot 1-5 | 手动保存 | ❌ |

---

## Consequences

### 正面影响
- ✅ 人类可读，便于调试
- ✅ Godot内置支持，无需额外依赖
- ✅ 跨平台兼容
- ✅ 易于版本迁移

### 负面影响
- ⚠️ 文件大小比二进制格式大
- ⚠️ 解析速度比二进制格式慢
- ⚠️ 需要处理版本兼容

### 风险缓解
- 使用gzip压缩减少文件大小
- 实现增量保存减少写入量
- 版本号处理向前兼容

---

## ADR Dependencies

- ADR-0001 (Scene Management) — 场景切换时保存状态

---

## Engine Compatibility

| 特性 | Godot 4.6.3 | 风险 |
|------|-------------|------|
| JSON | ✅ 稳定 | 低 |
| FileAccess | ✅ 稳定 | 低 |
| DirAccess | ✅ 稳定 | 低 |

---

## GDD Requirements Addressed

| Requirement ID | GDD | System |
|----------------|-----|--------|
| TR-save-001 | 存档系统 | 存档格式定义 |
| TR-save-002 | 存档系统 | 存档槽管理 |
| TR-save-003 | 存档系统 | 自动保存机制 |

---

## Implementation Notes

```gdscript
# save_manager.gd (Autoload)
extends Node

const SAVE_DIR = "user://saves/"
const MAX_SLOTS = 6
const AUTO_SAVE_SLOT = 0

func save_game(slot: int) -> bool:
    var save_data = _collect_all_data()
    var json_string = JSON.stringify(save_data, "  ")
    
    var file = FileAccess.open(SAVE_DIR + "slot_%d.json" % slot, FileAccess.WRITE)
    if file:
        file.store_string(json_string)
        file.close()
        return true
    return false

func load_game(slot: int) -> bool:
    var file = FileAccess.open(SAVE_DIR + "slot_%d.json" % slot, FileAccess.READ)
    if file:
        var json_string = file.get_as_text()
        file.close()
        
        var json = JSON.new()
        var error = json.parse(json_string)
        if error == OK:
            _apply_all_data(json.data)
            return true
    return false

func _collect_all_data() -> Dictionary:
    return {
        "version": ProjectSettings.get_setting("application/config/version"),
        "timestamp": Time.get_datetime_string_from_system(),
        "player": PlayerSystem.serialize(),
        "cards": CardSystem.serialize(),
        "worlds": WorldSystem.serialize(),
        "stories": StorySystem.serialize(),
        "marks": MarkSystem.serialize()
    }
```
