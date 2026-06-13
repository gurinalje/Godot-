## 世界探索器
## 管理玩家在游戏世界中的探索、移动和发现
## 是RPG探索系统的核心
class_name WorldExplorer
extends Node

## 探索信号
signal area_entered(area_id: String)
signal area_exited(area_id: String)
signal location_discovered(location_id: String)
signal exploration_progress_updated(progress: float)

## 区域数据结构
class AreaData extends RefCounted:
	var id: String = ""
	var name: String = ""
	var description: String = ""
	var connections: Array[String] = []
	var locations: Array[String] = []
	var is_discovered: bool = false
	var exploration_progress: float = 0.0
	var encounter_rate: float = 0.1
	var treasure_locations: Array[Vector2] = []

## 当前区域
var current_area: String = ""

## 已探索的区域
var discovered_areas: Array[String] = []

## 区域探索进度
var area_progress: Dictionary = {}

## 已发现的地点
var discovered_locations: Array[String] = []

## 探索历史
var exploration_history: Array[Dictionary] = []

## 区域数据库
var area_database: Dictionary = {}

## 初始化世界探索器
func _ready() -> void:
	# 初始化区域数据
	_initialize_area_data()

## 初始化区域数据
func _initialize_area_data() -> void:
	# 创建示例区域
	_add_area("starting_village", "起始村庄", "你的冒险开始的地方", [], ["village_square", "blacksmith", "shop"])
	_add_area("dark_forest", "黑暗森林", "充满危险的森林", ["starting_village"], ["forest_entrance", "deep_forest", "ancient_tree"])
	_add_area("crystal_cave", "水晶洞穴", "闪烁着水晶光芒的洞穴", ["dark_forest"], ["cave_entrance", "crystal_chamber", "underground_lake"])
	_add_area("ancient_ruins", "古老遗迹", "远古文明的遗迹", ["crystal_cave"], ["ruins_entrance", "temple", "treasure_room"])
	_add_area("void_realm", "虚空领域", "充满神秘力量的领域", ["ancient_ruins"], ["void_gate", "void_center", "void_core"])

## 添加区域
func _add_area(id: String, name: String, description: String, connections: Array[String], locations: Array[String]) -> void:
	var area = AreaData.new()
	area.id = id
	area.name = name
	area.description = description
	area.connections = connections
	area.locations = locations
	area_database[id] = area

## 进入区域
func enter_area(area_id: String) -> bool:
	# 检查区域是否存在
	if area_id not in area_database:
		push_warning("Area not found: %s" % area_id)
		return false
	
	# 检查区域是否已解锁
	var world_state_manager = GameManager.get_system("WorldStateManager")
	if world_state_manager and not world_state_manager.is_area_unlocked(area_id):
		push_warning("Area not unlocked: %s" % area_id)
		return false
	
	# 离开当前区域
	if current_area != "":
		exit_area()
	
	# 进入新区域
	current_area = area_id
	
	# 标记为已发现
	if area_id not in discovered_areas:
		discovered_areas.append(area_id)
		area_database[area_id].is_discovered = true
	
	# 初始化探索进度
	if area_id not in area_progress:
		area_progress[area_id] = 0.0
	
	# 发射信号
	area_entered.emit(area_id)
	
	# 记录历史
	_record_exploration("enter", area_id)
	
	return true

## 离开区域
func exit_area() -> void:
	if current_area != "":
		var old_area = current_area
		current_area = ""
		area_exited.emit(old_area)
		_record_exploration("exit", old_area)

## 探索当前位置
func explore_current_location() -> Dictionary:
	if current_area == "":
		return {"success": false, "message": "不在任何区域中"}
	
	var area = area_database[current_area]
	var exploration_result = {
		"success": true,
		"area": current_area,
		"discoveries": [],
		"encounters": [],
		"treasures": []
	}
	
	# 更新探索进度
	area_progress[current_area] = minf(area_progress[current_area] + 0.1, 1.0)
	exploration_progress_updated.emit(area_progress[current_area])
	
	# 随机发现地点
	if randf() < 0.3:  # 30%概率发现新地点
		var undiscovered_locations = _get_undiscovered_locations(current_area)
		if undiscovered_locations.size() > 0:
			var new_location = undiscovered_locations[randi() % undiscovered_locations.size()]
			discover_location(new_location)
			exploration_result.discoveries.append(new_location)
	
	# 随机遭遇
	if randf() < area.encounter_rate:
		var encounter = _generate_encounter()
		exploration_result.encounters.append(encounter)
	
	# 随机发现宝藏
	if randf() < 0.1:  # 10%概率发现宝藏
		var treasure = _generate_treasure()
		exploration_result.treasures.append(treasure)
	
	return exploration_result

