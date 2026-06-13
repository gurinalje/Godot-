## 任务系统
## 处理任务的接受、进度更新和完成
class_name QuestSystem
extends Node

# 信号
signal quest_accepted(quest_id: String)
signal quest_progress_updated(quest_id: String, current: int, required: int)
signal quest_completed(quest_id: String)
signal quest_failed(quest_id: String)
signal reward_granted(reward_type: String, amount: int)

# 任务状态枚举
enum QuestStatus {
	AVAILABLE,
	ACTIVE,
	COMPLETED,
	FAILED
}

# 任务数据结构
var quests: Dictionary = {}  # quest_id -> quest_data
var active_quests: Array[String] = []
var completed_quests: Array[String] = []

# 任务定义
var quest_definitions: Dictionary = {
	"forest_boss_quest": {
		"name": "森林巨魔的威胁",
		"description": "幽暗森林深处出现了一只狂暴的森林巨魔，击败它以保卫村庄！",
		"giver": "quest_giver_forest",
		"objectives": [
			{"type": "kill", "target": "森林巨魔", "required": 1, "current": 0}
		],
		"rewards": {
			"gold": 300,
			"experience": 400,
			"card": "holy_blessing"
		},
		"prerequisites": [],
		"level_required": 1
	},
	"wolf_hunt": {
		"name": "猎狼任务",
		"description": "森林中的野狼威胁着商队的安全，消灭5只野狼。",
		"giver": "quest_giver",
		"objectives": [
			{"type": "kill", "target": "野狼", "required": 5, "current": 0}
		],
		"rewards": {
			"gold": 100,
			"experience": 50,
			"card": "summon_skeleton"
		},
		"prerequisites": [],
		"level_required": 1
	},
	"goblin_clear": {
		"name": "清理哥布林",
		"description": "哥布林在森林边缘建立了营地，清理它们！",
		"giver": "quest_giver",
		"objectives": [
			{"type": "kill", "target": "哥布林", "required": 3, "current": 0}
		],
		"rewards": {
			"gold": 150,
			"experience": 75,
			"card": "lightning"
		},
		"prerequisites": ["wolf_hunt"],
		"level_required": 3
	},
	"skeleton_king": {
		"name": "骷髅王之怒",
		"description": "城堡深处的骷髅王复活了，击败它！",
		"giver": "quest_giver",
		"objectives": [
			{"type": "kill", "target": "骷髅王", "required": 1, "current": 0}
		],
		"rewards": {
			"gold": 500,
			"experience": 200,
			"card": "earthquake"
		},
		"prerequisites": ["goblin_clear"],
		"level_required": 8
	},
	"collect_herbs": {
		"name": "采集草药",
		"description": "采集10份草药来制作药水。",
		"giver": "merchant",
		"objectives": [
			{"type": "collect", "target": "草药", "required": 10, "current": 0}
		],
		"rewards": {
			"gold": 80,
			"experience": 30,
			"item": "生命药水"
		},
		"prerequisites": [],
		"level_required": 1
	},
	"escort_merchant": {
		"name": "护送商队",
		"description": "保护商队安全通过危险区域。",
		"giver": "merchant",
		"objectives": [
			{"type": "escort", "target": "商队", "required": 1, "current": 0}
		],
		"rewards": {
			"gold": 200,
			"experience": 100,
			"card": "holy_blessing"
		},
		"prerequisites": ["collect_herbs"],
		"level_required": 5
	}
}

## 初始化
func _ready() -> void:
	# 初始化所有任务
	for quest_id in quest_definitions:
		quests[quest_id] = quest_definitions[quest_id].duplicate()
		quests[quest_id]["status"] = QuestStatus.AVAILABLE

## 获取可用任务
func get_available_quests(npc_id: String) -> Array[Dictionary]:
	var available: Array[Dictionary] = []
	var player_level = _get_player_level()
	
	for quest_id in quests:
		var quest = quests[quest_id]
		
		# 检查任务状态
		if quest["status"] != QuestStatus.AVAILABLE:
			continue
		
		# 检查NPC
		if quest["giver"] != npc_id:
			continue
		
		# 检查等级要求
		if player_level < quest["level_required"]:
			continue
		
		# 检查前置任务
		var prerequisites_met = true
		for prereq in quest["prerequisites"]:
			if not completed_quests.has(prereq):
				prerequisites_met = false
				break
		
		if prerequisites_met:
			available.append({
				"id": quest_id,
				"name": quest["name"],
				"description": quest["description"]
			})
	
	return available

