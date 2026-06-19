## UI管理器
## 管理游戏中的所有UI界面
class_name UIManager
extends Node

## 游戏配置资源路径
const GAME_CONFIG_PATH: String = "res://src/resources/game_config.tres"

# 依赖注入
@export var game_config: GameConfig

## UI层级字典（键为层级名称，值为对应的CanvasLayer节点）
var ui_layers: Dictionary[String, CanvasLayer] = {}

## 当前打开的UI列表
var open_uis: Array[String] = []

## 信号：UI被打开
signal ui_opened(ui_name: String)

## 信号：UI被关闭
signal ui_closed(ui_name: String)

func _ready() -> void:
	initialize()

## 初始化UI管理器
## 加载游戏配置并创建UI层级结构
func initialize() -> void:
	_load_game_config()
	_create_ui_layers()
	print("[UIManager] Initialized")

## 加载游戏配置
## 尝试从资源文件加载GameConfig，如果失败则创建默认配置
func _load_game_config() -> void:
	if game_config:
		return
	
	# 尝试从资源文件加载
	if ResourceLoader.exists(GAME_CONFIG_PATH):
		var config: GameConfig = load(GAME_CONFIG_PATH) as GameConfig
		if config:
			game_config = config
			return
	
	# 创建默认配置
	game_config = GameConfig.new()
	push_warning("[UIManager] Using default GameConfig")

## 设置GameConfig依赖
func set_game_config(config: GameConfig) -> void:
	game_config = config

## 创建UI层级
## 根据GameConfig中的ui_layers配置创建对应的CanvasLayer层级
func _create_ui_layers() -> void:
	var layer_names: Array[String] = game_config.ui_layers
	var layer_index: int = 10
	
	for layer_name in layer_names:
		var layer = CanvasLayer.new()
		layer.name = layer_name.capitalize() + "UILayer"
		layer.layer = layer_index
		add_child(layer)
		ui_layers[layer_name] = layer
		layer_index += 10

## 打开UI
## [param ui_name] 要打开的UI名称
## [param layer] UI层级名称，默认使用配置中的第一个层级
## [return] 是否成功打开
func open_ui(ui_name: String, layer: String = "") -> bool:
	if layer.is_empty():
		layer = game_config.ui_layers[0] if game_config.ui_layers.size() > 0 else "base"
	if ui_name in open_uis:
		push_warning("[UIManager] UI already open: " + ui_name)
		return false
	
	var ui_layer = ui_layers.get(layer)
	if not ui_layer:
		push_warning("[UIManager] UI layer not found: " + layer)
		return false
	
	# TODO: 加载并显示UI
	
	open_uis.append(ui_name)
	ui_opened.emit(ui_name)
	print("[UIManager] Opened UI: ", ui_name)
	return true

## 关闭UI
func close_ui(ui_name: String) -> bool:
	if not ui_name in open_uis:
		push_warning("[UIManager] UI not open: " + ui_name)
		return false
	
	# TODO: 隐藏并移除UI
	
	open_uis.erase(ui_name)
	ui_closed.emit(ui_name)
	print("[UIManager] Closed UI: ", ui_name)
	return true

## 关闭所有UI
func close_all_uis() -> void:
	for ui_name in open_uis.duplicate():
		close_ui(ui_name)

## 检查UI是否打开
func is_ui_open(ui_name: String) -> bool:
	return ui_name in open_uis

## 获取打开的UI列表
func get_open_uis() -> Array[String]:
	return open_uis

## 显示提示
func show_tooltip(text: String, position: Vector2) -> void:
	# TODO: 实现提示显示
	print("[UIManager] Tooltip: ", text)

## 隐藏提示
func hide_tooltip() -> void:
	# TODO: 实现提示隐藏
	pass

## 显示确认对话框
func show_confirm_dialog(title: String, message: String, callback: Callable) -> void:
	# TODO: 实现确认对话框
	print("[UIManager] Confirm dialog: ", title)

## 显示警告对话框
func show_alert_dialog(title: String, message: String) -> void:
	# TODO: 实现警告对话框
	print("[UIManager] Alert dialog: ", title)
