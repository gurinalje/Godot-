## 主菜单场景
## 游戏入口，提供新游戏、继续游戏、设置等选项

class_name MainMenu
extends Control

# UI引用
@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var new_game_button: Button = $VBoxContainer/NewGameButton
@onready var continue_button: Button = $VBoxContainer/ContinueButton
@onready var settings_button: Button = $VBoxContainer/SettingsButton
@onready var quit_button: Button = $VBoxContainer/QuitButton
@onready var version_label: Label = $VersionLabel

func _ready() -> void:
	print("[MainMenu] Ready")
	
	# 设置UI
	_setup_ui()
	
	# 连接信号
	_connect_signals()
	
	# 检查是否有存档
	_check_save_data()

## 设置UI
func _setup_ui() -> void:
	# 设置标题
	title_label.text = "命运卡牌局"
	
	# 设置按钮文本
	new_game_button.text = "新游戏"
	continue_button.text = "继续游戏"
	settings_button.text = "设置"
	quit_button.text = "退出"
	
	# 设置版本号
	version_label.text = "v0.1.0"

## 连接信号
func _connect_signals() -> void:
	new_game_button.pressed.connect(_on_new_game_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

## 检查存档数据
func _check_save_data() -> void:
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager and game_manager.has_method("has_save_data"):
		var has_save = game_manager.has_save_data()
		continue_button.disabled = not has_save
		if not has_save:
			continue_button.modulate = Color(0.5, 0.5, 0.5, 0.5)
	else:
		# 如果没有存档数据，禁用继续按钮
		continue_button.disabled = true
		continue_button.modulate = Color(0.5, 0.5, 0.5, 0.5)

## 新游戏按钮按下
func _on_new_game_pressed() -> void:
	print("[MainMenu] Starting new game...")
	get_tree().change_scene_to_file("res://src/scenes/world_exploration.tscn")

## 继续游戏按钮按下
func _on_continue_pressed() -> void:
	print("[MainMenu] Loading save data...")
	
	# 加载存档数据
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		var save_manager = game_manager.get_system("SaveSlotManager")
		if save_manager and save_manager.has_method("load_game"):
			var success = save_manager.load_game()
			if success:
				print("[MainMenu] Save data loaded successfully")
			else:
				push_warning("[MainMenu] Failed to load save data")
	
	# 切换到探索场景
	get_tree().change_scene_to_file("res://src/scenes/world_exploration.tscn")

## 设置按钮按下
func _on_settings_pressed() -> void:
	print("[MainMenu] Opening settings...")

## 退出按钮按下
func _on_quit_pressed() -> void:
	print("[MainMenu] Quitting game...")
	get_tree().quit()
