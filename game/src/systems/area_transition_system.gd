## 区域传送系统
## 处理不同区域之间的切换
class_name AreaTransitionSystem
extends Node

# 信号
signal area_changed(old_area: String, new_area: String)
signal transition_started()
signal transition_completed()
## 请求UI系统播放过渡动画，由UI系统负责实际的动画播放
signal transition_animation_requested(from_area: String, to_area: String)
## 请求UI系统显示通知消息
signal notification_requested(message: String)

# 区域配置数据（从外部Resource文件加载）
var _area_configs: Dictionary = {}

# 区域配置资源路径映射（可在此处扩展新区域）
@export var area_resource_paths: Dictionary = {
	"forest": "res://src/resources/area_configs/forest.tres",
	"castle": "res://src/resources/area_configs/castle.tres",
	"ruins": "res://src/resources/area_configs/ruins.tres",
	"void": "res://src/resources/area_configs/void.tres",
}

# 当前区域
var current_area: String = "forest"
var unlocked_areas: Array[String] = ["forest"]

# 内部信号，用于协调过渡动画的异步等待
signal _transition_animation_finished()

## 初始化：加载所有区域配置资源
func _ready() -> void:
	_load_area_configs()

## 加载所有区域配置
func _load_area_configs() -> void:
	for area_id: String in area_resource_paths:
		var path: String = area_resource_paths[area_id]
		if ResourceLoader.exists(path):
			var config: AreaConfig = load(path) as AreaConfig
			if config:
				_area_configs[area_id] = config
				print("[AreaTransition] Loaded config: ", area_id, " connections=", config.connections, " unlock_level=", config.unlock_level)
			else:
				push_warning("[AreaTransitionSystem] Failed to load AreaConfig: " + path)
		else:
			push_warning("[AreaTransitionSystem] Area config file not found: " + path)
	print("[AreaTransition] Total configs loaded: ", _area_configs.size(), " keys=", _area_configs.keys())

## 检查是否可以传送到目标区域
func can_transition_to(target_area: String) -> Dictionary:
	if not _area_configs.has(target_area):
		return {"allowed": false, "reason": "区域不存在"}
	
	var config: AreaConfig = _area_configs[target_area]
	var player_level: int = _get_player_level()
	
	# 检查等级要求
	if player_level < config.unlock_level:
		return {"allowed": false, "reason": "需要等级 " + str(config.unlock_level)}
	
	# 检查是否已解锁
	if not unlocked_areas.has(target_area):
		return {"allowed": false, "reason": "区域未解锁"}
	
	# 检查连接
	var current_config: AreaConfig = _area_configs[current_area]
	print("[AreaTransition] current_area=", current_area, " connections=", current_config.connections, " target=", target_area)
	if not current_config.connections.has(target_area):
		return {"allowed": false, "reason": "无法从当前区域传送到目标区域"}
	
	return {"allowed": true, "reason": ""}

## 执行区域传送
func transition_to(target_area: String) -> bool:
	var check: Dictionary = can_transition_to(target_area)
	if not check["allowed"]:
		notification_requested.emit(check["reason"])
		return false
	
	var old_area: String = current_area
	current_area = target_area
	
	# 通过信号请求UI系统播放传送动画
	await _request_transition_animation(old_area, target_area)
	
	# 发送信号
	area_changed.emit(old_area, target_area)
	transition_completed.emit()
	
	return true

## 请求过渡动画并等待完成
func _request_transition_animation(from_area: String, to_area: String) -> void:
	transition_started.emit()
	transition_animation_requested.emit(from_area, to_area)
	await _transition_animation_finished

## 由UI系统调用，通知过渡动画已完成
func notify_transition_animation_finished() -> void:
	_transition_animation_finished.emit()

## 解锁新区域
func unlock_area(area: String) -> void:
	if not unlocked_areas.has(area) and _area_configs.has(area):
		var config: AreaConfig = _area_configs[area]
		unlocked_areas.append(area)
		notification_requested.emit("解锁新区域：" + config.display_name)

## 检查并解锁所有符合条件的区域
func check_and_unlock_areas(player_level: int) -> void:
	print("[AreaTransition] check_and_unlock_areas: level=", player_level, " configs=", _area_configs.keys())
	for area_id: String in _area_configs:
		var config: AreaConfig = _area_configs[area_id]
		print("[AreaTransition]   area=", area_id, " unlock_level=", config.unlock_level, " already_unlocked=", unlocked_areas.has(area_id))
		if player_level >= config.unlock_level and not unlocked_areas.has(area_id):
			unlock_area(area_id)

## 获取区域信息
func get_area_info(area: String) -> AreaConfig:
	return _area_configs.get(area, null)

## 获取区域配置字典（兼容旧接口）
func get_area_info_dict(area: String) -> Dictionary:
	var config: AreaConfig = _area_configs.get(area, null)
	if config == null:
		return {}
	return {
		"id": config.area_id,
		"name": config.display_name,
		"description": config.description,
		"background_color": config.background_color,
		"enemies": config.enemies,
		"npcs": config.npcs,
		"connections": config.connections,
		"unlock_level": config.unlock_level,
	}

## 获取可传送区域
func get_available_areas() -> Array[Dictionary]:
	var available: Array[Dictionary] = []
	var current_config: AreaConfig = _area_configs[current_area]
	var player_level: int = _get_player_level()
	
	for connection: String in current_config.connections:
		var config: AreaConfig = _area_configs[connection]
		available.append({
			"id": connection,
			"name": config.display_name,
			"description": config.description,
			"unlock_level": config.unlock_level,
			"unlocked": unlocked_areas.has(connection),
			"can_transition": player_level >= config.unlock_level and unlocked_areas.has(connection)
		})
	
	return available

## 获取玩家等级（通过GameManager依赖注入）
func _get_player_level() -> int:
	var game_manager: Node = get_tree().root.get_node_or_null("GameManager")
	if game_manager:
		# 优先检查 player_data.level（实际存储位置）
		var player_data = game_manager.get("player_data")
		if player_data and player_data.get("level") != null:
			return player_data.level as int
		# 回退到直接属性
		if game_manager.get("player_level") != null:
			return game_manager.get("player_level") as int
	push_warning("[AreaTransitionSystem] GameManager not found, returning default level 1")
	return 1

## 显示通知（已重构为信号发射，此方法保留兼容性）
func _show_notification(message: String) -> void:
	notification_requested.emit(message)
