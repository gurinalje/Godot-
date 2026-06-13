# character_attribute.gd
# 角色属性资源类
# 定义单个属性的所有属性和计算逻辑

@tool
class_name CharacterAttribute
extends RefCounted

## 属性类型枚举
enum AttributeType {
	STRENGTH,     ## 力量 - 影响物理伤害
	DEXTERITY,    ## 敏捷 - 影响暴击和闪避
	INTELLIGENCE, ## 智力 - 影响魔法伤害和治疗
	CONSTITUTION, ## 体质 - 影响生命值和防御
	PERCEPTION,   ## 感知 - 影响命中和发现
	LUCK          ## 幸运 - 影响掉落和特殊效果
}

## 属性名称映射
const ATTRIBUTE_NAMES: Dictionary = {
	AttributeType.STRENGTH: "力量",
	AttributeType.DEXTERITY: "敏捷",
	AttributeType.INTELLIGENCE: "智力",
	AttributeType.CONSTITUTION: "体质",
	AttributeType.PERCEPTION: "感知",
	AttributeType.LUCK: "幸运"
}

## 属性描述映射
const ATTRIBUTE_DESCRIPTIONS: Dictionary = {
	AttributeType.STRENGTH: "影响物理攻击力和负重能力",
	AttributeType.DEXTERITY: "影响暴击率、暴击伤害和闪避率",
	AttributeType.INTELLIGENCE: "影响魔法攻击力和治疗效果",
	AttributeType.CONSTITUTION: "影响最大生命值和物理防御",
	AttributeType.PERCEPTION: "影响命中率和隐藏发现",
	AttributeType.LUCK: "影响掉落率和特殊效果触发"
}

## 属性类型
var type: AttributeType

## 基础值
var base_value: int

## 装备加成
var equipment_bonus: int = 0

## Buff加成
var buff_bonus: int = 0

## 等级加成
var level_bonus: int = 0

## 初始化
func _init(attr_type: AttributeType, base: int = 10) -> void:
	type = attr_type
	base_value = base

## 获取属性名称
func get_name() -> String:
	return ATTRIBUTE_NAMES.get(type, "未知")

## 获取属性描述
func get_description() -> String:
	return ATTRIBUTE_DESCRIPTIONS.get(type, "")

## 获取最终属性值（所有加成总和）
func get_final_value() -> int:
	var final_value: int = base_value + equipment_bonus + buff_bonus + level_bonus
	# 属性值限制在0-149之间
	return clampi(final_value, 0, 149)

## 获取属性修正值（用于伤害计算等）
## 修正值 = (属性值 - 10) / 2，向下取整
func get_modifier() -> int:
	return (get_final_value() - 10) / 2

## 设置装备加成
func set_equipment_bonus(bonus: int) -> void:
	equipment_bonus = bonus

## 设置Buff加成
func set_buff_bonus(bonus: int) -> void:
	buff_bonus = bonus

## 设置等级加成
func set_level_bonus(bonus: int) -> void:
	level_bonus = bonus

## 重置所有加成
func reset_bonuses() -> void:
	equipment_bonus = 0
	buff_bonus = 0
	level_bonus = 0

## 序列化为字典
func to_dict() -> Dictionary:
	return {
		"type": type,
		"base_value": base_value,
		"equipment_bonus": equipment_bonus,
		"buff_bonus": buff_bonus,
		"level_bonus": level_bonus
	}

## 从字典反序列化
static func from_dict(data: Dictionary) -> CharacterAttribute:
	var attr: CharacterAttribute = CharacterAttribute.new(
		data.get("type", AttributeType.STRENGTH),
		data.get("base_value", 10)
	)
	attr.equipment_bonus = data.get("equipment_bonus", 0)
	attr.buff_bonus = data.get("buff_bonus", 0)
	attr.level_bonus = data.get("level_bonus", 0)
	return attr
