## 卡牌数据库
## 管理所有卡牌数据的加载和查询
## 支持从 .tres 资源文件和 .json 数据文件加载卡牌

class_name CardDatabase
extends Node

# 卡牌数据缓存
var _cards: Dictionary = {}

# 信号
signal card_loaded(card_id: String)
signal database_loaded()

func _ready() -> void:
	# 初始化数据库
	initialize()

## 初始化数据库
func initialize() -> void:
	print("[CardDatabase] Initializing...")
	_load_all_cards()
	database_loaded.emit()
	print("[CardDatabase] Loaded ", _cards.size(), " cards")

## 加载所有卡牌
func _load_all_cards() -> void:
	# 扫描卡牌目录
	var cards_dir = "res://data/cards/"
	var dir = DirAccess.open(cards_dir)
	
	if not dir:
		push_warning("[CardDatabase] Cards directory not found: " + cards_dir)
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".tres"):
			_load_tres_card(cards_dir + file_name)
		elif file_name.ends_with(".json"):
			_load_json_cards(cards_dir + file_name)
		file_name = dir.get_next()

## 加载 .tres 格式卡牌
func _load_tres_card(card_path: String) -> void:
	var card = load(card_path)
	if card and card is CardData:
		_cards[card.id] = card
		card_loaded.emit(card.id)

## 加载 .json 格式卡牌数据
func _load_json_cards(json_path: String) -> void:
	var file = FileAccess.open(json_path, FileAccess.READ)
	if not file:
		push_warning("[CardDatabase] Cannot open JSON file: " + json_path)
		return
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_string)
	if error != OK:
		push_warning("[CardDatabase] JSON parse error in " + json_path + ": " + json.get_error_message())
		return
	
	var data = json.data
	if not data is Dictionary or not data.has("cards"):
		push_warning("[CardDatabase] Invalid JSON structure in " + json_path)
		return
	
	for card_dict in data["cards"]:
		var card = _create_card_from_dict(card_dict)
		if card:
			_cards[card.id] = card
			card_loaded.emit(card.id)

## 从字典创建卡牌数据
func _create_card_from_dict(card_dict: Dictionary) -> CardData:
	if not card_dict.has("id"):
		push_warning("[CardDatabase] Card missing 'id' field")
		return null
	
	var card = CardData.new()
	card.id = card_dict.get("id", "")
	card.display_name = card_dict.get("display_name", "")
	card.description = card_dict.get("description", "")
	card.cost = card_dict.get("cost", 0)
	card.hp_cost = card_dict.get("hp_cost", 0)
	card.mp_cost = card_dict.get("mp_cost", 0)
	card.is_single_use = card_dict.get("is_single_use", false)
	
	# 解析枚举类型
	card.card_type = _parse_card_type(card_dict.get("card_type", "DIRECT_DAMAGE"))
	card.element = _parse_element(card_dict.get("element", "NONE"))
	card.rarity = _parse_rarity(card_dict.get("rarity", "COMMON"))
	
	# 解析效果列表
	var effects_array = card_dict.get("effects", [])
	for effect_dict in effects_array:
		var effect = _create_effect_from_dict(effect_dict)
		if effect:
			card.effects.append(effect)
	
	return card

## 从字典创建卡牌效果
func _create_effect_from_dict(effect_dict: Dictionary) -> CardEffect:
	var effect = CardEffect.new()
	effect.effect_type = _parse_effect_type(effect_dict.get("effect_type", "DAMAGE"))
	effect.value = effect_dict.get("value", 0)
	effect.target = _parse_target_type(effect_dict.get("target", "ENEMY"))
	effect.duration = effect_dict.get("duration", 0)
	effect.secondary_value = effect_dict.get("secondary_value", 0)
	effect.condition = effect_dict.get("condition", "")
	return effect

## 解析卡牌类型
func _parse_card_type(type_string: String) -> CardEnums.CardType:
	match type_string:
		"SUMMON":
			return CardEnums.CardType.SUMMON
		"DIRECT_DAMAGE":
			return CardEnums.CardType.DIRECT_DAMAGE
		"ENVIRONMENT":
			return CardEnums.CardType.ENVIRONMENT
		"BUFF_DEBUFF":
			return CardEnums.CardType.BUFF_DEBUFF
		_:
			push_warning("[CardDatabase] Unknown card type: " + type_string)
			return CardEnums.CardType.DIRECT_DAMAGE

