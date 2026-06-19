## 世界探索管理器
## 管理世界地图和区域探索

class_name WorldExplorationManager
extends Node

# 当前区域
var current_area: String = "forest"

# 已解锁区域
var unlocked_areas: Array[String] = ["forest"]

# 区域数据
var areas: Dictionary = {
	"forest": {
		"name": "幽暗森林",
		"description": "一片神秘的森林，充满了未知的危险",
		"enemies": ["slime", "skeleton"],
		"npcs": ["merchant", "quest_giver"],
		"background": "res://assets/sprites/environments/forest/env_forest_background.png"
	},
	"castle": {
		"name": "废弃城堡",
		"description": "一座被遗弃的城堡，隐藏着古老的秘密",
		"enemies": ["demon", "skeleton"],
		"npcs": ["blacksmith"],
		"background": "res://assets/sprites/environments/castle/env_castle_background.png"
	},
	"ruins": {
		"name": "古老废墟",
		"description": "远古文明的遗迹，充满了魔法能量",
		"enemies": ["demon", "golem"],
		"npcs": [],
		"background": "res://assets/sprites/environments/ruins/env_ruins_background.png"
	},
	"void": {
		"name": "虚空领域",
		"description": "一个充满黑暗力量的异界空间",
		"enemies": ["dragon", "lich"],
		"npcs": [],
		"background": "res://assets/sprites/environments/void/env_void_background.png"
	}
}

# 信号
signal area_changed(new_area: String)
signal area_unlocked(area: String)

func _ready() -> void:
	initialize()

func initialize() -> void:
	print("[WorldExplorationManager] Initialized")

## 获取当前区域
func get_current_area() -> String:
	return current_area

## 设置当前区域
func set_current_area(area: String) -> void:
	if areas.has(area):
		current_area = area
		area_changed.emit(area)
		print("[WorldExplorationManager] Changed to area: ", area)

## 获取区域数据
func get_area_data(area: String) -> Dictionary:
	return areas.get(area, {})

## 获取区域名称
func get_area_name(area: String) -> String:
	var data = areas.get(area, {})
	return data.get("name", "未知区域")

## 获取区域描述
func get_area_description(area: String) -> String:
	var data = areas.get(area, {})
	return data.get("description", "")

## 获取区域敌人
func get_area_enemies(area: String) -> Array:
	var data = areas.get(area, {})
	return data.get("enemies", [])

## 获取区域NPC
func get_area_npcs(area: String) -> Array:
	var data = areas.get(area, {})
	return data.get("npcs", [])

## 检查区域是否解锁
func is_area_unlocked(area: String) -> bool:
	return area in unlocked_areas

## 解锁区域
func unlock_area(area: String) -> void:
	if not area in unlocked_areas:
		unlocked_areas.append(area)
		area_unlocked.emit(area)
		print("[WorldExplorationManager] Unlocked area: ", area)

## 获取所有区域
func get_all_areas() -> Dictionary:
	return areas

## 获取已解锁区域
func get_unlocked_areas() -> Array[String]:
	return unlocked_areas

## 传送到区域
func teleport_to_area(area: String) -> bool:
	if not is_area_unlocked(area):
		push_warning("[WorldExplorationManager] Area not unlocked: " + area)
		return false
	
	set_current_area(area)
	return true
