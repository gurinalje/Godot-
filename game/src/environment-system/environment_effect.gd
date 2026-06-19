# environment_effect.gd
# 环境效果资源类
# 定义单个环境效果的所有属性

@tool
class_name EnvironmentEffect
extends Resource

## 环境类型枚举
enum EnvironmentType {
	NONE,      ## 无环境
	FIRE,      ## 火焰环境
	WATER,     ## 水域环境
	EARTH,     ## 大地环境
	WIND,      ## 风暴环境
	LIGHTNING  ## 雷电环境
}

## 环境ID
@export var environment_id: String = ""

## 环境名称
@export var environment_name: String = ""

## 环境描述
@export var description: String = ""

## 环境类型
@export var environment_type: EnvironmentType = EnvironmentType.NONE

## 环境持续回合数
@export var duration: int = 3

## 当前剩余回合
var remaining_turns: int = 0

## 对友方单位的效果
@export var ally_effects: Array[Dictionary] = []

## 对敌方单位的效果
@export var enemy_effects: Array[Dictionary] = []

## 环境图标
@export var icon: Texture2D = null

## 环境颜色
@export var environment_color: Color = Color.WHITE

## 环境背景
@export var background: Texture2D = null

## 初始化
func _init() -> void:
	remaining_turns = duration

## 激活环境
func activate() -> void:
	remaining_turns = duration

## 检查环境是否激活
func is_active() -> bool:
	return remaining_turns > 0

## 处理回合结束
func process_turn_end() -> void:
	if remaining_turns > 0:
		remaining_turns -= 1

## 获取对友方单位的效果
func get_ally_effects() -> Array[Dictionary]:
	return ally_effects

## 获取对敌方单位的效果
func get_enemy_effects() -> Array[Dictionary]:
	return enemy_effects

## 获取环境效果描述
func get_description() -> String:
	var desc: String = description + "\n"
	desc += "持续 %d 回合\n" % remaining_turns
	
	if not ally_effects.is_empty():
		desc += "友方效果:\n"
		for effect in ally_effects:
			desc += "  • %s: %+d\n" % [effect.get("name", "未知"), effect.get("value", 0)]
	
	if not enemy_effects.is_empty():
		desc += "敌方效果:\n"
		for effect in enemy_effects:
			desc += "  • %s: %+d\n" % [effect.get("name", "未知"), effect.get("value", 0)]
	
	return desc

## 获取环境类型名称
func get_type_name() -> String:
	match environment_type:
		EnvironmentType.FIRE:
			return "火焰"
		EnvironmentType.WATER:
			return "水域"
		EnvironmentType.EARTH:
			return "大地"
		EnvironmentType.WIND:
			return "风暴"
		EnvironmentType.LIGHTNING:
			return "雷电"
		_:
			return "无"

## 获取环境颜色
func get_type_color() -> Color:
	match environment_type:
		EnvironmentType.FIRE:
			return Color(1.0, 0.3, 0.2)
		EnvironmentType.WATER:
			return Color(0.2, 0.5, 1.0)
		EnvironmentType.EARTH:
			return Color(0.6, 0.4, 0.2)
		EnvironmentType.WIND:
			return Color(0.4, 0.9, 0.4)
		EnvironmentType.LIGHTNING:
			return Color(1.0, 0.9, 0.2)
		_:
			return Color(0.7, 0.7, 0.7)

## 序列化为字典
func to_dict() -> Dictionary:
	return {
		"environment_id": environment_id,
		"environment_name": environment_name,
		"description": description,
		"environment_type": environment_type,
		"duration": duration,
		"remaining_turns": remaining_turns,
		"ally_effects": ally_effects,
		"enemy_effects": enemy_effects
	}

## 从字典反序列化
static func from_dict(data: Dictionary) -> EnvironmentEffect:
	var env: EnvironmentEffect = EnvironmentEffect.new()
	env.environment_id = data.get("environment_id", "")
	env.environment_name = data.get("environment_name", "")
	env.description = data.get("description", "")
	env.environment_type = data.get("environment_type", EnvironmentType.NONE)
	env.duration = data.get("duration", 3)
	env.remaining_turns = data.get("remaining_turns", 0)
	env.ally_effects = data.get("ally_effects", [])
	env.enemy_effects = data.get("enemy_effects", [])
	return env
