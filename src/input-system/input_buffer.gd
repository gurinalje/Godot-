# 输入缓冲系统 - 支持Combo预输入
# 允许在动画播放期间预输入下一个动作

class_name InputBuffer
extends Node

## 缓冲窗口时间（毫秒）
const BUFFER_WINDOW_MS: int = 100

## 最大缓冲动作数量
const MAX_BUFFERED_ACTIONS: int = 2

## 缓冲的动作队列
var buffered_actions: Array[BufferedAction] = []

## 缓冲动作数据结构
class BufferedAction:
	var action_name: String
	var timestamp: int
	var consumed: bool = false
	
	func _init(p_action_name: String, p_timestamp: int) -> void:
		action_name = p_action_name
		timestamp = p_timestamp
	
	func is_valid() -> bool:
		var current_time = Time.get_ticks_msec()
		return (current_time - timestamp) < BUFFER_WINDOW_MS and not consumed

## 初始化
func _ready() -> void:
	pass

## 处理缓冲
func process_buffer(delta: float) -> void:
	# 清理过期的缓冲动作
	_clean_expired_actions()

## 添加动作到缓冲
func add_to_buffer(action_name: String) -> void:
	# 如果缓冲已满，移除最旧的动作
	if buffered_actions.size() >= MAX_BUFFERED_ACTIONS:
		buffered_actions.pop_front()
	
	# 创建新的缓冲动作
	var buffered_action = BufferedAction.new(action_name, Time.get_ticks_msec())
	buffered_actions.append(buffered_action)

## 检查是否有缓冲的动作
func has_buffered_action(action_name: String) -> bool:
	for action in buffered_actions:
		if action.action_name == action_name and action.is_valid():
			# 标记为已消费
			action.consumed = true
			return true
	return false

## 获取下一个缓冲的动作
func get_next_action() -> String:
	for action in buffered_actions:
		if action.is_valid():
			# 标记为已消费
			action.consumed = true
			return action.action_name
	return ""

## 清空缓冲
func clear_buffer() -> void:
	buffered_actions.clear()

## 清理过期的动作
func _clean_expired_actions() -> void:
	var current_time = Time.get_ticks_msec()
	buffered_actions = buffered_actions.filter(func(action): 
		return (current_time - action.timestamp) < BUFFER_WINDOW_MS
	)

## 获取缓冲大小
func get_buffer_size() -> int:
	return buffered_actions.size()

## 检查缓冲是否为空
func is_buffer_empty() -> bool:
	return buffered_actions.is_empty()

## 获取缓冲动作列表（用于调试）
func get_buffered_actions() -> Array[String]:
	var actions: Array[String] = []
	for action in buffered_actions:
		if action.is_valid():
			actions.append(action.action_name)
	return actions
