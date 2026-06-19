## 卡组管理器
## 管理玩家的卡组和卡牌收藏

class_name DeckManager
extends Node

# 卡牌收藏
var card_collection: Array[CardData] = []

# 卡组列表
var decks: Dictionary = {}

# 当前卡组
var current_deck_id: String = ""

# 信号
signal collection_updated()
signal deck_created(deck_id: String)
signal deck_updated(deck_id: String)
signal deck_deleted(deck_id: String)

func _ready() -> void:
	initialize()

func initialize() -> void:
	print("[DeckManager] Initialized")
	_create_default_deck()

## 创建默认卡组
func _create_default_deck() -> void:
	var deck_id = "default"
	decks[deck_id] = {
		"id": deck_id,
		"name": "默认卡组",
		"cards": []
	}
	current_deck_id = deck_id
	deck_created.emit(deck_id)

## 获取卡牌收藏
func get_card_collection() -> Array[CardData]:
	return card_collection

## 添加卡牌到收藏
func add_card_to_collection(card: CardData) -> void:
	card_collection.append(card)
	collection_updated.emit()
	print("[DeckManager] Added card to collection: ", card.display_name)

## 从收藏移除卡牌
func remove_card_from_collection(card_index: int) -> bool:
	if card_index < 0 or card_index >= card_collection.size():
		return false
	
	card_collection.remove_at(card_index)
	collection_updated.emit()
	return true

## 获取卡组
func get_deck(deck_id: String) -> Dictionary:
	return decks.get(deck_id, {})

## 获取当前卡组
func get_current_deck() -> Dictionary:
	return decks.get(current_deck_id, {})

## 创建新卡组
func create_deck(name: String) -> String:
	var deck_id = "deck_" + str(decks.size())
	decks[deck_id] = {
		"id": deck_id,
		"name": name,
		"cards": []
	}
	deck_created.emit(deck_id)
	print("[DeckManager] Created deck: ", name)
	return deck_id

## 删除卡组
func delete_deck(deck_id: String) -> bool:
	if not decks.has(deck_id):
		return false
	
	if deck_id == current_deck_id:
		push_warning("[DeckManager] Cannot delete current deck")
		return false
	
	decks.erase(deck_id)
	deck_deleted.emit(deck_id)
	print("[DeckManager] Deleted deck: ", deck_id)
	return true

## 设置当前卡组
func set_current_deck(deck_id: String) -> bool:
	if not decks.has(deck_id):
		return false
	
	current_deck_id = deck_id
	print("[DeckManager] Set current deck: ", deck_id)
	return true

## 添加卡牌到卡组
func add_card_to_deck(deck_id: String, card: CardData) -> bool:
	if not decks.has(deck_id):
		return false
	
	var deck = decks[deck_id]
	deck["cards"].append(card)
	deck_updated.emit(deck_id)
	return true

## 从卡组移除卡牌
func remove_card_from_deck(deck_id: String, card_index: int) -> bool:
	if not decks.has(deck_id):
		return false
	
	var deck = decks[deck_id]
	var cards = deck["cards"]
	
	if card_index < 0 or card_index >= cards.size():
		return false
	
	cards.remove_at(card_index)
	deck_updated.emit(deck_id)
	return true

## 获取所有卡组
func get_all_decks() -> Dictionary:
	return decks

## 获取卡组数量
func get_deck_count() -> int:
	return decks.size()

## 搜索收藏中的卡牌
func search_collection(query: String) -> Array[CardData]:
	var results: Array[CardData] = []
	var lower_query = query.to_lower()
	
	for card in card_collection:
		if card.display_name.to_lower().contains(lower_query):
			results.append(card)
	
	return results
