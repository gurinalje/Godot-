# save_slot_manager.gd
# Story 002: 存档槽管理
# Date: 2026-06-03

class_name SaveSlotManager
extends Node

## 存档槽管理器
## 管理6个存档槽（Slot 0为自动保存，Slot 1-5为手动保存）

# 常量
const SAVE_DIR: String = "user://saves/"
const MAX_SLOTS: int = 6
const AUTO_SAVE_SLOT: int = 0
const MANUAL_SAVE_SLOTS: Array[int] = [1, 2, 3, 4, 5]

# 存档槽信息
class SaveSlotInfo:
	var slot_id: int
	var file_path: String
	var is_empty: bool
	var is_auto_save: bool
	var timestamp: String
	var play_time: String
	var location: String
	
	func _init(p_slot_id: int, p_file_path: String, p_is_empty: bool, p_is_auto_save: bool):
		slot_id = p_slot_id
		file_path = p_file_path
		is_empty = p_is_empty
		is_auto_save = p_is_auto_save
		timestamp = ""
		play_time = ""
		location = ""

## 初始化存档目录
static func init_save_directory() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)

## 获取存档文件路径
static func get_slot_file_path(slot_id: int) -> String:
	return SAVE_DIR + "save_slot_%d.json" % slot_id

## 获取存档槽信息
static func get_slot_info(slot_id: int) -> SaveSlotInfo:
	if slot_id < 0 or slot_id >= MAX_SLOTS:
		return null
	
	var file_path = get_slot_file_path(slot_id)
	var is_empty = not FileAccess.file_exists(file_path)
	var is_auto_save = (slot_id == AUTO_SAVE_SLOT)
	
	var info = SaveSlotInfo.new(slot_id, file_path, is_empty, is_auto_save)
	
	# 如果文件存在，读取元数据
	if not is_empty:
		var file = FileAccess.open(file_path, FileAccess.READ)
		if file:
			var json_string = file.get_as_text()
			file.close()
			
			var json = JSON.new()
			var error = json.parse(json_string)
			if error == OK:
				var data = json.data
				if data is Dictionary:
					info.timestamp = data.get("timestamp", "")
					info.location = data.get("location", "未知位置")
					# 计算游戏时长（简化处理）
					info.play_time = "未知时长"
	
	return info

## 获取所有存档槽信息
static func get_all_slot_info() -> Array[SaveSlotInfo]:
	var slots: Array[SaveSlotInfo] = []
	for i in range(MAX_SLOTS):
		slots.append(get_slot_info(i))
	return slots

## 检查槽位是否为空
static func is_slot_empty(slot_id: int) -> bool:
	if slot_id < 0 or slot_id >= MAX_SLOTS:
		return true
	return not FileAccess.file_exists(get_slot_file_path(slot_id))

## 检查是否为自动保存槽
static func is_slot_auto_save(slot_id: int) -> bool:
	return slot_id == AUTO_SAVE_SLOT

## 检查是否为手动保存槽
static func is_slot_manual_save(slot_id: int) -> bool:
	return slot_id in MANUAL_SAVE_SLOTS

## 获取空闲的手动槽位
static func get_empty_manual_slot() -> int:
	for slot_id in MANUAL_SAVE_SLOTS:
		if is_slot_empty(slot_id):
			return slot_id
	return -1  # 无空闲槽位

## 检查手动槽位是否已满
static func is_manual_slots_full() -> bool:
	return get_empty_manual_slot() == -1

## 获取需要覆盖的槽位列表
static func get_overwritable_slots() -> Array[int]:
	var slots: Array[int] = []
	for slot_id in MANUAL_SAVE_SLOTS:
		if not is_slot_empty(slot_id):
			slots.append(slot_id)
	return slots

## 删除存档槽
static func delete_slot(slot_id: int) -> bool:
	# 自动保存槽不可删除
	if is_slot_auto_save(slot_id):
		return false
	
	if slot_id < 0 or slot_id >= MAX_SLOTS:
		return false
	
	var file_path = get_slot_file_path(slot_id)
	if FileAccess.file_exists(file_path):
		DirAccess.remove_absolute(file_path)
		return true
	
	return false

## 获取存档槽统计
static func get_slot_statistics() -> Dictionary:
	var empty_count = 0
	var manual_count = 0
	var auto_save_exists = false
	
	for i in range(MAX_SLOTS):
		if is_slot_empty(i):
			empty_count += 1
		elif is_slot_auto_save(i):
			auto_save_exists = true
		else:
			manual_count += 1
	
	return {
		"total_slots": MAX_SLOTS,
		"empty_slots": empty_count,
		"manual_slots_used": manual_count,
		"auto_save_exists": auto_save_exists,
		"manual_slots_available": MANUAL_SAVE_SLOTS.size() - manual_count
	}

## 保存游戏到自动存档槽
func save_game() -> bool:
	var game_manager = get_parent()
	if not game_manager or not game_manager.has_method("get_system"):
		push_error("[SaveSlotManager] GameManager not found")
		return false
	
	# 收集游戏状态
	var save_data = _collect_game_state(game_manager)
	
	# 使用SaveSystem保存
	var save_system = game_manager.get_system("SaveSystem")
	if save_system:
		return save_system.save_to_slot(AUTO_SAVE_SLOT, save_data)
	else:
		# 直接保存
		return _save_to_file(AUTO_SAVE_SLOT, save_data)

