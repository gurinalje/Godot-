## 世界状态数据
## 存储游戏世界的各种状态信息
## 包括解锁区域、完成任务、触发事件等
class_name WorldState
extends Resource

## 区域解锁状态
@export var unlocked_areas: Array[String] = []

## 完成的任务
@export var completed_quests: Array[String] = []

## 触发的事件
@export var triggered_events: Array[String] = []

## 世界变量（键值对存储）
@export var world_variables: Dictionary = {}

## NPC状态
@export var npc_states: Dictionary = {}

## 天气状态
@export var weather_state: String = "clear"

## 时间状态
@export var time_state: String = "day"

## 获取变量值
func get_variable(key: String, default_value = null) -> Variant:
	return world_variables.get(key, default_value)

## 设置变量值
func set_variable(key: String, value: Variant) -> void:
	world_variables[key] = value

## 检查区域是否解锁
func is_area_unlocked(area_id: String) -> bool:
	return area_id in unlocked_areas

## 解锁区域
func unlock_area(area_id: String) -> void:
	if area_id not in unlocked_areas:
		unlocked_areas.append(area_id)

## 检查任务是否完成
func is_quest_completed(quest_id: String) -> bool:
	return quest_id in completed_quests

## 完成任务
func complete_quest(quest_id: String) -> void:
	if quest_id not in completed_quests:
		completed_quests.append(quest_id)

## 检查事件是否触发
func is_event_triggered(event_id: String) -> bool:
	return event_id in triggered_events

## 触发事件
func trigger_event(event_id: String) -> void:
	if event_id not in triggered_events:
		triggered_events.append(event_id)

## 获取NPC状态
func get_npc_state(npc_id: String) -> Dictionary:
	return npc_states.get(npc_id, {})

## 设置NPC状态
func set_npc_state(npc_id: String, state: Dictionary) -> void:
	npc_states[npc_id] = state

## 克隆世界状态
func clone() -> WorldState:
	var clone_state = WorldState.new()
	clone_state.unlocked_areas = unlocked_areas.duplicate()
	clone_state.completed_quests = completed_quests.duplicate()
	clone_state.triggered_events = triggered_events.duplicate()
	clone_state.world_variables = world_variables.duplicate(true)
	clone_state.npc_states = npc_states.duplicate(true)
	clone_state.weather_state = weather_state
	clone_state.time_state = time_state
	return clone_state