## 解析元素类型
func _parse_element(element_string: String) -> CardEnums.Element:
	match element_string:
		"NONE":
			return CardEnums.Element.NONE
		"FIRE":
			return CardEnums.Element.FIRE
		"WATER":
			return CardEnums.Element.WATER
		"EARTH":
			return CardEnums.Element.EARTH
		"WIND":
			return CardEnums.Element.WIND
		"LIGHTNING":
			return CardEnums.Element.LIGHTNING
		_:
			push_warning("[CardDatabase] Unknown element: " + element_string)
			return CardEnums.Element.NONE

## 解析稀有度
func _parse_rarity(rarity_string: String) -> CardEnums.Rarity:
	match rarity_string:
		"COMMON":
			return CardEnums.Rarity.COMMON
		"UNCOMMON":
			return CardEnums.Rarity.UNCOMMON
		"RARE":
			return CardEnums.Rarity.RARE
		"LEGENDARY":
			return CardEnums.Rarity.LEGENDARY
		_:
			push_warning("[CardDatabase] Unknown rarity: " + rarity_string)
			return CardEnums.Rarity.COMMON

## 解析效果类型
func _parse_effect_type(type_string: String) -> CardEnums.EffectType:
	match type_string:
		"DAMAGE":
			return CardEnums.EffectType.DAMAGE
		"HEAL":
			return CardEnums.EffectType.HEAL
		"SUMMON":
			return CardEnums.EffectType.SUMMON
		"BUFF":
			return CardEnums.EffectType.BUFF
		"DEBUFF":
			return CardEnums.EffectType.DEBUFF
		"ENVIRONMENT_CHANGE":
			return CardEnums.EffectType.ENVIRONMENT_CHANGE
		_:
			push_warning("[CardDatabase] Unknown effect type: " + type_string)
			return CardEnums.EffectType.DAMAGE

## 解析目标类型
func _parse_target_type(target_string: String) -> CardEnums.TargetType:
	match target_string:
		"SELF":
			return CardEnums.TargetType.SELF
		"ENEMY":
			return CardEnums.TargetType.ENEMY
		"ALL_ENEMIES":
			return CardEnums.TargetType.ALL_ENEMIES
		"ALL_ALLIES":
			return CardEnums.TargetType.ALL_ALLIES
		"RANDOM":
			return CardEnums.TargetType.RANDOM
		_:
			push_warning("[CardDatabase] Unknown target type: " + target_string)
			return CardEnums.TargetType.ENEMY

## 获取卡牌
func get_card(card_id: String) -> CardData:
	return _cards.get(card_id)

## 获取所有卡牌
func get_all_cards() -> Array[CardData]:
	var cards: Array[CardData] = []
	for card in _cards.values():
		cards.append(card)
	return cards

## 按类型获取卡牌
func get_cards_by_type(card_type: CardEnums.CardType) -> Array[CardData]:
	var cards: Array[CardData] = []
	for card in _cards.values():
		if card.card_type == card_type:
			cards.append(card)
	return cards

## 按元素获取卡牌
func get_cards_by_element(element: CardEnums.Element) -> Array[CardData]:
	var cards: Array[CardData] = []
	for card in _cards.values():
		if card.element == element:
			cards.append(card)
	return cards

## 按稀有度获取卡牌
func get_cards_by_rarity(rarity: CardEnums.Rarity) -> Array[CardData]:
	var cards: Array[CardData] = []
	for card in _cards.values():
		if card.rarity == rarity:
			cards.append(card)
	return cards

## 搜索卡牌
func search_cards(query: String) -> Array[CardData]:
	var results: Array[CardData] = []
	var lower_query = query.to_lower()
	
	for card in _cards.values():
		if card.display_name.to_lower().contains(lower_query) or card.description.to_lower().contains(lower_query):
			results.append(card)
	
	return results

## 获取卡牌数量
func get_card_count() -> int:
	return _cards.size()

## 检查卡牌是否存在
func has_card(card_id: String) -> bool:
	return _cards.has(card_id)

## 添加卡牌
func add_card(card: CardData) -> void:
	if card and not card.id.is_empty():
		_cards[card.id] = card
		card_loaded.emit(card.id)

## 移除卡牌
func remove_card(card_id: String) -> void:
	if _cards.has(card_id):
		_cards.erase(card_id)

## 清空数据库
func clear() -> void:
	_cards.clear()

## 重新加载
func reload() -> void:
	clear()
	_load_all_cards()
	database_loaded.emit()
