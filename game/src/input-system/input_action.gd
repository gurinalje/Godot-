# input_action.gd
# 输入动作资源类
# 定义单个输入动作的所有属性

@tool
class_name InputAction
extends RefCounted

## 动作类型枚举
enum ActionType {
	MOVEMENT,    ## 移动相关
	COMBAT,      ## 战斗相关
	UI,          ## 界面相关
	SYSTEM       ## 系统相关
}

## 动作ID
var action_id: String

## 动作名称
var action_name: String

## 动作类型
var action_type: ActionType

## 默认按键
var default_key: Key

## 当前绑定按键
var current_key: Key

## 是否为continuous_press
var is_continuous_press: bool

## 是否在上下文中激活
var is_active: bool = true

## 初始化
func _init(id: String, name: String, type: ActionType, key: Key,continuous_press: bool = false) -> void:
	action_id = id
	action_name = name
	action_type = type
	default_key = key
	current_key = key
	is_continuous_press = continuous_press

## 重置为默认按键
func reset_to_default() -> void:
	current_key = default_key

## 获取按键名称
func get_key_name() -> String:
	return OS.get_keycode_string(current_key)

## 检查是否匹配按键
func matches_key(key: Key) -> bool:
	return current_key == key and is_active

## 序列化为字典
func to_dict() -> Dictionary:
	return {
		"action_id": action_id,
		"action_name": action_name,
		"action_type": action_type,
		"current_key": current_key,
		"is_continuous_press": is_continuous_press
	}

## 从字典反序列化
static func from_dict(data: Dictionary) -> InputAction:
	var action: InputAction = InputAction.new(
		data.get("action_id", ""),
		data.get("action_name", ""),
		data.get("action_type", ActionType.SYSTEM),
		data.get("current_key", KEY_NONE),
		data.get("is_continuous_press", false)
	)
	return action
