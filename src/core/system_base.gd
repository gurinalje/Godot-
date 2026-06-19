## SystemBase - 所有游戏系统的抽象基类
## 定义系统生命周期、存档/读档、重置的契约
class_name SystemBase
extends Node

## 系统初始化完成信号
signal system_initialized()
## 系统错误信号
signal system_error(error_message: String)

## 系统是否已初始化
var is_initialized: bool = false

## 系统初始化（子类必须重写）
func initialize() -> void:
	is_initialized = true
	system_initialized.emit()

## 系统重置（子类必须重写）
func reset() -> void:
	is_initialized = false

## 保存系统数据（子类必须重写）
## 返回: 包含系统状态的Dictionary
func save_data() -> Dictionary:
	return {}

## 加载系统数据（子类必须重写）
## 参数: data - 包含系统状态的Dictionary
func load_data(data: Dictionary) -> void:
	pass

## 获取系统名称（子类必须重写）
func get_system_name() -> String:
	return "SystemBase"

## 报告系统错误
func _report_error(message: String) -> void:
	push_error("[" + get_system_name() + "] " + message)
	system_error.emit(message)

## 报告系统警告
func _report_warning(message: String) -> void:
	push_warning("[" + get_system_name() + "] " + message)