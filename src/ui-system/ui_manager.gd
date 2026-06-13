## UI管理器
## 管理游戏中的所有UI界面

class_name UIManager
extends Node

# UI层级
var ui_layers: Dictionary = {}

# 当前打开的UI
var open_uis: Array[String] = []

# 信号
signal ui_opened(ui_name: String)
signal ui_closed(ui_name: String)

func _ready() -> void:
	initialize()

func initialize() -> void:
	print("[UIManager] Initialized")
	_create_ui_layers()

## 创建UI层级
func _create_ui_layers() -> void:
	# 创建基础层级
	var base_layer = CanvasLayer.new()
	base_layer.name = "BaseUILayer"
	base_layer.layer = 10
	add_child(base_layer)
	ui_layers["base"] = base_layer
	
	# 创建弹窗层级
	var popup_layer = CanvasLayer.new()
	popup_layer.name = "PopupUILayer"
	popup_layer.layer = 20
	add_child(popup_layer)
	ui_layers["popup"] = popup_layer
	
	# 创建提示层级
	var tooltip_layer = CanvasLayer.new()
	tooltip_layer.name = "TooltipUILayer"
	tooltip_layer.layer = 30
	add_child(tooltip_layer)
	ui_layers["tooltip"] = tooltip_layer

## 打开UI
func open_ui(ui_name: String, layer: String = "base") -> bool:
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
