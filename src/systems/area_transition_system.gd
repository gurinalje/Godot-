## 区域传送系统
## 处理不同区域之间的切换
class_name AreaTransitionSystem
extends Node

# 信号
signal area_changed(old_area: String, new_area: String)
signal transition_started()
signal transition_completed()

# 区域配置
var area_config: Dictionary = {
	"forest": {
		"name": "幽暗森林",
		"description": "浓密的森林，隐藏着各种危险...",
		"background_color": Color(0.2, 0.4, 0.2),
		"enemies": ["野狼", "哥布林", "毒蜘蛛"],
		"npcs": ["merchant", "quest_giver"],
		"connections": ["castle"],
		"unlock_level": 1
	},
	"castle": {
		"name": "废弃城堡",
		"description": "曾经辉煌的城堡，如今只剩下残垣断壁...",
		"background_color": Color(0.4, 0.4, 0.5),
		"enemies": ["骷髅士兵", "暗影骑士", "死灵法师"],
		"npcs": ["blacksmith"],
		"connections": ["forest", "ruins"],
		"unlock_level": 5
	},
	"ruins": {
		"name": "远古遗迹",
		"description": "神秘的遗迹，蕴含着强大的力量...",
		"background_color": Color(0.5, 0.4, 0.3),
		"enemies": ["石像鬼", "元素精灵", "远古守卫"],
		"npcs": ["merchant"],
		"connections": ["castle", "void"],
		"unlock_level": 10
	},
	"void": {
		"name": "虚空领域",
		"description": "扭曲的空间，充满了混沌能量...",
		"background_color": Color(0.3, 0.2, 0.4),
		"enemies": ["虚空行者", "混沌使者", "末日守卫"],
		"npcs": [],
		"connections": ["ruins"],
		"unlock_level": 15
	}
}

# 当前区域
var current_area: String = "forest"
var unlocked_areas: Array[String] = ["forest"]

## 检查是否可以传送到目标区域
func can_transition_to(target_area: String) -> Dictionary:
	if not area_config.has(target_area):
		return {"allowed": false, "reason": "区域不存在"}
	
	var config = area_config[target_area]
	var player_level = _get_player_level()
	
	# 检查等级要求
	if player_level < config["unlock_level"]:
		return {"allowed": false, "reason": "需要等级 " + str(config["unlock_level"])}
	
	# 检查是否已解锁
	if not unlocked_areas.has(target_area):
		return {"allowed": false, "reason": "区域未解锁"}
	
	# 检查连接
	var current_config = area_config[current_area]
	if not current_config["connections"].has(target_area):
		return {"allowed": false, "reason": "无法从当前区域传送到目标区域"}
	
	return {"allowed": true, "reason": ""}

## 执行区域传送
func transition_to(target_area: String) -> bool:
	var check = can_transition_to(target_area)
	if not check["allowed"]:
		_show_notification(check["reason"])
		return false
	
	var old_area = current_area
	current_area = target_area
	
	# 播放传送动画
	await _play_transition_animation()
	
	# 发送信号
	area_changed.emit(old_area, target_area)
	transition_completed.emit()
	
	return true

## 解锁新区域
func unlock_area(area: String) -> void:
	if not unlocked_areas.has(area):
		unlocked_areas.append(area)
		_show_notification("解锁新区域：" + area_config[area]["name"])

## 检查并解锁所有符合条件的区域
func check_and_unlock_areas(player_level: int) -> void:
	for area_id in area_config:
		var config = area_config[area_id]
		if player_level >= config["unlock_level"] and not unlocked_areas.has(area_id):
			unlock_area(area_id)

## 获取区域信息
func get_area_info(area: String) -> Dictionary:
	return area_config.get(area, {})

## 获取可传送区域
func get_available_areas() -> Array[Dictionary]:
	var available: Array[Dictionary] = []
	var current_config = area_config[current_area]
	
	for connection in current_config["connections"]:
		var config = area_config[connection]
		var player_level = _get_player_level()
		
		available.append({
			"id": connection,
			"name": config["name"],
			"description": config["description"],
			"unlock_level": config["unlock_level"],
			"unlocked": unlocked_areas.has(connection),
			"can_transition": player_level >= config["unlock_level"] and unlocked_areas.has(connection)
		})
	
	return available

## 播放传送动画
func _play_transition_animation() -> void:
	transition_started.emit()
	
	# 创建黑屏过渡
	var fade = ColorRect.new()
	fade.color = Color.BLACK
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.modulate.a = 0.0
	
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 20
	canvas_layer.add_child(fade)
	get_tree().root.add_child(canvas_layer)
	
	# 淡入
	var tween = create_tween()
	tween.tween_property(fade, "modulate:a", 1.0, 0.5)
	await tween.finished
	
	# 等待一小段时间
	await get_tree().create_timer(0.3).timeout
	
	# 淡出
	tween = create_tween()
	tween.tween_property(fade, "modulate:a", 0.0, 0.5)
	await tween.finished
	
	# 清理
	canvas_layer.queue_free()

## 获取玩家等级
func _get_player_level() -> int:
	# 尝试从父节点获取（area_transition_system是WorldExploration的子节点）
	var parent = get_parent()
	if parent and parent.has_method("get") and parent.get("player_level") != null:
		return parent.get("player_level")
	# 回退：尝试从GameManager获取
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		var world = game_manager.get_node_or_null("WorldExploration")
		if world and world.get("player_level") != null:
			return world.get("player_level")
	return 1

## 显示通知
func _show_notification(message: String) -> void:
	var notification = Label.new()
	notification.text = message
	notification.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notification.set_anchors_preset(Control.PRESET_CENTER)
	
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 15
	canvas_layer.add_child(notification)
	get_tree().root.add_child(canvas_layer)
	
	# 2秒后消失
	await get_tree().create_timer(2.0).timeout
	notification.queue_free()
	canvas_layer.queue_free()
