## NPC管理器
## 管理游戏中的NPC数据和交互

class_name NPCManager
extends Node

# NPC数据
var npcs: Dictionary = {}

# NPC状态
var npc_states: Dictionary = {}

# 信号
signal npc_interaction_started(npc_id: String)
signal npc_interaction_ended(npc_id: String)

func _ready() -> void:
	initialize()

func initialize() -> void:
	print("[NPCManager] Initialized")
	_load_npc_data()

## 加载NPC数据
func _load_npc_data() -> void:
	# TODO: 从文件加载NPC数据
	npcs = {
		"merchant": {
			"id": "merchant",
			"name": "商人",
			"description": "一位友善的商人",
			"sprite": "res://assets/sprites/characters/npcs/char_npcs_merchant.png",
			"dialogue_id": "merchant_greeting",
			"position": Vector2(300, 400),
			"area": "forest"
		},
		"quest_giver": {
			"id": "quest_giver",
			"name": "任务给予者",
			"description": "一位神秘的任务给予者",
			"sprite": "res://assets/sprites/characters/npcs/char_npcs_quest_giver.png",
			"dialogue_id": "quest_giver_greeting",
			"position": Vector2(500, 300),
			"area": "forest"
		},
		"blacksmith": {
			"id": "blacksmith",
			"name": "铁匠",
			"description": "一位技艺精湛的铁匠",
			"sprite": "res://assets/sprites/characters/npcs/char_npcs_blacksmith.png",
			"dialogue_id": "blacksmith_greeting",
			"position": Vector2(400, 500),
			"area": "castle"
		}
	}

## 获取NPC数据
func get_npc_data(npc_id: String) -> Dictionary:
	return npcs.get(npc_id, {})

## 获取区域内的NPC
func get_npcs_in_area(area: String) -> Array:
	var area_npcs = []
	for npc in npcs.values():
		if npc.get("area", "") == area:
			area_npcs.append(npc)
	return area_npcs

## 获取NPC名称
func get_npc_name(npc_id: String) -> String:
	var data = get_npc_data(npc_id)
	return data.get("name", "")

## 获取NPC描述
func get_npc_description(npc_id: String) -> String:
	var data = get_npc_data(npc_id)
	return data.get("description", "")

## 获取NPC精灵
func get_npc_sprite(npc_id: String) -> String:
	var data = get_npc_data(npc_id)
	return data.get("sprite", "")

## 获取NPC对话ID
func get_npc_dialogue_id(npc_id: String) -> String:
	var data = get_npc_data(npc_id)
	return data.get("dialogue_id", "")

## 获取NPC位置
func get_npc_position(npc_id: String) -> Vector2:
	var data = get_npc_data(npc_id)
	return data.get("position", Vector2.ZERO)

## 开始NPC交互
func start_interaction(npc_id: String) -> void:
	npc_interaction_started.emit(npc_id)
	print("[NPCManager] Started interaction with: ", npc_id)

## 结束NPC交互
func end_interaction(npc_id: String) -> void:
	npc_interaction_ended.emit(npc_id)
	print("[NPCManager] Ended interaction with: ", npc_id)

## 检查NPC是否存在
func has_npc(npc_id: String) -> bool:
	return npcs.has(npc_id)

## 获取所有NPC
func get_all_npcs() -> Dictionary:
	return npcs

## 获取NPC状态
func get_npc_state(npc_id: String) -> Dictionary:
	return npc_states.get(npc_id, {})

## 设置NPC状态
func set_npc_state(npc_id: String, state: Dictionary) -> void:
	npc_states[npc_id] = state
