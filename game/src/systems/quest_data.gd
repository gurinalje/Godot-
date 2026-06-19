## 任务数据资源类
## 用于定义单个任务的所有属性，支持从外部 .tres 文件加载
class_name QuestData
extends Resource

## 任务ID（唯一标识符）
@export var quest_id: String = ""

## 任务名称
@export var quest_name: String = ""

## 任务描述
@export var description: String = ""

## 任务发布者NPC ID
@export var giver: String = ""

## 任务目标列表
## 每个目标格式: {"type": String, "target": String, "required": int}
@export var objectives: Array[Dictionary] = []

## 任务奖励
## 格式: {"gold": int, "experience": int, "card": String, "item": String}
@export var rewards: Dictionary = {}

## 前置任务ID列表
@export var prerequisites: Array[String] = []

## 所需玩家等级
@export var level_required: int = 1

## 从字典创建QuestData的工厂方法
static func from_dict(quest_id: String, data: Dictionary) -> QuestData:
	var quest := QuestData.new()
	quest.quest_id = quest_id
	quest.quest_name = data.get("name", "")
	quest.description = data.get("description", "")
	quest.giver = data.get("giver", "")
	quest.objectives.assign(data.get("objectives", []))
	quest.rewards = data.get("rewards", {})
	quest.prerequisites.assign(data.get("prerequisites", []))
	quest.level_required = data.get("level_required", 1)
	return quest

## 转换为字典格式（兼容旧系统）
func to_dict() -> Dictionary:
	return {
		"name": quest_name,
		"description": description,
		"giver": giver,
		"objectives": objectives,
		"rewards": rewards,
		"prerequisites": prerequisites,
		"level_required": level_required,
	}
