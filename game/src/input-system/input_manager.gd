# input_manager.gd
# 输入管理器单例
# 处理所有输入事件，支持键位映射和输入缓冲

class_name InputManager
extends Node

## 信号：动作触发
signal action_pressed(action_id: String)
signal action_released(action_id: String)

## 信号：按键绑定改变
signal key_binding_changed(action_id: String, new_key: Key)

## 输入上下文枚举
enum InputContext {
	EXPLORATION,  ## 探索状态
	COMBAT,       ## 战斗状态
	DIALOGUE,     ## 对话状态
	MENU          ## 菜单状态
}

## 当前输入上下文
var current_context = InputContext.EXPLORATION

## 所有输入动作
var actions: Dictionary = {}  # action_id -> InputAction

## 输入缓冲队列
var input_buffer: Array[Dictionary] = []
const BUFFER_SIZE: int = 2
const BUFFER_WINDOW: float = 0.1  # 100ms缓冲窗口

## 上下文激活状态
var context_active: Dictionary = {
	InputContext.EXPLORATION: true,
	InputContext.COMBAT: true,
	InputContext.DIALOGUE: false,
	InputContext.MENU: false
}

## 初始化
func _ready() -> void:
	_initialize_default_actions()

## 初始化默认按键绑定
func _initialize_default_actions() -> void:
	# 移动相关
	_register_action("move_up", "向上移动", InputAction.ActionType.MOVEMENT, KEY_W)
	_register_action("move_down", "向下移动", InputAction.ActionType.MOVEMENT, KEY_S)
	_register_action("move_left", "向左移动", InputAction.ActionType.MOVEMENT, KEY_A)
	_register_action("move_right", "向右移动", InputAction.ActionType.MOVEMENT, KEY_D)
	
	# 战斗相关
	_register_action("play_card", "打出卡牌", InputAction.ActionType.COMBAT, KEY_SPACE)
	_register_action("select_card", "选择卡牌", InputAction.ActionType.COMBAT, KEY_TAB)
	_register_action("select_target", "选择目标", InputAction.ActionType.COMBAT, KEY_ENTER)
	_register_action("end_turn", "结束回合", InputAction.ActionType.COMBAT, KEY_E)
	
	# UI相关
	_register_action("confirm", "确认", InputAction.ActionType.UI, KEY_ENTER)
	_register_action("cancel", "取消", InputAction.ActionType.UI, KEY_ESCAPE)
	_register_action("menu", "菜单", InputAction.ActionType.UI, KEY_ESCAPE)
	
	# 系统相关
	_register_action("save", "保存", InputAction.ActionType.SYSTEM, KEY_F5)
	_register_action("load", "加载", InputAction.ActionType.SYSTEM, KEY_F9)

## 注册新动作
func _register_action(action_id: String, action_name: String, type: InputAction.ActionType, key: Key, continuous_press: bool = false) -> void:
	actions[action_id] = InputAction.new(action_id, action_name, type, key, continuous_press)

## 输入处理
func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed:
			_handle_key_pressed(key_event.keycode)
		else:
			_handle_key_released(key_event.keycode)

## 处理按键按下
func _handle_key_pressed(key: Key) -> void:
	# 检查所有动作
	for action in actions.values():
		if action.matches_key(key) and _is_action_active(action):
			# 添加到输入缓冲
			_add_to_buffer(action.action_id)
			# 触发信号
			action_pressed.emit(action.action_id)

## 处理按键释放
func _handle_key_released(key: Key) -> void:
	for action in actions.values():
		if action.matches_key(key) and _is_action_active(action):
			action_released.emit(action.action_id)

## 检查动作是否在当前上下文中激活
func _is_action_active(action: InputAction) -> bool:
	# 系统动作始终激活
	if action.action_type == InputAction.ActionType.SYSTEM:
		return true
	
	# 检查上下文
	match current_context:
		InputContext.EXPLORATION:
			return action.action_type == InputAction.ActionType.MOVEMENT or action.action_type == InputAction.ActionType.UI
		InputContext.COMBAT:
			return action.action_type == InputAction.ActionType.COMBAT or action.action_type == InputAction.ActionType.UI
		InputContext.DIALOGUE:
			return action.action_type == InputAction.ActionType.UI
		InputContext.MENU:
			return action.action_type == InputAction.ActionType.UI
	
	return false

## 添加到输入缓冲
func _add_to_buffer(action_id: String) -> void:
	var timestamp: float = Time.get_ticks_msec() / 1000.0
	input_buffer.append({
		"action_id": action_id,
		"timestamp": timestamp
	})
	
	# 保持缓冲大小
	if input_buffer.size() > BUFFER_SIZE:
		input_buffer.pop_front()

## 检查缓冲中是否有指定动作
func is_action_buffered(action_id: String) -> bool:
	var current_time: float = Time.get_ticks_msec() / 1000.0
	
	for entry in input_buffer:
		if entry["action_id"] == action_id:
			if current_time - entry["timestamp"] <= BUFFER_WINDOW:
				return true
	
	return false

## 清空输入缓冲
func clear_buffer() -> void:
	input_buffer.clear()

## ==================== 上下文管理 ====================

## 设置输入上下文
func set_context(context: InputContext) -> void:
	current_context = context
	clear_buffer()  # 切换上下文时清空缓冲

## 获取当前上下文
func get_context() -> InputContext:
	return current_context

## ==================== 按键绑定管理 ====================

## 重新绑定按键
func rebind_action(action_id: String, new_key: Key) -> bool:
	if not actions.has(action_id):
		return false
	
	# 检查按键冲突
	for action in actions.values():
		if action.current_key == new_key and action.action_id != action_id:
			push_warning("InputManager: Key %s already bound to %s" % [OS.get_keycode_string(new_key), action.action_id])
			return false
	
	# 设置新按键
	actions[action_id].current_key = new_key
	key_binding_changed.emit(action_id, new_key)
	return true

## 重置所有按键为默认
func reset_all_bindings() -> void:
	for action in actions.values():
		action.reset_to_default()

## 获取动作的当前按键
func get_action_key(action_id: String) -> Key:
	if actions.has(action_id):
		return actions[action_id].current_key
	return KEY_NONE

## 检查动作是否被按下
func is_action_pressed(action_id: String) -> bool:
	if not actions.has(action_id):
		return false
	return Input.is_key_pressed(actions[action_id].current_key)

## ==================== 序列化 ====================

## 保存按键绑定
func save_bindings() -> Dictionary:
	var bindings: Dictionary = {}
	for action_id in actions:
		bindings[action_id] = actions[action_id].current_key
	return bindings

## 加载按键绑定
func load_bindings(bindings: Dictionary) -> void:
	for action_id in bindings:
		if actions.has(action_id):
			actions[action_id].current_key = bindings[action_id]
