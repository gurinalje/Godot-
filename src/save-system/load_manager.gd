# load_manager.gd
# Story 005: 加载功能
# Date: 2026-06-03

class_name LoadManager
extends Node

## 加载管理器
## 管理游戏的加载功能，支持从存档槽恢复游戏状态

# 信号
signal load_slot_list_requested()
signal load_slot_selected(slot_id: int)
signal load_completed(success: bool, slot_id: int)
signal load_error(error_message: String)
signal game_state_restored()

# 常量
const ALL_SAVE_SLOTS: Array[int] = [0, 1, 2, 3, 4, 5]

# 变量
var _save_system: SaveSystem  # 需要注入
var _save_slot_manager: SaveSlotManager  # 需要注入
var _is_loading: bool = false
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

# 请求加载游戏
func request_load():
	# 发送显示存档槽列表信号
	load_slot_list_requested.emit()

# 获取所有存档槽信息
func get_all_save_slots() -> Array[Dictionary]:
	var slots: Array[Dictionary] = []
	
	for slot_id in ALL_SAVE_SLOTS:
		var slot_info = _save_slot_manager.get_slot_info(slot_id)
		slots.append({
			"slot_id": slot_id,
			"is_empty": slot_info.is_empty,
			"is_auto_save": slot_info.is_auto_save,
			"timestamp": slot_info.timestamp,
			"play_time": slot_info.play_time,
			"location": slot_info.location
		})
	
	return slots

# 选择存档槽
func select_slot(slot_id: int):
	if slot_id not in ALL_SAVE_SLOTS:
		load_error.emit("无效的存档槽位")
		return
	
	_selected_slot = slot_id
	load_slot_selected.emit(slot_id)
	
	# 检查槽位是否为空
	if _save_slot_manager.is_slot_empty(slot_id):
		load_error.emit("该槽位无存档")
		return
	
	# 执行加载
	_perform_load(slot_id)

# 执行加载
func _perform_load(slot_id: int):
	if _save_system == null:
		load_error.emit("存档系统未初始化")
		return
	
	_is_loading = true
	
	# 从指定槽位加载
	var result = _save_system.load_from_slot(slot_id)
	
	_is_loading = false
	_selected_slot = -1
	
	if result.success:
		# 恢复游戏状态
		_restore_game_state(result.data)
		load_completed.emit(true, slot_id)
		game_state_restored.emit()
	else:
		load_error.emit(result.error_message)

# 恢复游戏状态
func _restore_game_state(save_data: Dictionary):
	# 这里应该将save_data分发到各个系统
	# 暂时只是打印日志
	print("LoadManager: Restoring game state from save data")
	print("Save data keys: ", save_data.keys())

# 检查是否正在加载
func is_loading() -> bool:
	return _is_loading

# 获取选中的槽位
func get_selected_slot() -> int:
	return _selected_slot

# 取消加载
func cancel_load():
	_selected_slot = -1
	_is_loading = false

# 获取有存档的槽位数量
func get_filled_slot_count() -> int:
	var count = 0
	for slot_id in ALL_SAVE_SLOTS:
		if not _save_slot_manager.is_slot_empty(slot_id):
			count += 1
	return count

# 检查是否有存档
func has_save_data() -> bool:
	return get_filled_slot_count() > 0

# 获取自动存档信息
func get_auto_save_info() -> Dictionary:
	var slot_info = _save_slot_manager.get_slot_info(0)
	return {
		"slot_id": 0,
		"is_empty": slot_info.is_empty,
		"timestamp": slot_info.timestamp,
		"play_time": slot_info.play_time,
		"location": slot_info.location
	}

# 获取手动存档信息
func get_manual_save_infos() -> Array[Dictionary]:
	var slots: Array[Dictionary] = []
	
	for slot_id in range(1, 6):
		var slot_info = _save_slot_manager.get_slot_info(slot_id)
		slots.append({
			"slot_id": slot_id,
			"is_empty": slot_info.is_empty,
			"timestamp": slot_info.timestamp,
			"play_time": slot_info.play_time,
			"location": slot_info.location
		})
	
	return slots
