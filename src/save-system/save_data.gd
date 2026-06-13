# save_data.gd
# PROTOTYPE - NOT FOR PRODUCTION
# Story: 存档数据结构
# Date: 2026-06-03

class_name SaveData
extends Resource

## 存档数据结构
## 使用Godot Resource系统定义存档数据，支持JSON序列化

# 版本信息
@export var version: String = "1.0"
@export var timestamp: String = ""

# 玩家数据
@export var player_data: Dictionary = {
	"level": 1,
	"experience": 0,
	"attributes": {
		"strength": 10,
		"dexterity": 10,
		"intelligence": 10,
		"constitution": 10,
		"perception": 10,
		"luck": 10
	},
	"gold": 0
}

# 卡牌数据
@export var cards_data: Dictionary = {
	"collection": [],  # 所有已收集的卡牌ID
	"deck": [],        # 当前卡组的卡牌ID
	"levels": {}       # 卡牌等级 {card_id: level}
}

# 世界状态数据
@export var worlds_data: Dictionary = {
	"forest": {"unlocked": false, "completed": false},
	"castle": {"unlocked": false, "completed": false},
	"ruins": {"unlocked": false, "completed": false},
	"void": {"unlocked": false, "completed": false}
}

# 剧情进度数据
@export var stories_data: Dictionary = {
	"main_quest": {"progress": 0, "choices": []},
	"side_quests": [],
	"hidden_stories": []
}

# 印记数据
@export var marks_data: Dictionary = {
	"good": 0,
	"evil": 0,
	"neutral": 0
}

## 序列化为Dictionary
func serialize() -> Dictionary:
	return {
		"version": version,
		"timestamp": timestamp,
		"player": player_data,
		"cards": cards_data,
		"worlds": worlds_data,
		"stories": stories_data,
		"marks": marks_data
	}

## 从Dictionary反序列化
static func deserialize(data: Dictionary) -> SaveData:
	var save_data = SaveData.new()
	
	# 版本信息
	if data.has("version"):
		save_data.version = data["version"]
	if data.has("timestamp"):
		save_data.timestamp = data["timestamp"]
	
	# 玩家数据
	if data.has("player"):
		save_data.player_data = data["player"]
	
	# 卡牌数据
	if data.has("cards"):
		save_data.cards_data = data["cards"]
	
	# 世界状态数据
	if data.has("worlds"):
		save_data.worlds_data = data["worlds"]
	
	# 剧情进度数据
	if data.has("stories"):
		save_data.stories_data = data["stories"]
	
	# 印记数据
	if data.has("marks"):
		save_data.marks_data = data["marks"]
	
	return save_data

## 验证数据完整性
func validate() -> bool:
	# 检查必需字段
	if version.is_empty():
		return false
	if timestamp.is_empty():
		return false
	if not player_data.has("level"):
		return false
	if not player_data.has("experience"):
		return false
	if not player_data.has("attributes"):
		return false
	if not player_data.has("gold"):
		return false
	if not cards_data.has("collection"):
		return false
	if not cards_data.has("deck"):
		return false
	if not cards_data.has("levels"):
		return false
	if not worlds_data.has("forest"):
		return false
	if not marks_data.has("good"):
		return false
	if not marks_data.has("evil"):
		return false
	if not marks_data.has("neutral"):
		return false
	
	return true

## 获取玩家等级
func get_player_level() -> int:
	return player_data.get("level", 1)

## 获取玩家经验值
func get_player_experience() -> int:
	return player_data.get("experience", 0)

## 获取玩家金币
func get_player_gold() -> int:
	return player_data.get("gold", 0)

## 获取玩家属性
func get_player_attribute(attribute_name: String) -> int:
	var attributes = player_data.get("attributes", {})
	return attributes.get(attribute_name, 0)

## 获取卡牌收藏数量
func get_card_collection_count() -> int:
	return cards_data.get("collection", []).size()

## 获取卡组卡牌数量
func get_deck_count() -> int:
	return cards_data.get("deck", []).size()

## 获取卡牌等级
func get_card_level(card_id: String) -> int:
	var levels = cards_data.get("levels", {})
	return levels.get(card_id, 1)

## 检查世界是否解锁
func is_world_unlocked(world_id: String) -> bool:
	var world = worlds_data.get(world_id, {})
	return world.get("unlocked", false)

## 检查世界是否完成
func is_world_completed(world_id: String) -> bool:
	var world = worlds_data.get(world_id, {})
	return world.get("completed", false)

## 获取印记数量
func get_mark_count(mark_type: String) -> int:
	return marks_data.get(mark_type, 0)
