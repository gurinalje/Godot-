## 世界状态管理器
## 管理游戏世界的全局状态

class_name WorldStateManager
extends Node

# 世界状态
var world_state: Dictionary = {
	"current_area": "forest",
	"time_of_day": "day",
	"weather": "clear",
	"danger_level": 1,
	"events_completed": [],
	"npcs_met": [],
	"treasures_found": []
}

# 时间系统
var game_time: float = 0.0
var time_speed: float = 1.0

# 信号
signal area_changed(new_area: String)
signal time_changed(new_time: float)
signal weather_changed(new_weather: String)
signal event_completed(event_id: String)

func _ready() -> void:
	initialize()

func initialize() -> void:
	print("[WorldStateManager] Initialized")

## 获取当前区域
func get_current_area() -> String:
	return world_state.get("current_area", "forest")

## 设置当前区域
func set_current_area(area: String) -> void:
	world_state["current_area"] = area
	area_changed.emit(area)
	print("[WorldStateManager] Changed to area: ", area)

## 获取时间段
func get_time_of_day() -> String:
	return world_state.get("time_of_day", "day")

## 设置时间段
func set_time_of_day(time: String) -> void:
	world_state["time_of_day"] = time
	print("[WorldStateManager] Time of day: ", time)

## 获取天气
func get_weather() -> String:
	return world_state.get("weather", "clear")

## 设置天气
func set_weather(weather: String) -> void:
	world_state["weather"] = weather
	weather_changed.emit(weather)
	print("[WorldStateManager] Weather: ", weather)

## 获取危险等级
func get_danger_level() -> int:
	return world_state.get("danger_level", 1)

## 设置危险等级
func set_danger_level(level: int) -> void:
	world_state["danger_level"] = level
	print("[WorldStateManager] Danger level: ", level)

## 完成事件
func complete_event(event_id: String) -> void:
	var events = world_state.get("events_completed", [])
	if not event_id in events:
		events.append(event_id)
		world_state["events_completed"] = events
		event_completed.emit(event_id)
		print("[WorldStateManager] Event completed: ", event_id)

## 检查事件是否完成
func is_event_completed(event_id: String) -> bool:
	var events = world_state.get("events_completed", [])
	return event_id in events

## 记录遇到的NPC
func record_npc_met(npc_id: String) -> void:
	var npcs = world_state.get("npcs_met", [])
	if not npc_id in npcs:
		npcs.append(npc_id)
		world_state["npcs_met"] = npcs
		print("[WorldStateManager] Met NPC: ", npc_id)

## 检查是否遇到过NPC
func has_met_npc(npc_id: String) -> bool:
	var npcs = world_state.get("npcs_met", [])
	return npc_id in npcs

## 记录发现的宝藏
func record_treasure_found(treasure_id: String) -> void:
	var treasures = world_state.get("treasures_found", [])
	if not treasure_id in treasures:
		treasures.append(treasure_id)
		world_state["treasures_found"] = treasures
		print("[WorldStateManager] Found treasure: ", treasure_id)

## 检查是否发现过宝藏
func has_found_treasure(treasure_id: String) -> bool:
	var treasures = world_state.get("treasures_found", [])
	return treasure_id in treasures

## 获取世界状态
func get_world_state() -> Dictionary:
	return world_state.duplicate()

## 设置世界状态
func set_world_state(state: Dictionary) -> void:
	world_state = state

## 更新游戏时间
func update_game_time(delta: float) -> void:
	game_time += delta * time_speed
	time_changed.emit(game_time)
	
	# 根据时间更新时间段
	_update_time_of_day()

## 更新时间段
func _update_time_of_day() -> void:
	var hour = fmod(game_time / 3600.0, 24.0)
	
	if hour >= 6 and hour < 12:
		set_time_of_day("morning")
	elif hour >= 12 and hour < 18:
		set_time_of_day("afternoon")
	elif hour >= 18 and hour < 22:
		set_time_of_day("evening")
	else:
		set_time_of_day("night")

## 重置世界状态
func reset_world_state() -> void:
	world_state = {
		"current_area": "forest",
		"time_of_day": "day",
		"weather": "clear",
		"danger_level": 1,
		"events_completed": [],
		"npcs_met": [],
		"treasures_found": []
	}
	game_time = 0.0
	print("[WorldStateManager] World state reset")
