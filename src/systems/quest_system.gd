## 任务系统
## 处理任务的接受、进度更新和完成
class_name QuestSystem
extends Node

# 信号
## 任务被接受时发出
signal quest_accepted(quest_id: String)
## 任务进度更新时发出
signal quest_progress_updated(quest_id: String, current: int, required: int)
## 任务完成时发出
signal quest_completed(quest_id: String)
## 任务失败时发出
signal quest_failed(quest_id: String)
## 奖励发放时发出
signal reward_granted(reward_type: String, amount: int)
## 请求显示通知（由UI系统处理）
signal notification_requested(message: String)

# 任务状态枚举
enum QuestStatus {
	AVAILABLE,
	ACTIVE,
	COMPLETED,
	FAILED
}

# 任务数据结构
## 所有任务运行时数据（quest_id -> quest运行时数据）
var quests: Dictionary = {}
## 当前活跃任务ID列表
var active_quests: Array[String] = []
## 已完成任务ID列表
var completed_quests: Array[String] = []

## 任务数据库引用（通过GameManager获取）
var _quest_database: QuestDatabase = null

## 初始化
func _ready() -> void:
	# 通过GameManager获取系统引用
	_quest_database = _get_quest_database()
	if _quest_database == null:
		push_warning("[QuestSystem] QuestDatabase not found, creating local instance")
		_quest_database = QuestDatabase.new()
		_quest_database._ready()

	# 初始化所有任务
	_initialize_quests()

## 初始化任务数据
func _initialize_quests() -> void:
	var definitions: Dictionary = _quest_database.get_all_definitions()
	for quest_id: String in definitions:
		var quest_def: QuestData = definitions[quest_id]
		var quest_data: Dictionary = quest_def.to_dict()
		quest_data["status"] = QuestStatus.AVAILABLE
		# 初始化目标进度
		for objective: Dictionary in quest_data["objectives"]:
			objective["current"] = 0
		quests[quest_id] = quest_data

## 获取可用任务
func get_available_quests(npc_id: String) -> Array[Dictionary]:
	var available: Array[Dictionary] = []
	var player_level: int = _get_player_level()

	for quest_id: String in quests:
		var quest: Dictionary = quests[quest_id]

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
		var prerequisites_met: bool = true
		for prereq: String in quest["prerequisites"]:
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

	var quest: Dictionary = quests[quest_id]

	# 检查是否可以接受
	if quest["status"] != QuestStatus.AVAILABLE:
		return false

	# 检查等级
	if _get_player_level() < quest["level_required"]:
		notification_requested.emit("等级不足，需要等级 " + str(quest["level_required"]))
		return false

	# 检查前置任务
	for prereq: String in quest["prerequisites"]:
		if not completed_quests.has(prereq):
			notification_requested.emit("需要先完成前置任务")
			return false

	# 接受任务
	quest["status"] = QuestStatus.ACTIVE
	active_quests.append(quest_id)

	# 重置进度
	for objective: Dictionary in quest["objectives"]:
		objective["current"] = 0

	quest_accepted.emit(quest_id)
	notification_requested.emit("接受任务：" + quest["name"])

	return true

## 更新任务进度
func update_quest_progress(quest_id: String, objective_index: int, amount: int = 1) -> void:
	if not quests.has(quest_id):
		return

	var quest: Dictionary = quests[quest_id]

	# 检查任务状态
	if quest["status"] != QuestStatus.ACTIVE:
		return

	# 更新进度
	if objective_index < quest["objectives"].size():
		var objective: Dictionary = quest["objectives"][objective_index]
		objective["current"] = mini(objective["current"] + amount, objective["required"])

		quest_progress_updated.emit(quest_id, objective["current"], objective["required"])

		# 检查是否完成
		_check_quest_completion(quest_id)

