# card_effect.gd
# 卡牌效果资源类
# 定义单个卡牌效果的所有属性

@tool
class_name CardEffect
extends Resource

## 效果类型
@export var effect_type: CardEnums.EffectType = CardEnums.EffectType.DAMAGE

## 效果数值
@export var value: int = 0

## 目标类型
@export var target: CardEnums.TargetType = CardEnums.TargetType.ENEMY

## 持续回合数（0表示即时效果）
@export var duration: int = 0

## 辅助数值（可选，例如用于召唤物的攻击力）
@export var secondary_value: int = 0

## 触发条件（可选，用于复杂效果）
@export var condition: String = ""

## 效果描述模板（用于生成显示文本）
@export var description_template: String = ""

## 获取效果描述文本
func get_description() -> String:
	if not description_template.is_empty():
		return description_template.format({"value": value, "duration": duration})
	
	var desc: String = ""
	match effect_type:
		CardEnums.EffectType.DAMAGE:
			desc = "造成%d点伤害" % value
		CardEnums.EffectType.HEAL:
			desc = "恢复%d点生命" % value
		CardEnums.EffectType.SUMMON:
			desc = "召唤单位（生命值:%d）" % value
		CardEnums.EffectType.BUFF:
			desc = "获得增益效果（+%d）" % value
		CardEnums.EffectType.DEBUFF:
			desc = "施加减益效果（-%d）" % value
		CardEnums.EffectType.ENVIRONMENT_CHANGE:
			desc = "改变战场环境"
	
	if duration > 0:
		desc += "，持续%d回合" % duration
	
	return desc

## 获取目标描述
func get_target_description() -> String:
	match target:
		CardEnums.TargetType.SELF:
			return "自身"
		CardEnums.TargetType.ENEMY:
			return "单个敌人"
		CardEnums.TargetType.ALL_ENEMIES:
			return "所有敌人"
		CardEnums.TargetType.ALL_ALLIES:
			return "所有友方"
		CardEnums.TargetType.RANDOM:
			return "随机目标"
		_:
			return "未知"

## 检查效果是否为即时效果
func is_instant() -> bool:
	return duration == 0

## 检查效果是否为持续效果
func is_persistent() -> bool:
	return duration > 0

## 克隆效果（用于创建独立副本）
func clone() -> CardEffect:
	var new_effect: CardEffect = CardEffect.new()
	new_effect.effect_type = effect_type
	new_effect.value = value
	new_effect.target = target
	new_effect.duration = duration
	new_effect.condition = condition
	new_effect.description_template = description_template
	return new_effect

## 序列化为字典（用于存档）
func to_dict() -> Dictionary:
	return {
		"effect_type": effect_type,
		"value": value,
		"target": target,
		"duration": duration,
		"condition": condition
	}

## 从字典反序列化
static func from_dict(data: Dictionary) -> CardEffect:
	var effect: CardEffect = CardEffect.new()
	effect.effect_type = data.get("effect_type", CardEnums.EffectType.DAMAGE)
	effect.value = data.get("value", 0)
	effect.target = data.get("target", CardEnums.TargetType.ENEMY)
	effect.duration = data.get("duration", 0)
	effect.condition = data.get("condition", "")
	return effect
