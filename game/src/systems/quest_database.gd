## 任务数据库
## 管理所有任务定义的外部数据源
class_name QuestDatabase
extends Node

## 任务定义资源文件路径
const QUEST_DATA_DIR: String = "res://data/quests/"

## 所有任务定义（quest_id -> QuestData）
var quest_definitions: Dictionary = {}

## 默认任务数据（内联定义，作为Resource文件不可用时的回退）
const DEFAULT_QUEST_DEFINITIONS: Dictionary = {
	"forest_boss_quest": {
		"name": "森林巨魔的威胁",
		"description": "幽暗森林深处出现了一只狂暴的森林巨魔，击败它以保卫村庄！",
		"giver": "quest_giver_forest",
		"objectives": [
			{"type": "kill", "target": "森林巨魔", "required": 1}
		],
		"rewards": {
			"gold": 300,
			"experience": 400,
			"card": "holy_blessing"
		},
		"prerequisites": [],
		"level_required": 1
	},
	"wolf_hunt": {
		"name": "猎狼任务",
		"description": "森林中的野狼威胁着商队的安全，消灭5只野狼。",
		"giver": "quest_giver",
		"objectives": [
			{"type": "kill", "target": "野狼", "required": 5}
		],
		"rewards": {
			"gold": 100,
			"experience": 50,
			"card": "summon_skeleton"
		},
		"prerequisites": [],
		"level_required": 1
	},
	"goblin_clear": {
		"name": "清理哥布林",
		"description": "哥布林在森林边缘建立了营地，清理它们！",
		"giver": "quest_giver",
		"objectives": [
			{"type": "kill", "target": "哥布林", "required": 3}
		],
		"rewards": {
			"gold": 150,
			"experience": 75,
			"card": "lightning"
		},
		"prerequisites": ["wolf_hunt"],
		"level_required": 3
	},
	"skeleton_king": {
		"name": "骷髅王之怒",
		"description": "城堡深处的骷髅王复活了，击败它！",
		"giver": "quest_giver",
		"objectives": [
			{"type": "kill", "target": "骷髅王", "required": 1}
		],
		"rewards": {
			"gold": 500,
			"experience": 200,
			"card": "earthquake"
		},
		"prerequisites": ["goblin_clear"],
		"level_required": 8
	},
	"collect_herbs": {
		"name": "采集草药",
		"description": "采集10份草药来制作药水。",
		"giver": "merchant",
		"objectives": [
			{"type": "collect", "target": "草药", "required": 10}
		],
		"rewards": {
			"gold": 80,
			"experience": 30,
			"item": "生命药水"
		},
		"prerequisites": [],
		"level_required": 1
	},
	"escort_merchant": {
		"name": "护送商队",
		"description": "保护商队安全通过危险区域。",
		"giver": "merchant",
		"objectives": [
			{"type": "escort", "target": "商队", "required": 1}
		],
		"rewards": {
			"gold": 200,
			"experience": 100,
			"card": "holy_blessing"
		},
		"prerequisites": ["collect_herbs"],
		"level_required": 5
	}
}

func _ready() -> void:
	_load_quest_definitions()

## 加载任务定义（优先从Resource文件加载，否则使用默认数据）
func _load_quest_definitions() -> void:
	# 尝试从Resource目录加载
	var dir: DirAccess = DirAccess.open(QUEST_DATA_DIR)
	if dir:
		dir.list_dir_begin()
		var file_name: String = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres") or file_name.ends_with(".res"):
				var quest_data: QuestData = load(QUEST_DATA_DIR + file_name) as QuestData
				if quest_data and not quest_data.quest_id.is_empty():
					quest_definitions[quest_data.quest_id] = quest_data
			file_name = dir.get_next()
		dir.list_dir_end()

	# 如果没有从Resource加载到数据，使用默认数据
	if quest_definitions.is_empty():
		_load_default_definitions()

## 从默认字典加载任务定义
func _load_default_definitions() -> void:
	for quest_id: String in DEFAULT_QUEST_DEFINITIONS:
		var data: Dictionary = DEFAULT_QUEST_DEFINITIONS[quest_id]
		quest_definitions[quest_id] = QuestData.from_dict(quest_id, data)

## 获取任务定义
func get_quest_definition(quest_id: String) -> QuestData:
	return quest_definitions.get(quest_id, null)

## 获取所有任务定义
func get_all_definitions() -> Dictionary:
	return quest_definitions

## 检查任务是否存在
func has_quest(quest_id: String) -> bool:
	return quest_definitions.has(quest_id)
