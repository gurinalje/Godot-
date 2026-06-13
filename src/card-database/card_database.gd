## 卡牌数据库
## 管理所有卡牌数据的加载和查询

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
		_create_default_cards()
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".tres"):
			var card_path = cards_dir + file_name
			var card = load(card_path)
			if card and card is CardData:
				_cards[card.id] = card
				card_loaded.emit(card.id)
		file_name = dir.get_next()
	
	# 补充缺失的默认卡牌
	_ensure_default_cards()

## 确保默认卡牌存在
func _ensure_default_cards() -> void:
	var defaults = _get_default_card_definitions()
	# 始终用默认卡牌覆盖，确保ID一致性
	for card_id in defaults:
		_cards[card_id] = defaults[card_id]

## 获取默认卡牌定义
func _get_default_card_definitions() -> Dictionary:
	var cards: Dictionary = {}
	
	# 小型生命药水
	var item_health_potion = CardData.new()
	item_health_potion.id = "item_health_potion"
	item_health_potion.name = "小型生命药水"
	item_health_potion.description = "消耗10点MP，恢复30点HP"
	item_health_potion.card_type = CardEnums.CardType.BUFF_DEBUFF
	item_health_potion.element = CardEnums.Element.NONE
	item_health_potion.cost = 0
	item_health_potion.hp_cost = 0
	item_health_potion.mp_cost = 10
	item_health_potion.is_single_use = true
	item_health_potion.rarity = CardEnums.Rarity.COMMON
	var potion_heal_effect = CardEffect.new()
	potion_heal_effect.effect_type = CardEnums.EffectType.HEAL
	potion_heal_effect.value = 30
	potion_heal_effect.target = CardEnums.TargetType.SELF
	item_health_potion.effects.append(potion_heal_effect)
	cards["item_health_potion"] = item_health_potion
	
	# 恶魔药水
	var item_rage_potion = CardData.new()
	item_rage_potion.id = "item_rage_potion"
	item_rage_potion.name = "恶魔药水"
	item_rage_potion.description = "消耗20点HP，获得15点护甲"
	item_rage_potion.card_type = CardEnums.CardType.BUFF_DEBUFF
	item_rage_potion.element = CardEnums.Element.NONE
	item_rage_potion.cost = 0
	item_rage_potion.hp_cost = 20
	item_rage_potion.mp_cost = 0
	item_rage_potion.is_single_use = true
	item_rage_potion.rarity = CardEnums.Rarity.UNCOMMON
	var potion_shield_effect = CardEffect.new()
	potion_shield_effect.effect_type = CardEnums.EffectType.BUFF
	potion_shield_effect.value = 15
	potion_shield_effect.target = CardEnums.TargetType.SELF
	item_rage_potion.effects.append(potion_shield_effect)
	cards["item_rage_potion"] = item_rage_potion
	
	# 无消耗秘药
	var item_elixir = CardData.new()
	item_elixir.id = "item_elixir"
	item_elixir.name = "无消耗秘药"
	item_elixir.description = "获得8点护甲，无消耗且一次性"
	item_elixir.card_type = CardEnums.CardType.BUFF_DEBUFF
	item_elixir.element = CardEnums.Element.NONE
	item_elixir.cost = 0
	item_elixir.hp_cost = 0
	item_elixir.mp_cost = 0
	item_elixir.is_single_use = true
	item_elixir.rarity = CardEnums.Rarity.COMMON
	var elixir_shield_effect = CardEffect.new()
	elixir_shield_effect.effect_type = CardEnums.EffectType.BUFF
	elixir_shield_effect.value = 8
	elixir_shield_effect.target = CardEnums.TargetType.SELF
	item_elixir.effects.append(elixir_shield_effect)
	cards["item_elixir"] = item_elixir
	
	# 火球术
	var fireball = CardData.new()
	fireball.id = "fireball"
	fireball.name = "火球术"
	fireball.description = "造成8点火焰伤害"
	fireball.card_type = CardEnums.CardType.DIRECT_DAMAGE
	fireball.element = CardEnums.Element.FIRE
	fireball.cost = 2
	fireball.rarity = CardEnums.Rarity.COMMON
	var fireball_effect = CardEffect.new()
	fireball_effect.effect_type = CardEnums.EffectType.DAMAGE
	fireball_effect.value = 8
	fireball_effect.target = CardEnums.TargetType.ENEMY
	fireball.effects.append(fireball_effect)
	cards["fireball"] = fireball
	
	# 冰冻术
	var blizzard = CardData.new()
	blizzard.id = "blizzard"
	blizzard.name = "暴风雪"
	blizzard.description = "对所有敌人造成5点冰霜伤害"
	blizzard.card_type = CardEnums.CardType.ENVIRONMENT
	blizzard.element = CardEnums.Element.WATER
	blizzard.cost = 3
	blizzard.rarity = CardEnums.Rarity.RARE
	var blizzard_effect = CardEffect.new()
	blizzard_effect.effect_type = CardEnums.EffectType.DAMAGE
	blizzard_effect.value = 5
	blizzard_effect.target = CardEnums.TargetType.ALL_ENEMIES
	blizzard.effects.append(blizzard_effect)
	cards["blizzard"] = blizzard
	
	# 骷髅召唤
	var summon_skeleton = CardData.new()
	summon_skeleton.id = "summon_skeleton"
	summon_skeleton.name = "召唤骷髅"
	summon_skeleton.description = "召唤一个骷髅战士"
	summon_skeleton.card_type = CardEnums.CardType.SUMMON
	summon_skeleton.element = CardEnums.Element.EARTH
	summon_skeleton.cost = 3
	summon_skeleton.rarity = CardEnums.Rarity.COMMON
	var summon_effect = CardEffect.new()
	summon_effect.effect_type = CardEnums.EffectType.SUMMON
	summon_effect.value = 10
	summon_effect.target = CardEnums.TargetType.SELF
	summon_skeleton.effects.append(summon_effect)
	cards["summon_skeleton"] = summon_skeleton
	
	# 神圣祝福
	var holy_blessing = CardData.new()
	holy_blessing.id = "holy_blessing"
	holy_blessing.name = "神圣祝福"
	holy_blessing.description = "恢复10点生命值"
	holy_blessing.card_type = CardEnums.CardType.BUFF_DEBUFF
	holy_blessing.element = CardEnums.Element.WATER
	holy_blessing.cost = 2
	holy_blessing.rarity = CardEnums.Rarity.COMMON
	var heal_effect = CardEffect.new()
	heal_effect.effect_type = CardEnums.EffectType.HEAL
	heal_effect.value = 10
	heal_effect.target = CardEnums.TargetType.SELF
	holy_blessing.effects.append(heal_effect)
	cards["holy_blessing"] = holy_blessing
	
	# 护盾
	var shield = CardData.new()
	shield.id = "shield"
	shield.name = "护盾"
	shield.description = "获得5点护甲"
	shield.card_type = CardEnums.CardType.BUFF_DEBUFF
	shield.element = CardEnums.Element.EARTH
	shield.cost = 1
	shield.rarity = CardEnums.Rarity.COMMON
	var armor_effect = CardEffect.new()
	armor_effect.effect_type = CardEnums.EffectType.BUFF
	armor_effect.value = 5
	armor_effect.target = CardEnums.TargetType.SELF
	shield.effects.append(armor_effect)
	cards["shield"] = shield
	
	# 闪电箭
	var lightning = CardData.new()
	lightning.id = "lightning"
	lightning.name = "闪电箭"
	lightning.description = "造成6点雷电伤害"
	lightning.card_type = CardEnums.CardType.DIRECT_DAMAGE
	lightning.element = CardEnums.Element.LIGHTNING
	lightning.cost = 1
	lightning.rarity = CardEnums.Rarity.COMMON
	var lightning_effect = CardEffect.new()
	lightning_effect.effect_type = CardEnums.EffectType.DAMAGE
	lightning_effect.value = 6
	lightning_effect.target = CardEnums.TargetType.ENEMY
	lightning.effects.append(lightning_effect)
	cards["lightning"] = lightning
	
	# 地震术
	var earthquake = CardData.new()
	earthquake.id = "earthquake"
	earthquake.name = "地震术"
	earthquake.description = "对所有敌人造成4点土系伤害"
	earthquake.card_type = CardEnums.CardType.ENVIRONMENT
	earthquake.element = CardEnums.Element.EARTH
	earthquake.cost = 2
	earthquake.rarity = CardEnums.Rarity.RARE
	var earthquake_effect = CardEffect.new()
	earthquake_effect.effect_type = CardEnums.EffectType.DAMAGE
	earthquake_effect.value = 4
	earthquake_effect.target = CardEnums.TargetType.ALL_ENEMIES
	earthquake.effects.append(earthquake_effect)
	cards["earthquake"] = earthquake
	
	# 黑暗诅咒
	var dark_curse = CardData.new()
	dark_curse.id = "dark_curse"
	dark_curse.name = "黑暗诅咒"
	dark_curse.description = "使目标受到伤害增加50%"
	dark_curse.card_type = CardEnums.CardType.BUFF_DEBUFF
	dark_curse.element = CardEnums.Element.NONE
	dark_curse.cost = 2
	dark_curse.rarity = CardEnums.Rarity.RARE
	var debuff_effect = CardEffect.new()
	debuff_effect.effect_type = CardEnums.EffectType.DEBUFF
	debuff_effect.value = 50
	debuff_effect.target = CardEnums.TargetType.ENEMY
	debuff_effect.duration = 3
	dark_curse.effects.append(debuff_effect)
	cards["dark_curse"] = dark_curse
	
	return cards