## 接受任务
func accept_quest(quest_id: String) -> bool:
	if not quests.has(quest_id):
		return false
	
	var quest = quests[quest_id]
	
	# 检查是否可以接受
	if quest["status"] != QuestStatus.AVAILABLE:
		return false
	
	# 检查等级
	if _get_player_level() < quest["level_required"]:
		_show_notification("等级不足，需要等级 " + str(quest["level_required"]))
		return false
	
	# 检查前置任务
	for prereq in quest["prerequisites"]:
		if not completed_quests.has(prereq):
			_show_notification("需要先完成前置任务")
			return false
	
	# 接受任务
	quest["status"] = QuestStatus.ACTIVE
	active_quests.append(quest_id)
	
	# 重置进度
	for objective in quest["objectives"]:
		objective["current"] = 0
	
	quest_accepted.emit(quest_id)
	_show_notification("接受任务：" + quest["name"])
	
	return true

## 更新任务进度
func update_quest_progress(quest_id: String, objective_index: int, amount: int = 1) -> void:
	if not quests.has(quest_id):
		return
	
	var quest = quests[quest_id]
	
	# 检查任务状态
	if quest["status"] != QuestStatus.ACTIVE:
		return
	
	# 更新进度
	if objective_index < quest["objectives"].size():
		var objective = quest["objectives"][objective_index]
		objective["current"] = min(objective["current"] + amount, objective["required"])
		
		quest_progress_updated.emit(quest_id, objective["current"], objective["required"])
		
		# 检查是否完成
		_check_quest_completion(quest_id)

## 检查任务完成
func _check_quest_completion(quest_id: String) -> void:
	var quest = quests[quest_id]
	var all_completed = true
	
	for objective in quest["objectives"]:
		if objective["current"] < objective["required"]:
			all_completed = false
			break
	
	if all_completed:
		_complete_quest(quest_id)

## 完成任务
func _complete_quest(quest_id: String) -> void:
	var quest = quests[quest_id]
	
	quest["status"] = QuestStatus.COMPLETED
	active_quests.erase(quest_id)
	completed_quests.append(quest_id)
	
	# 发放奖励
	_grant_rewards(quest["rewards"])
	
	quest_completed.emit(quest_id)
	_show_notification("完成任务：" + quest["name"])

## 发放奖励
func _grant_rewards(rewards: Dictionary) -> void:
	# 金币奖励
	if rewards.has("gold"):
		var gold = rewards["gold"]
		_add_player_gold(gold)
		reward_granted.emit("gold", gold)
	
	# 经验奖励
	if rewards.has("experience"):
		var exp = rewards["experience"]
		_add_player_experience(exp)
		reward_granted.emit("experience", exp)
	
	# 卡牌奖励
	if rewards.has("card"):
		var card_id = rewards["card"]
		_add_card_to_collection(card_id)
		reward_granted.emit("card", 1)
	
	# 物品奖励
	if rewards.has("item"):
		var item_name = rewards["item"]
		_add_item_to_inventory(item_name)
		reward_granted.emit("item", 1)

## 失败任务
func fail_quest(quest_id: String) -> void:
	if not quests.has(quest_id):
		return
	
	var quest = quests[quest_id]
	
	if quest["status"] == QuestStatus.ACTIVE:
		quest["status"] = QuestStatus.FAILED
		active_quests.erase(quest_id)
		
		quest_failed.emit(quest_id)
		_show_notification("任务失败：" + quest["name"])

## 获取任务信息
func get_quest_info(quest_id: String) -> Dictionary:
	return quests.get(quest_id, {})

## 获取活跃任务
func get_active_quests() -> Array[Dictionary]:
	var active: Array[Dictionary] = []
	
	for quest_id in active_quests:
		var quest = quests[quest_id]
		active.append({
			"id": quest_id,
			"name": quest["name"],
			"description": quest["description"],
			"objectives": quest["objectives"]
		})
	
	return active

## 获取已完成任务
func get_completed_quests() -> Array[String]:
	return completed_quests.duplicate()