## 检查任务完成
func _check_quest_completion(quest_id: String) -> void:
	var quest: Dictionary = quests[quest_id]
	var all_completed: bool = true

	for objective: Dictionary in quest["objectives"]:
		if objective["current"] < objective["required"]:
			all_completed = false
			break

	if all_completed:
		_complete_quest(quest_id)

## 完成任务
func _complete_quest(quest_id: String) -> void:
	var quest: Dictionary = quests[quest_id]

	quest["status"] = QuestStatus.COMPLETED
	active_quests.erase(quest_id)
	completed_quests.append(quest_id)

	# 发放奖励
	_grant_rewards(quest["rewards"])

	quest_completed.emit(quest_id)
	notification_requested.emit("完成任务：" + quest["name"])

## 发放奖励
func _grant_rewards(rewards: Dictionary) -> void:
	# 金币奖励
	if rewards.has("gold"):
		var gold: int = rewards["gold"]
		_add_player_gold(gold)
		reward_granted.emit("gold", gold)

	# 经验奖励
	if rewards.has("experience"):
		var exp: int = rewards["experience"]
		_add_player_experience(exp)
		reward_granted.emit("experience", exp)

	# 卡牌奖励
	if rewards.has("card"):
		var card_id: String = rewards["card"]
		_add_card_to_collection(card_id)
		reward_granted.emit("card", 1)

	# 物品奖励
	if rewards.has("item"):
		var item_name: String = rewards["item"]
		_add_item_to_inventory(item_name)
		reward_granted.emit("item", 1)

## 失败任务
func fail_quest(quest_id: String) -> void:
	if not quests.has(quest_id):
		return

	var quest: Dictionary = quests[quest_id]

	if quest["status"] == QuestStatus.ACTIVE:
		quest["status"] = QuestStatus.FAILED
		active_quests.erase(quest_id)

		quest_failed.emit(quest_id)
		notification_requested.emit("任务失败：" + quest["name"])

## 获取任务信息
func get_quest_info(quest_id: String) -> Dictionary:
	return quests.get(quest_id, {})

## 获取活跃任务
func get_active_quests() -> Array[Dictionary]:
	var active: Array[Dictionary] = []

	for quest_id: String in active_quests:
		var quest: Dictionary = quests[quest_id]
		active.append({
			"id": quest_id,
			"name": quest["name"],
			"description": quest["description"],
			"objectives": quest["objectives"]
		})

	return active

## 获取已完成任务ID列表
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
	for quest_id: String in active_quests:
		var quest: Dictionary = quests[quest_id]

		for i: int in range(quest["objectives"].size()):
			var objective: Dictionary = quest["objectives"][i]

			if objective["type"] == "kill" and objective["target"] == enemy_name:
				update_quest_progress(quest_id, i)

## 处理物品收集
func on_item_collected(item_name: String) -> void:
	for quest_id: String in active_quests:
		var quest: Dictionary = quests[quest_id]

		for i: int in range(quest["objectives"].size()):
			var objective: Dictionary = quest["objectives"][i]

			if objective["type"] == "collect" and objective["target"] == item_name:
				update_quest_progress(quest_id, i)

#region 系统引用获取（通过GameManager依赖注入）

## 获取玩家等级
func _get_player_level() -> int:
	var game_manager: Node = _get_game_manager()
	if game_manager == null:
		return 1

	# 尝试从PlayerSystem获取
	var player_system: Node = game_manager.get_node_or_null("PlayerSystem")
	if player_system and player_system.get("player_level") != null:
		return player_system.get("player_level")

	# 尝试从WorldExploration获取
	var world: Node = game_manager.get_node_or_null("WorldExploration")
	if world and world.get("player_level") != null:
		return world.get("player_level")

	return 1

## 获取GameManager引用
func _get_game_manager() -> Node:
	return get_node_or_null("/root/GameManager")

## 获取QuestDatabase引用
func _get_quest_database() -> QuestDatabase:
	var game_manager: Node = _get_game_manager()
	if game_manager:
		var db: Node = game_manager.get_node_or_null("QuestDatabase")
		if db is QuestDatabase:
			return db as QuestDatabase
	# 回退：检查自动加载
	return get_node_or_null("/root/QuestDatabase") as QuestDatabase