## 创建默认卡牌
func _create_default_cards() -> void:
	var defaults = _get_default_card_definitions()
	for card_id in defaults:
		_cards[card_id] = defaults[card_id]
	print("[CardDatabase] Created ", _cards.size(), " default cards")

## 获取卡牌
func get_card(card_id: String):
	return _cards.get(card_id)

## 获取所有卡牌
func get_all_cards() -> Array:
	var cards: Array = []
	for card in _cards.values():
		cards.append(card)
	return cards

## 按类型获取卡牌
func get_cards_by_type(card_type) -> Array:
	var cards: Array = []
	for card in _cards.values():
		if card.card_type == card_type:
			cards.append(card)
	return cards

## 按元素获取卡牌
func get_cards_by_element(element) -> Array:
	var cards: Array = []
	for card in _cards.values():
		if card.element == element:
			cards.append(card)
	return cards

## 按稀有度获取卡牌
func get_cards_by_rarity(rarity) -> Array:
	var cards: Array = []
	for card in _cards.values():
		if card.rarity == rarity:
			cards.append(card)
	return cards

## 搜索卡牌
func search_cards(query: String) -> Array:
	var results: Array = []
	var lower_query = query.to_lower()
	
	for card in _cards.values():
		if card.name.to_lower().contains(lower_query) or card.description.to_lower().contains(lower_query):
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