## 从自动存档槽加载游戏
func load_game() -> bool:
	var game_manager = get_parent()
	if not game_manager or not game_manager.has_method("get_system"):
		push_error("[SaveSlotManager] GameManager not found")
		return false
	
	# 使用SaveSystem加载
	var save_system = game_manager.get_system("SaveSystem")
	var load_result: Dictionary
	
	if save_system:
		load_result = save_system.load_from_slot(AUTO_SAVE_SLOT)
	else:
		# 直接加载
		load_result = _load_from_file(AUTO_SAVE_SLOT)
	
	if not load_result.get("success", false):
		push_error("[SaveSlotManager] Load failed: " + load_result.get("error_message", "Unknown error"))
		return false
	
	# 恢复游戏状态
	return _restore_game_state(game_manager, load_result.get("data", {}))

## 收集游戏状态
func _collect_game_state(game_manager: Node) -> Dictionary:
	var state: Dictionary = {
		"version": "1.0",
		"timestamp": Time.get_datetime_string_from_system(),
		"player": {},
		"world": {},
		"quests": {},
		"cards": {},
		"npcs": {},
		"settings": {}
	}
	
	# 收集玩家状态
	state["player"] = {
		"health": game_manager.get("player_health") if game_manager.get("player_health") else 100,
		"max_health": game_manager.get("player_max_health") if game_manager.get("player_max_health") else 100,
		"mana": game_manager.get("player_mana") if game_manager.get("player_mana") else 100,
		"max_mana": game_manager.get("player_max_mana") if game_manager.get("player_max_mana") else 100,
		"gold": game_manager.get("player_gold") if game_manager.get("player_gold") else 0,
		"experience": game_manager.get("player_experience") if game_manager.get("player_experience") else 0,
		"level": game_manager.get("player_level") if game_manager.get("player_level") else 1,
		"attack": game_manager.get("player_attack") if game_manager.get("player_attack") else 10,
		"defense": game_manager.get("player_defense") if game_manager.get("player_defense") else 5,
		"current_area": game_manager.get("current_area") if game_manager.get("current_area") else "forest",
		"first_battle_completed": game_manager.get("first_battle_completed") if game_manager.get("first_battle_completed") else false
	}
	
	# 收集世界状态
	var world_state_manager = game_manager.get_system("WorldStateManager")
	if world_state_manager and world_state_manager.has_method("to_dict"):
		state["world"] = world_state_manager.to_dict()
	
	# 收集任务状态
	var quest_system = game_manager.get_system("QuestSystem")
	if quest_system and quest_system.has_method("to_dict"):
		state["quests"] = quest_system.to_dict()
	
	# 收集卡牌状态
	var deck_manager = game_manager.get_system("DeckBuildingManager")
	if deck_manager and deck_manager.has_method("to_dict"):
		state["cards"] = deck_manager.to_dict()
	
	# 收集NPC状态
	var npc_manager = game_manager.get_system("NPCManager")
	if npc_manager and npc_manager.has_method("to_dict"):
		state["npcs"] = npc_manager.to_dict()
	
	return state

## 恢复游戏状态
func _restore_game_state(game_manager: Node, data: Dictionary) -> bool:
	# 恢复玩家状态
	var player_data = data.get("player", {})
	game_manager.set("player_health", player_data.get("health", 100))
	game_manager.set("player_max_health", player_data.get("max_health", 100))
	game_manager.set("player_mana", player_data.get("mana", 100))
	game_manager.set("player_max_mana", player_data.get("max_mana", 100))
	game_manager.set("player_gold", player_data.get("gold", 0))
	game_manager.set("player_experience", player_data.get("experience", 0))
	game_manager.set("player_level", player_data.get("level", 1))
	game_manager.set("player_attack", player_data.get("attack", 10))
	game_manager.set("player_defense", player_data.get("defense", 5))
	game_manager.set("current_area", player_data.get("current_area", "forest"))
	game_manager.set("first_battle_completed", player_data.get("first_battle_completed", false))
	
	# 恢复世界状态
	var world_state_manager = game_manager.get_system("WorldStateManager")
	if world_state_manager and world_state_manager.has_method("load_from_dict"):
		world_state_manager.load_from_dict(data.get("world", {}))
	
	# 恢复任务状态
	var quest_system = game_manager.get_system("QuestSystem")
	if quest_system and quest_system.has_method("load_from_dict"):
		quest_system.load_from_dict(data.get("quests", {}))
	
	# 恢复卡牌状态
	var deck_manager = game_manager.get_system("DeckBuildingManager")
	if deck_manager and deck_manager.has_method("load_from_dict"):
		deck_manager.load_from_dict(data.get("cards", {}))
	
	# 恢复NPC状态
	var npc_manager = game_manager.get_system("NPCManager")
	if npc_manager and npc_manager.has_method("load_from_dict"):
		npc_manager.load_from_dict(data.get("npcs", {}))
	
	print("[SaveSlotManager] Game state restored successfully")
	return true

## 直接保存到文件
func _save_to_file(slot_id: int, save_data: Dictionary) -> bool:
	init_save_directory()
	var file_path = get_slot_file_path(slot_id)
	var json_string = JSON.stringify(save_data, "\t")
	
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		push_error("[SaveSlotManager] Cannot open file for writing: " + file_path)
		return false
	
	file.store_string(json_string)
	file.close()
	print("[SaveSlotManager] Saved to slot: ", slot_id)
	return true

## 直接从文件加载
func _load_from_file(slot_id: int) -> Dictionary:
	var file_path = get_slot_file_path(slot_id)
	
	if not FileAccess.file_exists(file_path):
		return {"success": false, "error_message": "Slot is empty"}
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return {"success": false, "error_message": "Cannot open file for reading"}
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_string)
	if error != OK:
		return {"success": false, "error_message": "JSON parse error: " + json.get_error_message()}
	
	var data = json.data
	if data is not Dictionary:
		return {"success": false, "error_message": "Invalid save data format"}
	
	return {"success": true, "data": data}
