# auto_save_manager.gd
# Story 003: 自动保存功能
# Date: 2026-06-03

class_name AutoSaveManager
extends Node

## 自动保存管理器
## 管理游戏的自动保存功能，支持多种触发条件

# 信号
signal auto_save_started()
signal auto_save_completed(success: bool)
signal auto_save_icon_show()

# 常量
const AUTO_SAVE_SLOT: int = 0
const AUTO_SAVE_INTERVAL: float = 300.0  # 5分钟
const DEBOUNCE_TIME: float = 2.0  # 防抖时间

# 变量
var _timer: Timer
var _debounce_timer: Timer
var _is_saving: bool = false
var _last_save_time: float = 0.0
var _save_system: SaveSystem  # 需要注入

# 初始化
func _ready():
	_init_timer()
	_init_debounce_timer()
	_connect_events()

# 初始化定时器
func _init_timer():
	_timer = Timer.new()
	_timer.wait_time = AUTO_SAVE_INTERVAL
	_timer.timeout.connect(_on_timer_timeout)
	_timer.autostart = true
	add_child(_timer)

# 初始化防抖定时器
func _init_debounce_timer():
	_debounce_timer = Timer.new()
	_debounce_timer.wait_time = DEBOUNCE_TIME
	_debounce_timer.one_shot = true
	add_child(_debounce_timer)

# 连接事件
func _connect_events():
	# 这里应该连接EventBus的信号
	# EventBus.area_entered.connect(_on_area_entered)
	# EventBus.choice_made.connect(_on_choice_made)
	# EventBus.boss_defeated.connect(_on_boss_defeated)
	pass

# 设置存档系统
func set_save_system(save_system: SaveSystem):
	_save_system = save_system

# 进入新区域时触发
func _on_area_entered():
	_trigger_auto_save("area_entered")

# 做出重要选择后触发
func _on_choice_made():
	_trigger_auto_save("choice_made")

# 击败Boss后触发
func _on_boss_defeated():
	_trigger_auto_save("boss_defeated")

# 定时器超时触发
func _on_timer_timeout():
	_trigger_auto_save("timer")

# 触发自动保存
func _trigger_auto_save(trigger: String):
	# 检查防抖
	if _debounce_timer.time_left > 0:
		return
	
	# 检查是否正在保存
	if _is_saving:
		return
	
	# 开始保存
	_start_auto_save(trigger)

# 开始自动保存
func _start_auto_save(trigger: String):
	_is_saving = true
	auto_save_started.emit()
	
	# 显示保存图标
	auto_save_icon_show.emit()
	
	# 执行保存
	var success = _perform_save(trigger)
	
	# 完成保存
	_is_saving = false
	_last_save_time = Time.get_unix_time_from_system()
	auto_save_completed.emit(success)
	
	# 启动防抖定时器
	_debounce_timer.start()

# 执行保存
func _perform_save(trigger: String) -> bool:
	if _save_system == null:
		push_error("AutoSaveManager: SaveSystem not set")
		return false
	
	# 收集游戏状态
	var save_data = _collect_game_state(trigger)
	
	# 保存到Slot 0
	return _save_system.save_to_slot(AUTO_SAVE_SLOT, save_data)

# 收集游戏状态
## 遍历GameManager中的所有系统，调用它们的save_data()方法收集状态
func _collect_game_state(trigger: String) -> Dictionary:
	var save_data: Dictionary = {
		"trigger": trigger,
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
		push_error("[AutoSaveManager] GameManager not found")
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

# 获取上次保存时间
func get_last_save_time() -> float:
	return _last_save_time

# 检查是否正在保存
func is_saving() -> bool:
	return _is_saving

# 手动触发自动保存
func trigger_manual_auto_save():
	_trigger_auto_save("manual")

# 暂停自动保存
func pause_auto_save():
	_timer.paused = true

# 恢复自动保存
func resume_auto_save():
	_timer.paused = false

# 设置自动保存间隔
func set_auto_save_interval(interval: float):
	_timer.wait_time = interval

# 获取自动保存间隔
func get_auto_save_interval() -> float:
	return _timer.wait_time
