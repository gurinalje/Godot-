# ADR-0006: Status Effect Stack Rules

> **Status**: Accepted  
> **Date**: 2026-06-03  
> **Deciders**: Technical Director, Lead Programmer

---

## Context

《命运卡牌局》有多种状态效果（Buff/Debuff），需要定义效果叠加规则。

**Key Requirements**:
- 支持多种状态效果类型
- 支持效果叠加/刷新/覆盖
- 支持效果优先级
- 支持效果免疫

---

## Decision

使用**分层叠加规则**管理状态效果：

### 效果叠加规则

| 效果类型 | 叠加规则 | 说明 |
|----------|----------|------|
| **同类Buff** | 叠加层数 | 最多5层，每层独立计时 |
| **同类Debuff** | 刷新持续时间 | 不叠加，刷新持续时间 |
| **不同类效果** | 独立存在 | 可同时存在 |
| **互斥效果** | 高优先级覆盖 | 低优先级被移除 |

### 效果优先级

| 优先级 | 效果类型 | 说明 |
|--------|----------|------|
| 100 | 免疫 | 最高优先级 |
| 80 | 净化 | 移除负面效果 |
| 60 | 增强 | 增益效果 |
| 40 | 普通 | 普通效果 |
| 20 | 弱化 | 减益效果 |
| 0 | 基础 | 基础效果 |

### 效果数据结构

```gdscript
# status_effect.gd
class_name StatusEffect
extends Resource

@export var id: String = ""
@export var name: String = ""
@export var effect_type: EffectType = EffectType.BUFF
@export var stack_type: StackType = StackType.REFRESH
@export var max_stacks: int = 5
@export var priority: int = 40
@export var duration: int = 3
@export var value: float = 0.0
@export var is_debuff: bool = false

enum EffectType { BUFF, DEBUFF, DOT, HOT, IMMUNITY }
enum StackType { STACK, REFRESH, OVERWRITE, IMMUNE }
```

---

## Consequences

### 正面影响
- ✅ 效果叠加规则清晰
- ✅ 易于扩展新效果
- ✅ 支持复杂效果交互
- ✅ 易于平衡调整

### 负面影响
- ⚠️ 规则复杂度高
- ⚠️ 需要管理效果优先级
- ⚠️ 调试困难

### 风险缓解
- 提供效果调试工具
- 使用可视化效果堆栈
- 限制效果数量

---

## ADR Dependencies

- ADR-0004 (Card Data Structure) — 卡牌效果定义

---

## Engine Compatibility

| 特性 | Godot 4.6.3 | 风险 |
|------|-------------|------|
| Resource | ✅ 稳定 | 低 |
| Timer | ✅ 稳定 | 低 |
| Signal | ✅ 稳定 | 低 |

---

## GDD Requirements Addressed

| Requirement ID | GDD | System |
|----------------|-----|--------|
| TR-effect-001 | 状态效果系统 | 效果叠加规则 |
| TR-effect-002 | 状态效果系统 | 效果优先级 |
| TR-effect-003 | 状态效果系统 | 效果持续时间 |

---

## Implementation Notes

```gdscript
# status_effect_manager.gd
class_name StatusEffectManager
extends Node

var _effects: Dictionary = {}  # effect_id -> StatusEffectInstance
var _stacks: Dictionary = {}   # effect_id -> int

func apply_effect(effect: StatusEffect, target: Node) -> void:
    if _can_apply(effect, target):
        match effect.stack_type:
            StatusEffect.StackType.STACK:
                _stack_effect(effect)
            StatusEffect.StackType.REFRESH:
                _refresh_effect(effect)
            StatusEffect.StackType.OVERWRITE:
                _overwrite_effect(effect)
            StatusEffect.StackType.IMMUNE:
                _immune_effect(effect)

func _can_apply(effect: StatusEffect, target: Node) -> bool:
    # 检查免疫
    if _has_immunity(effect.effect_type):
        return false
    # 检查优先级
    if _has_higher_priority_effect(effect):
        return false
    return true

func _stack_effect(effect: StatusEffect) -> void:
    if _stacks.has(effect.id):
        if _stacks[effect.id] < effect.max_stacks:
            _stacks[effect.id] += 1
            _effects[effect.id].refresh_duration()
    else:
        _stacks[effect.id] = 1
        _effects[effect.id] = StatusEffectInstance.new(effect)
```
