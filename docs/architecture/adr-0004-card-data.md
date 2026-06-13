# ADR-0004: Card Data Structure

> **Status**: Accepted  
> **Date**: 2026-06-03  
> **Deciders**: Technical Director, Lead Programmer

---

## Context

《命运卡牌局》有100+张卡牌，每张卡牌有多种属性。需要定义统一的卡牌数据结构。

**Key Requirements**:
- 支持4种卡牌类型（召唤/伤害/环境/增益）
- 支持5种元素（火/水/风/土/雷）
- 支持卡牌升级（1-5级）
- 支持卡牌效果组合

---

## Decision

使用Godot的**Resource系统**定义卡牌数据，每张卡牌是一个`.tres`文件。

### CardData Resource

```gdscript
# card_data.gd
class_name CardData
extends Resource

@export var id: String = ""
@export var name: String = ""
@export var description: String = ""
@export var type: CardType = CardType.ATTACK
@export var element: ElementType = ElementType.NONE
@export var rarity: Rarity = Rarity.COMMON
@export var cost: int = 0  # 能量消耗 0-10
@export var level: int = 1  # 当前等级 1-5
@export var max_level: int = 5

@export var effects: Array[CardEffect] = []
@export var upgrade_costs: Array[UpgradeCost] = []

enum CardType { ATTACK, SUMMON, ENVIRONMENT, BUFF }
enum ElementType { NONE, FIRE, WATER, WIND, EARTH, THUNDER }
enum Rarity { COMMON, RARE, EPIC, LEGENDARY }
```

### CardEffect Resource

```gdscript
# card_effect.gd
class_name CardEffect
extends Resource

@export var effect_type: EffectType = EffectType.DAMAGE
@export var value: int = 0
@export var duration: int = 0  # 持续回合数，0=即时
@export var target: TargetType = TargetType.ENEMY

enum EffectType { DAMAGE, HEAL, SUMMON, BUFF, DEBUFF, ENVIRONMENT }
enum TargetType { SELF, ENEMY, ALL, RANDOM }
```

### 文件结构

```
res://data/cards/
├─ common/
│  ├─ fire_ball.tres
│  ├─ water_shield.tres
│  └─ ...
├─ rare/
│  ├─ fire_dragon.tres
│  └─ ...
├─ epic/
│  └─ ...
└─ legendary/
   └─ ...
```

---

## Consequences

### 正面影响
- ✅ 类型安全（Resource系统）
- ✅ 编辑器支持（Inspector面板）
- ✅ 易于扩展新卡牌
- ✅ 支持热重载

### 负面影响
- ⚠️ 大量.tres文件管理复杂
- ⚠️ 需要自定义编辑器工具
- ⚠️ 版本控制需要处理二进制

### 风险缓解
- 使用脚本批量生成.tres文件
- 实现卡牌编辑器工具
- 使用文本格式的.tres（非二进制）

---

## ADR Dependencies

- 无（基础ADR）

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
| TR-card-001 | 卡牌数据库 | 卡牌数据结构 |
| TR-card-002 | 卡牌数据库 | 卡牌类型定义 |
| TR-card-003 | 卡牌数据库 | 卡牌效果定义 |

---

## Implementation Notes

```gdscript
# 示例卡牌数据 (fire_ball.tres)
[gd_resource type="Resource" script_class="CardData" load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/card_data.gd" id="1"]
[ext_resource type="Script" path="res://scripts/card_effect.gd" id="2"]

[sub_resource type="Resource" id="1"]
script = ExtResource("2")
effect_type = 0  # DAMAGE
value = 8
duration = 0
target = 1  # ENEMY

[resource]
script = ExtResource("1")
id = "fire_ball_001"
name = "火球术"
description = "对敌人造成8点火焰伤害"
type = 0  # ATTACK
element = 1  # FIRE
rarity = 0  # COMMON
cost = 3
level = 1
max_level = 5
effects = [SubResource("1")]
```