## 发现地点
func discover_location(location_id: String) -> void:
	if location_id not in discovered_locations:
		discovered_locations.append(location_id)
		location_discovered.emit(location_id)
		_record_exploration("discover", location_id)

## 获取未发现的地点
func _get_undiscovered_locations(area_id: String) -> Array[String]:
	var area = area_database[area_id]
	var undiscovered: Array[String] = []
	for location in area.locations:
		if location not in discovered_locations:
			undiscovered.append(location)
	return undiscovered

## 生成遭遇
func _generate_encounter() -> Dictionary:
	# 简单的遭遇生成
	var encounter_types = ["enemy", "npc", "event"]
	var type = encounter_types[randi() % encounter_types.size()]
	
	return {
		"type": type,
		"id": "encounter_%d" % randi(),
		"difficulty": randf_range(0.5, 1.5)
	}

## 生成宝藏
func _generate_treasure() -> Dictionary:
	# 简单的宝藏生成
	var treasure_types = ["gold", "item", "card"]
	var type = treasure_types[randi() % treasure_types.size()]
	
	return {
		"type": type,
		"value": randi_range(10, 100)
	}

## 获取可前往的区域
func get_accessible_areas() -> Array[String]:
	if current_area == "":
		return []
	
	var area = area_database[current_area]
	var accessible: Array[String] = []
	
	# 添加当前区域的连接区域
	for connection in area.connections:
		var world_state_manager = GameManager.get_system("WorldStateManager")
		if world_state_manager and world_state_manager.is_area_unlocked(connection):
			accessible.append(connection)
	
	return accessible

## 获取当前区域信息
func get_current_area_info() -> Dictionary:
	if current_area == "":
		return {}
	
	var area = area_database[current_area]
	return {
		"id": area.id,
		"name": area.name,
		"description": area.description,
		"exploration_progress": area_progress.get(current_area, 0.0),
		"discovered_locations": _get_discovered_locations_in_area(current_area),
		"accessible_areas": get_accessible_areas()
	}
## 获取区域中已发现的地点
func _get_discovered_locations_in_area(area_id: String) -> Array[String]:
	var area = area_database[area_id]
	var discovered: Array[String] = []
	for location in area.locations:
		if location in discovered_locations:
			discovered.append(location)
	return discovered

## 记录探索历史
func _record_exploration(action: String, target: String) -> void:
	var record = {
		"action": action,
		"target": target,
		"timestamp": Time.get_unix_time_from_system()
	}
	exploration_history.append(record)

## 获取探索历史
func get_exploration_history() -> Array[Dictionary]:
	return exploration_history.duplicate()

## 获取探索统计
func get_exploration_stats() -> Dictionary:
	return {
		"discovered_areas": discovered_areas.size(),
		"total_areas": area_database.size(),
		"discovered_locations": discovered_locations.size(),
		"exploration_completion": _calculate_exploration_completion()
	}

## 计算探索完成度
func _calculate_exploration_completion() -> float:
	if area_database.is_empty():
		return 0.0
	
	var total_progress = 0.0
	for area_id in area_database:
		total_progress += area_progress.get(area_id, 0.0)
	
	return total_progress / area_database.size() * 100.0

## 保存探索数据
func save_data() -> Dictionary:
	return {
		"current_area": current_area,
		"discovered_areas": discovered_areas,
		"area_progress": area_progress,
		"discovered_locations": discovered_locations,
		"exploration_history": exploration_history
	}

## 加载探索数据
func load_data(data: Dictionary) -> void:
	current_area = data.get("current_area", "")
	discovered_areas = data.get("discovered_areas", [])
	area_progress = data.get("area_progress", {})
	discovered_locations = data.get("discovered_locations", [])
	exploration_history = data.get("exploration_history", [])

## 重置探索系统
func reset() -> void:
	current_area = ""
	discovered_areas.clear()
	area_progress.clear()
	discovered_locations.clear()
	exploration_history.clear()
	_initialize_area_data()