## 获取PlayerSystem引用
func _get_player_system() -> Node:
	var game_manager: Node = _get_game_manager()
	if game_manager:
		return game_manager.get_node_or_null("PlayerSystem")
	return null

#endregion

#region 奖励发放（通过GameManager访问其他系统）

## 添加玩家金币
func _add_player_gold(amount: int) -> void:
	var player_system: Node = _get_player_system()
	if player_system and player_system.get("player_gold") != null:
		player_system.set("player_gold", player_system.get("player_gold") + amount)
		return

	# 回退：尝试直接通过GameManager
	var game_manager: Node = _get_game_manager()
	if game_manager and game_manager.has_method("add_player_gold"):
		game_manager.add_player_gold(amount)

## 添加玩家经验
func _add_player_experience(amount: int) -> void:
	var player_system: Node = _get_player_system()
	if player_system and player_system.get("player_experience") != null:
		player_system.set("player_experience", player_system.get("player_experience") + amount)
		if player_system.has_method("_check_level_up"):
			player_system._check_level_up()
		return

	# 回退：尝试直接通过GameManager
	var game_manager: Node = _get_game_manager()
	if game_manager and game_manager.has_method("add_player_experience"):
		game_manager.add_player_experience(amount)

## 添加卡牌到收集
func _add_card_to_collection(card_id: String) -> void:
	print("[QuestSystem] 添加卡牌到收集：", card_id)

	# 通过GameManager获取CardDatabase
	var card_database: Node = _get_game_manager().get_node_or_null("CardDatabase") if _get_game_manager() else null
	if card_database == null:
		card_database = get_node_or_null("/root/CardDatabase")
	if card_database == null:
		push_warning("[QuestSystem] CardDatabase not found")
		notification_requested.emit("卡牌奖励添加失败")
		return

	# 获取卡牌数据
	var card_data: Dictionary = card_database.get_card(card_id) if card_database.has_method("get_card") else {}
	if card_data.is_empty():
		push_warning("[QuestSystem] Card not found: " + card_id)
		return

	# 尝试添加到DeckBuildingManager
	var deck_manager: Node = get_node_or_null("/root/DeckBuildingManager")
	if deck_manager and deck_manager.has_method("add_card_to_collection"):
		deck_manager.add_card_to_collection(card_data)
		notification_requested.emit("任务奖励：获得卡牌 " + str(card_data.get("name", card_id)))
	else:
		notification_requested.emit("任务奖励：获得卡牌 " + str(card_data.get("name", card_id)))

	# 发送奖励信号
	reward_granted.emit("card", 1)

## 添加物品到背包
func _add_item_to_inventory(item_name: String) -> void:
	print("[QuestSystem] 添加物品到背包：", item_name)

	var player_system: Node = _get_player_system()

	# 根据物品类型应用效果
	match item_name:
		"生命药水":
			if player_system and player_system.get("player_health") != null:
				var current_health: int = player_system.get("player_health")
				var max_health: int = player_system.get("player_max_health")
				player_system.set("player_health", mini(current_health + 50, max_health))
				notification_requested.emit("任务奖励：使用生命药水，恢复50点生命值")
			else:
				notification_requested.emit("任务奖励：获得生命药水")
		"魔法药水":
			notification_requested.emit("任务奖励：获得魔法药水")
		"护甲碎片":
			if player_system and player_system.get("player_defense") != null:
				var current_defense: int = player_system.get("player_defense")
				player_system.set("player_defense", current_defense + 2)
				notification_requested.emit("任务奖励：护甲碎片，防御+2")
			else:
				notification_requested.emit("任务奖励：获得护甲碎片")
		_:
			notification_requested.emit("任务奖励：获得 " + item_name)

	# 发送奖励信号
	reward_granted.emit("item", 1)

#endregion
