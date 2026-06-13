## 卡组构筑管理器
## 管理玩家的卡组构建和编辑

class_name DeckBuildingManager
extends Node

# 当前卡组
var current_deck: Array[CardData] = []

# 卡组容量限制
const MIN_DECK_SIZE = 20
const MAX_DECK_SIZE = 40

# 信号
signal deck_updated()
signal card_added(card: CardData)
signal card_removed(card: CardData)

func _ready() -> void:
	initialize()

func initialize() -> void:
	print("[DeckBuildingManager] Initialized")
	_create_starter_deck()

## 创建初始卡组
func _create_starter_deck() -> void:
	current_deck.clear()  # 清空现有卡组，防止重复添加
	var card_database = GameManager.get_system("CardDatabase")
	if not card_database:
		push_warning("[DeckBuildingManager] CardDatabase not found")
		return
	
	# 添加初始卡牌
	var starter_cards = [
		"fireball", "fireball", "fireball",
		"lightning", "lightning",
		"shield", "shield", "shield",
		"holy_blessing", "holy_blessing",
		"blizzard",
		"summon_skeleton", "summon_skeleton",
		"earthquake",
		"dark_curse"
	]
	
	for card_id in starter_cards:
		var card = card_database.get_card(card_id)
		if card:
			current_deck.append(card)
	
	print("[DeckBuildingManager] Created starter deck with ", current_deck.size(), " cards")

## 创建初始卡组（公共接口）
func create_starter_deck() -> void:
	_create_starter_deck()

## 获取当前卡组
func get_current_deck() -> Array[CardData]:
	return current_deck.duplicate()

## 添加卡牌到卡组
func add_card(card: CardData) -> bool:
	if current_deck.size() >= MAX_DECK_SIZE:
		push_warning("[DeckBuildingManager] Deck is full")
		return false
	
	current_deck.append(card)
	card_added.emit(card)
	deck_updated.emit()
	return true

## 从卡组移除卡牌
func remove_card(card_index: int) -> bool:
	if card_index < 0 or card_index >= current_deck.size():
		push_warning("[DeckBuildingManager] Invalid card index: " + str(card_index))
		return false
	
	if current_deck.size() <= MIN_DECK_SIZE:
		push_warning("[DeckBuildingManager] Cannot remove card - minimum deck size reached")
		return false
	
	var card = current_deck[card_index]
	current_deck.remove_at(card_index)
	card_removed.emit(card)
	deck_updated.emit()
	return true

## 获取卡组大小
func get_deck_size() -> int:
	return current_deck.size()

## 检查卡组是否有效
func is_deck_valid() -> bool:
	return current_deck.size() >= MIN_DECK_SIZE and current_deck.size() <= MAX_DECK_SIZE

## 清空卡组
func clear_deck() -> void:
	current_deck.clear()
	deck_updated.emit()

## 洗牌
func shuffle_deck() -> void:
	current_deck.shuffle()
	deck_updated.emit()

## 获取卡牌统计
func get_card_stats() -> Dictionary:
	var stats = {
		"total": current_deck.size(),
		"by_type": {},
		"by_element": {},
		"by_rarity": {}
	}
	
	for card in current_deck:
		# 按类型统计
		var type = card.card_type
		stats["by_type"][type] = stats["by_type"].get(type, 0) + 1
		
		# 按元素统计
		var element = card.element
		stats["by_element"][element] = stats["by_element"].get(element, 0) + 1
		
		# 按稀有度统计
		var rarity = card.rarity
		stats["by_rarity"][rarity] = stats["by_rarity"].get(rarity, 0) + 1
	
	return stats

## 搜索卡组中的卡牌
func search_deck(query: String) -> Array[CardData]:
	var results: Array[CardData] = []
	var lower_query = query.to_lower()
	
	for card in current_deck:
		if card.name.to_lower().contains(lower_query):
			results.append(card)
	
	return results

## 序列化为字典（用于存档）
func to_dict() -> Dictionary:
	var card_ids: Array[String] = []
	for card in current_deck:
		card_ids.append(card.id)
	return {
		"deck": card_ids
	}

## 从字典反序列化（用于读档）
func load_from_dict(data: Dictionary) -> void:
	current_deck.clear()
	var card_database = GameManager.get_system("CardDatabase")
	if not card_database:
		push_warning("[DeckBuildingManager] CardDatabase not found for load_from_dict")
		return
	
	var card_ids = data.get("deck", [])
	for card_id in card_ids:
		var card = card_database.get_card(card_id)
		if card:
			current_deck.append(card)
	
	deck_updated.emit()