## 检查任务是否完成
func is_quest_completed(quest_id: String) -> bool:
	return completed_quests.has(quest_id)

## 检查任务是否激活
func is_quest_active(quest_id: String) -> bool:
	return active_quests.has(quest_id)

## 处理敌人击杀
func on_enemy_killed(enemy_name: String) -> void:
	for quest_id in active_quests:
		var quest = quests[quest_id]
		
		for i in range(quest["objectives"].size()):
			var objective = quest["objectives"][i]
			
			if objective["type"] == "kill" and objective["target"] == enemy_name:
				update_quest_progress(quest_id, i)

## 处理物品收集
func on_item_collected(item_name: String) -> void:
	for quest_id in active_quests:
		var quest = quests[quest_id]
		
		for i in range(quest["objectives"].size()):
			var objective = quest["objectives"][i]
			
			if objective["type"] == "collect" and objective["target"] == item_name:
				update_quest_progress(quest_id, i)

## 获取玩家等级
func _get_player_level() -> int:
	# 尝试从父节点获取
	var parent = get_parent()
	if parent and parent.get("player_level") != null:
		return parent.get("player_level")
	# 回退：尝试从GameManager获取
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		var world = game_manager.get_node_or_null("WorldExploration")
		if world and world.get("player_level") != null:
			return world.get("player_level")
	return 1

## 添加玩家金币
func _add_player_gold(amount: int) -> void:
	var parent = get_parent()
	if parent and parent.get("player_gold") != null:
		parent.set("player_gold", parent.get("player_gold") + amount)

## 添加玩家经验
func _add_player_experience(amount: int) -> void:
	var parent = get_parent()
	if parent and parent.get("player_experience") != null:
		parent.set("player_experience", parent.get("player_experience") + amount)
		# 检查升级（通过方法调用而非直接访问）
		if parent.has_method("_check_level_up"):
			parent._check_level_up()

## 添加卡牌到收集
func _add_card_to_collection(card_id: String) -> void:
	print("[QuestSystem] 添加卡牌到收集：", card_id)
	
	# 获取卡牌数据库
	var card_database = get_node_or_null("/root/CardDatabase")
	if not card_database:
		push_warning("[QuestSystem] CardDatabase not found")
		_show_notification("卡牌奖励添加失败")
		return
	
	# 获取卡牌数据
	var card_data = card_database.get_card(card_id)
	if not card_data:
		push_warning("[QuestSystem] Card not found: " + card_id)
		return
	
	# 尝试添加到DeckBuildingManager
	var deck_manager = get_node_or_null("/root/DeckBuildingManager")
	if deck_manager and deck_manager.has_method("add_card_to_collection"):
		deck_manager.add_card_to_collection(card_data)
		_show_notification("任务奖励：获得卡牌 " + card_data.name)
	else:
		# 回退：直接通知玩家
		_show_notification("任务奖励：获得卡牌 " + card_data.name)
	
	# 发送奖励信号
	reward_granted.emit("card", 1)

## 添加物品到背包
func _add_item_to_inventory(item_name: String) -> void:
	print("[QuestSystem] 添加物品到背包：", item_name)
	
	# 根据物品类型应用效果
	match item_name:
		"生命药水":
			# 恢复生命值
			var parent = get_parent()
			if parent and parent.has_method("get"):
				var current_health = parent.get("player_health")
				var max_health = parent.get("player_max_health")
				if current_health != null and max_health != null:
					parent.set("player_health", min(current_health + 50, max_health))
					_show_notification("任务奖励：使用生命药水，恢复50点生命值")
				else:
					_show_notification("任务奖励：获得生命药水")
			else:
				_show_notification("任务奖励：获得生命药水")
		"魔法药水":
			# 恢复能量（在战斗中有用）
			_show_notification("任务奖励：获得魔法药水")
		"护甲碎片":
			# 增加防御
			var parent = get_parent()
			if parent and parent.has_method("get"):
				var current_defense = parent.get("player_defense") if parent.get("player_defense") != null else 0
				parent.set("player_defense", current_defense + 2)
				_show_notification("任务奖励：护甲碎片，防御+2")
			else:
				_show_notification("任务奖励：获得护甲碎片")
		_:
			_show_notification("任务奖励：获得 " + item_name)
	
	# 发送奖励信号
	reward_granted.emit("item", 1)

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
