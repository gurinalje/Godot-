# ADR-0007: Dialogue Tree Format

> **Status**: Accepted  
> **Date**: 2026-06-03  
> **Deciders**: Technical Director, Lead Programmer

---

## Context

《命运卡牌局》有丰富的对话系统，需要支持分支对话、选择影响、NPC关系等。

**Key Requirements**:
- 支持分支对话树
- 支持选择影响剧情
- 支持NPC关系系统
- 支持本地化

---

## Decision

使用**基于Resource的对话树格式**，每个对话是一个.tres文件。

### DialogueNode Resource

```gdscript
# dialogue_node.gd
class_name DialogueNode
extends Resource

@export var id: String = ""
@export var speaker: String = ""
@export var text: String = ""
@export var portrait: Texture2D = null
@export var choices: Array[DialogueChoice] = []
@export var next_node: String = ""  # 无选择时的下一个节点
@export var conditions: Array[DialogueCondition] = []
@export var effects: Array[DialogueEffect] = []
```

### DialogueChoice Resource

```gdscript
# dialogue_choice.gd
class_name DialogueChoice
extends Resource

@export var text: String = ""
@export var next_node: String = ""
@export var conditions: Array[DialogueCondition] = []
@export var effects: Array[DialogueEffect] = []
@export var mark_type: String = ""  # 故事印记类型
@export var mark_value: int = 0     # 故事印记值
```

### DialogueEffect Resource

```gdscript
# dialogue_effect.gd
class_name DialogueEffect
extends Resource

@export var effect_type: EffectType = EffectType.NONE
@export var target_id: String = ""
@export var value: int = 0

enum EffectType { 
    NONE, 
    ADD_MARK, 
    CHANGE_ATTITUDE, 
    UNLOCK_WORLD, 
    UNLOCK_CARD,
    GIVE_ITEM,
    TRIGGER_STORY
}
```

### 对话树文件结构

```
res://data/dialogues/
├─ npcs/
│  ├─ merchant_001.tres
│  ├─ quest_giver_001.tres
│  └─ ...
├─ events/
│  ├─ forest_event_001.tres
│  └─ ...
└─ main_story/
   ├─ chapter_001.tres
   └─ ...
```

---

## Consequences

### 正面影响
- ✅ 对话树结构清晰
- ✅ 支持复杂分支逻辑
- ✅ 易于编辑和扩展
- ✅ 支持本地化

### 负面影响
- ⚠️ 对话文件可能很大
- ⚠️ 需要对话编辑器工具
- ⚠️ 调试困难

### 风险缓解
- 实现对话编辑器工具
- 使用可视化对话树
- 提供对话调试工具

---

## ADR Dependencies

- ADR-0004 (Card Data Structure) — Resource格式基础

---

## Engine Compatibility

| 特性 | Godot 4.6.3 | 风险 |
|------|-------------|------|
| Resource | ✅ 稳定 | 低 |
| @export | ✅ 稳定 | 低 |
| .tres | ✅ 稳定 | 低 |

---

## GDD Requirements Addressed

| Requirement ID | GDD | System |
|----------------|-----|--------|
| TR-dialogue-001 | 对话系统 | 对话树格式 |
| TR-dialogue-002 | 对话系统 | 选择影响 |
| TR-dialogue-003 | 对话系统 | NPC关系 |

---

## Implementation Notes

```gdscript
# dialogue_manager.gd
class_name DialogueManager
extends Node

signal dialogue_started(dialogue_id: String)
signal dialogue_ended()
signal choice_made(choice_index: int)

var _current_dialogue: DialogueNode
var _dialogue_history: Array[String] = []

func start_dialogue(dialogue_id: String) -> void:
    var dialogue_data = load("res://data/dialogues/" + dialogue_id + ".tres")
    if dialogue_data:
        _current_dialogue = dialogue_data
        dialogue_started.emit(dialogue_id)
        _show_dialogue(_current_dialogue)

func make_choice(choice_index: int) -> void:
    if _current_dialogue.choices.size() > choice_index:
        var choice = _current_dialogue.choices[choice_index]
        
        # 应用效果
        for effect in choice.effects:
            _apply_effect(effect)
        
        # 应用故事印记
        if choice.mark_type:
            StoryMarkSystem.add_mark(choice.mark_type, choice.mark_value)
        
        # 跳转到下一个节点
        _load_node(choice.next_node)
        choice_made.emit(choice_index)

func _apply_effect(effect: DialogueEffect) -> void:
    match effect.effect_type:
        DialogueEffect.EffectType.CHANGE_ATTITUDE:
            NPCSystem.update_attitude(effect.target_id, effect.value)
        DialogueEffect.EffectType.UNLOCK_WORLD:
            WorldStateSystem.unlock_world(effect.target_id)
        DialogueEffect.EffectType.TRIGGER_STORY:
            StoryTrackingSystem.update_progress(effect.target_id, effect.value)
```
