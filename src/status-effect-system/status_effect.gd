# status_effect.gd
# 状态效果资源类
# 定义单个状态效果的所有属性

@tool
class_name StatusEffect
extends Resource

## 效果类型枚举
enum EffectType {
	BUFF,    ## 增益效果
	DEBUFF,  ## 减益效果
	DOT,     ## 持续伤害
	HOT,     ## 持续治疗
	SHIELD   ## 护盾
}

## 效果ID
@export var effect_id: String = ""

## 效果名称
@export var effect_name: String = ""

## 效果描述
@export var description: String = ""

## 效果类型
@export var effect_type: EffectType = EffectType.BUFF

## 效果数值
@export var value: int = 0

## 持续回合数
@export var duration: int = 1

## 最大叠加层数
@export var max_stacks: int = 1

## 当前叠加层数
var current_stacks: int = 1

## 效果图标
@export var icon: Texture2D = null

## 效果颜色（用于UI显示）
@export var effect_color: Color = Color.WHITE

## 是否可驱散
@export var can_be_dispeled: bool = true

## 是否为负面效果
@export var is_negative: bool = false

## 初始化
func _init() -> void:
	pass

## 获取效果描述
func get_description() -> String:
	var desc: String = description
	if max_stacks > 1:
		desc += " (%d/%d层)" % [current_stacks, max_stacks]
	desc += " 剩余%d回合" % duration
	return desc

## 获取效果数值（考虑叠加层数）
func get_effective_value() -> int:
	return value * current_stacks

## 增加叠加层数
func add_stack() -> bool:
	if current_stacks < max_stacks:
		current_stacks += 1
		return true
	return false

## 减少叠加层数
func remove_stack() -> void:
	if current_stacks > 1:
		current_stacks -= 1

## 回合结束时调用
func on_turn_end() -> void:
	duration -= 1

## 检查效果是否已过期
func is_expired() -> bool:
	return duration <= 0

## 克隆效果
func clone() -> StatusEffect:
	var new_effect: StatusEffect = StatusEffect.new()
	new_effect.effect_id = effect_id
	new_effect.effect_name = effect_name
	new_effect.description = description
	new_effect.effect_type = effect_type
	new_effect.value = value
	new_effect.duration = duration
	new_effect.max_stacks = max_stacks
	new_effect.current_stacks = current_stacks
	new_effect.icon = icon
	new_effect.effect_color = effect_color
	new_effect.can_be_dispeled = can_be_dispeled
	new_effect.is_negative = is_negative
	return new_effect

## 序列化为字典
func to_dict() -> Dictionary:
	return {
		"effect_id": effect_id,
		"effect_name": effect_name,
		"effect_type": effect_type,
		"value": value,
		"duration": duration,
		"max_stacks": max_stacks,
		"current_stacks": current_stacks,
		"can_be_dispeled": can_be_dispeled,
		"is_negative": is_negative
	}

## 从字典反序列化
static func from_dict(data: Dictionary) -> StatusEffect:
	var effect: StatusEffect = StatusEffect.new()
	effect.effect_id = data.get("effect_id", "")
	effect.effect_name = data.get("effect_name", "")
	effect.effect_type = data.get("effect_type", EffectType.BUFF)
	effect.value = data.get("value", 0)
	effect.duration = data.get("duration", 1)
	effect.max_stacks = data.get("max_stacks", 1)
	effect.current_stacks = data.get("current_stacks", 1)
	effect.can_be_dispeled = data.get("can_be_dispeled", true)
	effect.is_negative = data.get("is_negative", false)
	return effect
