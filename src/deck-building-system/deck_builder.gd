## 卡组构筑器
## 管理玩家的卡组构建、卡牌添加/移除、卡组优化
## 是卡牌战斗系统的核心组件
class_name DeckBuilder
extends Node

## 卡组变化信号
signal card_added_to_deck(card_id: String)
signal card_removed_from_deck(card_id: String)
signal deck_changed()
signal deck_validated(is_valid: bool)

## 卡组配置
const MIN_DECK_SIZE = 20
const MAX_DECK_SIZE = 40
const MAX_CARD_COPIES = 3

## 玩家卡组（card_id -> 数量）
var player_deck: Dictionary = {}

## 卡组历史记录
var deck_history: Array[Dictionary] = []

## 可用卡牌池
var available_cards: Array[String] = []

## 初始化卡组构筑器
func _ready() -> void:
	# 初始化可用卡牌池
	_initialize_available_cards()

## 初始化可用卡牌池
func _initialize_available_cards() -> void:
	# 从卡牌数据库获取所有可用卡牌
	var card_database = GameManager.get_system("CardDatabase")
	if card_database:
		available_cards = card_database.get_all_card_ids()

## 添加卡牌到卡组
func add_card(card_id: String) -> bool:
	# 检查卡牌是否可用
	if card_id not in available_cards:
		push_warning("Card not available: %s" % card_id)
		return false
	
	# 检查卡组是否已满
	if get_deck_size() >= MAX_DECK_SIZE:
		push_warning("Deck is full")
		return false
	
	# 检查卡牌数量限制
	var current_count = player_deck.get(card_id, 0)
	if current_count >= MAX_CARD_COPIES:
		push_warning("Max copies reached for card: %s" % card_id)
		return false
	
	# 添加卡牌
	player_deck[card_id] = current_count + 1
	card_added_to_deck.emit(card_id)
	deck_changed.emit()
	
	# 记录历史
	_record_deck_change("add", card_id)
	
	return true

## 从卡组移除卡牌
func remove_card(card_id: String) -> bool:
	if card_id not in player_deck:
		push_warning("Card not in deck: %s" % card_id)
		return false
	
	# 移除卡牌
	player_deck[card_id] -= 1
	if player_deck[card_id] <= 0:
		player_deck.erase(card_id)
	
	card_removed_from_deck.emit(card_id)
	deck_changed.emit()
	
	# 记录历史
	_record_deck_change("remove", card_id)
	
	return true

## 获取卡组大小
func get_deck_size() -> int:
	var total = 0
	for count in player_deck.values():
		total += count
	return total

## 获取卡牌数量
func get_card_count(card_id: String) -> int:
	return player_deck.get(card_id, 0)

## 获取卡组中所有卡牌
func get_all_cards() -> Array[String]:
	var cards: Array[String] = []
	for card_id in player_deck:
		for i in range(player_deck[card_id]):
			cards.append(card_id)
	return cards

## 获取卡组中唯一卡牌
func get_unique_cards() -> Array[String]:
	return player_deck.keys()

## 检查卡组是否有效
func validate_deck() -> bool:
	var deck_size = get_deck_size()
	if deck_size < MIN_DECK_SIZE or deck_size > MAX_DECK_SIZE:
		deck_validated.emit(false)
		return false
	
	# 检查每张卡牌数量
	for card_id in player_deck:
		if player_deck[card_id] > MAX_CARD_COPIES:
			deck_validated.emit(false)
			return false
	
	deck_validated.emit(true)
	return true

## 清空卡组
func clear_deck() -> void:
	player_deck.clear()
	deck_changed.emit()
	_record_deck_change("clear", "")

## 随机生成卡组
func generate_random_deck(size: int = MIN_DECK_SIZE) -> void:
	clear_deck()
	
	# 确保大小在有效范围内
	size = clampi(size, MIN_DECK_SIZE, MAX_DECK_SIZE)
	
	# 随机添加卡牌
	var cards_added = 0
	while cards_added < size:
		var random_card = available_cards[randi() % available_cards.size()]
		if add_card(random_card):
			cards_added += 1

## 优化卡组（移除重复卡牌，保持多样性）
func optimize_deck() -> void:
	# 统计卡牌类型分布
	var type_counts = {}
	for card_id in player_deck:
		var card_data = _get_card_data(card_id)
		if card_data:
			var card_type = card_data.get("type", "unknown")
			type_counts[card_type] = type_counts.get(card_type, 0) + player_deck[card_id]
	
	# 计算理想分布（假设4种类型）
	var ideal_per_type = get_deck_size() / 4
	
	# 调整分布（简单优化）
	for card_type in type_counts:
		if type_counts[card_type] > ideal_per_type * 1.5:
			# 移除多余卡牌
			_excess_cards_of_type(card_type, type_counts[card_type] - ideal_per_type)

## 获取指定类型的多余卡牌
func _excess_cards_of_type(card_type: String, excess_count: int) -> void:
	var removed = 0
	for card_id in player_deck.keys():
		if removed >= excess_count:
			break
		
		var card_data = _get_card_data(card_id)
		if card_data and card_data.get("type", "") == card_type:
			if remove_card(card_id):
				removed += 1

## 获取卡牌数据
func _get_card_data(card_id: String) -> Dictionary:
	var card_database = GameManager.get_system("CardDatabase")
	if card_database:
		var card = card_database.get_card(card_id)
		if card:
			return {
				"id": card.id,
				"name": card.name,
				"type": card.card_type,
				"cost": card.cost,
				"rarity": card.rarity
			}
	return {}

## 记录卡组变化
func _record_deck_change(action: String, card_id: String) -> void:
	var record = {
		"action": action,
		"card_id": card_id,
		"deck_size": get_deck_size(),
		"timestamp": Time.get_unix_time_from_system()
	}
	deck_history.append(record)

## 获取卡组历史
func get_deck_history() -> Array[Dictionary]:
	return deck_history.duplicate()

## 获取卡组统计
func get_deck_stats() -> Dictionary:
	var stats = {
		"total_cards": get_deck_size(),
		"unique_cards": player_deck.size(),
		"average_cost": 0.0,
		"type_distribution": {}
	}
	
	# 计算平均费用
	var total_cost = 0.0
	for card_id in player_deck:
		var card_data = _get_card_data(card_id)
		if card_data:
			total_cost += card_data.get("cost", 0) * player_deck[card_id]
	
	if stats.total_cards > 0:
		stats.average_cost = total_cost / stats.total_cards
	
	return stats

## 保存卡组数据
func save_data() -> Dictionary:
	return {
		"player_deck": player_deck,
		"deck_history": deck_history
	}

## 加载卡组数据
func load_data(data: Dictionary) -> void:
	player_deck = data.get("player_deck", {})
	deck_history = data.get("deck_history", [])
	deck_changed.emit()

## 重置卡组系统
func reset() -> void:
	player_deck.clear()
	deck_history.clear()
	deck_changed.emit()
