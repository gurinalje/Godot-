# 输入映射配置 - 管理输入动作和上下文
# 负责输入映射的配置、保存和加载

class_name InputMapping
extends Node

## 输入动作配置
var action_configs: Dictionary = {}

## 上下文允许的动作
var context_actions: Dictionary = {
	InputManager.InputContext.EXPLORATION: [
		"move_up", "move_down", "move_left", "move_right",
		"confirm", "cancel", "open_deck", "open_menu"
	],
	InputManager.InputContext.COMBAT: [
		"select_card", "play_card", "select_target", "end_turn",
		"open_deck", "open_menu"
	],
	InputManager.InputContext.DIALOGUE: [
		"confirm", "cancel", "open_menu"
	],
	InputManager.InputContext.MENU: [
		"confirm", "cancel", "open_menu"
	]
}

## 默认输入映射
const DEFAULT_MAPPINGS: Dictionary = {
	"play_card": {
		"keyboard": KEY_SPACE,
		"mouse": MOUSE_BUTTON_LEFT,
		"gamepad": JOY_BUTTON_A
	},
	"select_card": {
		"keyboard": [KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT],
		"mouse": "mouse_motion",
		"gamepad": JOY_AXIS_LEFT_X
	},
	"select_target": {
		"keyboard": KEY_TAB,
		"mouse": MOUSE_BUTTON_RIGHT,
		"gamepad": JOY_BUTTON_X
	},
	"end_turn": {
		"keyboard": KEY_ENTER,
		"gamepad": JOY_BUTTON_Y
	},
	"open_deck": {
		"keyboard": KEY_D,
		"gamepad": JOY_BUTTON_LEFT_SHOULDER
	},
	"open_menu": {
		"keyboard": KEY_ESCAPE,
		"gamepad": JOY_BUTTON_START
	},
	"confirm": {
		"keyboard": KEY_ENTER,
		"mouse": MOUSE_BUTTON_LEFT,
		"gamepad": JOY_BUTTON_A
	},
	"cancel": {
		"keyboard": KEY_ESCAPE,
		"mouse": MOUSE_BUTTON_RIGHT,
		"gamepad": JOY_BUTTON_B
	},
	"move_up": {
		"keyboard": KEY_W,
		"gamepad": JOY_AXIS_LEFT_Y
	},
	"move_down": {
		"keyboard": KEY_S,
		"gamepad": JOY_AXIS_LEFT_Y
	},
	"move_left": {
		"keyboard": KEY_A,
		"gamepad": JOY_AXIS_LEFT_X
	},
	"move_right": {
		"keyboard": KEY_D,
		"gamepad": JOY_AXIS_LEFT_X
	}
}

## 初始化
func _ready() -> void:
	pass

## 设置默认输入映射
func setup_default_mappings() -> void:
	for action_name in DEFAULT_MAPPINGS:
		_register_action(action_name, DEFAULT_MAPPINGS[action_name])

## 注册输入动作
func _register_action(action_name: String, mapping: Dictionary) -> void:
	# 如果动作不存在，创建它
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	
	# 添加键盘映射
	if mapping.has("keyboard"):
		var key = mapping["keyboard"]
		if key is Array:
			for k in key:
				_add_key_mapping(action_name, k)
		else:
			_add_key_mapping(action_name, key)
	
	# 添加鼠标映射
	if mapping.has("mouse"):
		var mouse = mapping["mouse"]
		if mouse is int:
			_add_mouse_button_mapping(action_name, mouse)
	
	# 添加手柄映射
	if mapping.has("gamepad"):
		var gamepad = mapping["gamepad"]
		if gamepad is int:
			if gamepad < 100:  # 按钮
				_add_gamepad_button_mapping(action_name, gamepad)
			else:  # 轴
				_add_gamepad_axis_mapping(action_name, gamepad)

## 添加键盘映射
func _add_key_mapping(action_name: String, key_code: int) -> void:
	var event = InputEventKey.new()
	event.keycode = key_code
	InputMap.action_add_event(action_name, event)

## 添加鼠标按钮映射
func _add_mouse_button_mapping(action_name: String, button: int) -> void:
	var event = InputEventMouseButton.new()
	event.button_index = button
	InputMap.action_add_event(action_name, event)

## 添加手柄按钮映射
func _add_gamepad_button_mapping(action_name: String, button: int) -> void:
	var event = InputEventJoypadButton.new()
	event.button_index = button
	InputMap.action_add_event(action_name, event)

## 添加手柄轴映射
func _add_gamepad_axis_mapping(action_name: String, axis: int) -> void:
	var event = InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = 1.0
	InputMap.action_add_event(action_name, event)

## 检查动作在上下文中是否允许
func is_action_allowed_in_context(action_name: String, context: InputManager.InputContext) -> bool:
	if not context_actions.has(context):
		return false
	
	return action_name in context_actions[context]

## 获取所有动作
func get_all_actions() -> Array[String]:
	var actions: Array[String] = []
	for action_name in DEFAULT_MAPPINGS:
		actions.append(action_name)
	return actions

## 获取当前上下文的所有可用动作
func get_context_actions(context: InputManager.InputContext) -> Array[String]:
	if not context_actions.has(context):
		return []
	
	return context_actions[context]

## 重新映射输入
func remap_action(action_name: String, old_event: InputEvent, new_event: InputEvent) -> void:
	# 移除旧映射
	if InputMap.has_action(action_name):
		InputMap.action_erase_event(action_name, old_event)
	
	# 添加新映射
	InputMap.action_add_event(action_name, new_event)

## 保存输入配置
func save_input_config() -> void:
	var config = ConfigFile.new()
	
	# 保存所有动作的映射
	for action_name in DEFAULT_MAPPINGS:
		if InputMap.has_action(action_name):
			var events = InputMap.action_get_events(action_name)
			config.set_value("input", action_name, events)
	
	# 保存到文件
	config.save("user://input_config.cfg")

## 加载输入配置
func load_input_config() -> void:
	var config = ConfigFile.new()
	
	# 加载配置文件
	if config.load("user://input_config.cfg") != OK:
		print("No input config found, using defaults")
		return
	
	# 清除现有映射
	for action_name in DEFAULT_MAPPINGS:
		if InputMap.has_action(action_name):
			InputMap.action_erase_events(action_name)
	
	# 加载映射
	for action_name in config.get_section_keys("input"):
		var events = config.get_value("input", action_name)
		for event in events:
			InputMap.action_add_event(action_name, event)

## 重置为默认映射
func reset_to_defaults() -> void:
	# 清除所有自定义映射
	for action_name in DEFAULT_MAPPINGS:
		if InputMap.has_action(action_name):
			InputMap.action_erase_events(action_name)
	
	# 重新设置默认映射
	setup_default_mappings()
