# manual_save_manager.gd
# Story 004: 手动保存功能
# Date: 2026-06-03

class_name ManualSaveManager
extends Node

## 手动保存管理器
## 管理玩家的手动保存功能，支持槽位选择和覆盖确认

# 信号
signal save_slot_list_requested()
signal save_slot_selected(slot_id: int)
signal save_confirmation_required(slot_id: int)
signal save_completed(success: bool, slot_id: int)
signal save_error(error_message: String)

# 常量
const MANUAL_SAVE_SLOTS: Array[int] = [1, 2, 3, 4, 5]

# 变量
var _save_system: SaveSystem  # 需要注入
var _save_slot_manager: SaveSlotManager  # 需要注入
var _is_saving: bool = false
var _selected_slot: int = -1

# 初始化
func _ready():
	pass

# 设置存档系统
func set_save_system(save_system: SaveSystem):
	_save_system = save_system

# 设置存档槽管理器
func set_save_slot_manager(save_slot_manager: SaveSlotManager):
	_save_slot_manager = save_slot_manager

# 请求保存游戏
func request_save():
	# 发送显示存档槽列表信号
	save_slot_list_requested.emit()

# 获取手动存档槽信息
func get_manual_save_slots() -> Array[Dictionary]:
	var slots: Array[Dictionary] = []
	
	for slot_id in MANUAL_SAVE_SLOTS:
		var slot_info = _save_slot_manager.get_slot_info(slot_id)
		slots.append({
			"slot_id": slot_id,
			"is_empty": slot_info.is_empty,
			"timestamp": slot_info.timestamp,
			"play_time": slot_info.play_time,
			"location": slot_info.location
		})
	
	return slots

# 选择存档槽
func select_slot(slot_id: int):
	if slot_id not in MANUAL_SAVE_SLOTS:
		save_error.emit("无效的存档槽位")
		return
	
	_selected_slot = slot_id
	save_slot_selected.emit(slot_id)
	
	# 检查是否需要覆盖确认
	if not _save_slot_manager.is_slot_empty(slot_id):
		save_confirmation_required.emit(slot_id)
	else:
		# 直接保存
		_perform_save(slot_id)

# 确认覆盖保存
func confirm_overwrite():
	if _selected_slot == -1:
		save_error.emit("未选择存档槽位")
		return
	
	_perform_save(_selected_slot)

# 取消覆盖
func cancel_overwrite():
	_selected_slot = -1

# 执行保存
func _perform_save(slot_id: int):
	if _save_system == null:
		save_error.emit("存档系统未初始化")
		return
	
	_is_saving = true
	
	# 收集游戏状态
	var save_data = _collect_game_state()
	
	# 保存到指定槽位
	var success = _save_system.save_to_slot(slot_id, save_data)
	
	_is_saving = false
	_selected_slot = -1
	
	if success:
		save_completed.emit(true, slot_id)
	else:
		save_error.emit("保存失败，请重试")

# 收集游戏状态
## 遍历GameManager中的所有系统，调用它们的save_data()方法收集状态
func _collect_game_state() -> Dictionary:
	var save_data: Dictionary = {
		"systems": {}
	}
	
	# 获取GameManager单例
	var game_manager = Engine.get_singleton("GameManager")
	if game_manager == null:
		# 尝试从场景树获取
		var root = get_tree().get_root()
		if root.has_node("GameManager"):
			game_manager = root.get_node("GameManager")
	
	if game_manager == null:
		push_error("[ManualSaveManager] GameManager not found")
		return save_data
	
	# 遍历所有系统，收集有save_data方法的系统数据
	var systems: Dictionary = game_manager.systems
	for system_name in systems:
		var system = systems[system_name]
		if system != null and system.has_method("save_data"):
			var system_data: Dictionary = system.save_data()
			if not system_data.is_empty():
				save_data["systems"][system_name] = system_data
	
	# 保存玩家状态
	save_data["player"] = {
		"health": game_manager.player_health,
		"max_health": game_manager.player_max_health,
		"mana": game_manager.player_mana,
		"max_mana": game_manager.player_max_mana,
		"gold": game_manager.player_gold,
		"experience": game_manager.player_experience,
		"level": game_manager.player_level,
		"attack": game_manager.player_attack,
		"defense": game_manager.player_defense,
		"current_area": game_manager.current_area,
		"first_battle_completed": game_manager.first_battle_completed
	}
	
	return save_data

# 检查是否正在保存
func is_saving() -> bool:
	return _is_saving

# 获取选中的槽位
func get_selected_slot() -> int:
	return _selected_slot

# 取消保存
func cancel_save():
	_selected_slot = -1
	_is_saving = false

# 获取空闲槽位数量
func get_empty_slot_count() -> int:
	var count = 0
	for slot_id in MANUAL_SAVE_SLOTS:
		if _save_slot_manager.is_slot_empty(slot_id):
			count += 1
	return count

# 检查是否有空闲槽位
func has_empty_slot() -> bool:
	return get_empty_slot_count() > 0

# 获取可覆盖槽位列表
func get_overwritable_slots() -> Array[int]:
	return _save_slot_manager.get_overwritable_slots()
