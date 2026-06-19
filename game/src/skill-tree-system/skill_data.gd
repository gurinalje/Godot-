## 技能数据资源类
## 用于定义单个技能的所有属性，支持从外部 .tres 文件加载
class_name SkillData
extends Resource

## 技能ID（唯一标识符）
@export var skill_id: String = ""

## 技能所属类别（如 warrior, mage 等）
@export var category: String = ""

## 技能名称
@export var skill_name: String = ""

## 技能描述
@export var description: String = ""

## 技能点消耗
@export var cost: int = 1

## 前置技能ID列表
@export var prerequisites: Array[String] = []

## 技能效果
## 格式: {"damage": int, "element": String, "cooldown": int, ...}
@export var effects: Dictionary = {}

## 从字典创建SkillData的工厂方法
static func from_dict(skill_id: String, category: String, data: Dictionary) -> SkillData:
	var skill := SkillData.new()
	skill.skill_id = skill_id
	skill.category = category
	skill.skill_name = data.get("name", "")
	skill.description = data.get("description", "")
	skill.cost = data.get("cost", 1)
	skill.prerequisites.assign(data.get("requires", []))
	skill.effects = data.get("effects", {})
	return skill

## 转换为字典格式（兼容旧系统）
func to_dict() -> Dictionary:
	return {
		"name": skill_name,
		"description": description,
		"cost": cost,
		"requires": prerequisites,
		"effects": effects,
	}
