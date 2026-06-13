## 主场景入口
## 游戏启动时加载，初始化所有系统

class_name Main
extends Node

# 系统管理器
var system_managers: Dictionary = {}

# 加载进度
var loading_progress: float = 0.0
var is_loading: bool = false
var total_systems: int = 0
var loaded_systems: int = 0

# 信号
signal systems_initialized()
signal loading_complete()

# UI引用
@onready var loading_bar: ProgressBar = $LoadingScreen/VBoxContainer/LoadingBar
@onready var loading_label: Label = $LoadingScreen/VBoxContainer/LoadingLabel
@onready var loading_screen: Control = $LoadingScreen

func _ready() -> void:
	print("[Main] Game starting...")
	
	# 初始化系统
	_initialize_systems()

## 初始化系统
func _initialize_systems() -> void:
	print("[Main] Initializing systems...")
	is_loading = true
	
	# 更新加载状态
	_update_loading_status("Initializing systems...", 0.0)
	
	# 等待GameManager初始化完成
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager and not game_manager.is_initialized():
		# 等待GameManager的所有系统初始化完成
		await game_manager.game_initialized
	
	# 更新进度
	_update_loading_status("Loading complete!", 100.0)
	is_loading = false
	
	print("[Main] All systems initialized")
	systems_initialized.emit()
	
	# 等待一小段时间后切换到主菜单
	await get_tree().create_timer(0.5).timeout
	_load_main_menu()

## 更新加载状态
func _update_loading_status(text: String, progress: float) -> void:
	if loading_label:
		loading_label.text = text
	if loading_bar:
		loading_bar.value = progress
	print("[Main] Loading: ", text, " - ", progress, "%")

## 加载主菜单
func _load_main_menu() -> void:
	print("[Main] Loading main menu...")
	# 隐藏加载屏幕
	if loading_screen:
		loading_screen.visible = false
	# 切换到主菜单场景
	get_tree().change_scene_to_file("res://src/scenes/main_menu.tscn")

## 获取系统管理器
func get_manager(manager_name: String) -> Node:
	return system_managers.get(manager_name)

## 重新加载游戏
func reload_game() -> void:
	print("[Main] Reloading game...")
	
	# 清除所有管理器
	for manager in system_managers.values():
		manager.queue_free()
	system_managers.clear()
	
	# 重新初始化
	_initialize_systems()
	
	# 等待系统初始化完成
	await systems_initialized
	
	# 重新加载主菜单
	_load_main_menu()
