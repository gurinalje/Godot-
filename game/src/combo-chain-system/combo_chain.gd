# combo_chain.gd
# 连锁规则资源类
# 定义单个连锁规则的所有属性

@tool
class_name ComboChain
extends Resource

## 连锁类型枚举
enum ChainType {
	CARD_TYPE,     ## 卡牌类型连锁
	ELEMENT,       ## 元素连锁
	KEYWORD,       ## 关键词连锁
	SEQUENCE       ## 顺序连锁
}

## 连锁效果类型枚举
enum ChainEffectType {
	DAMAGE_BONUS,      ## 伤害加成
	EXTRA_EFFECT,      ## 额外效果
	ENERGY_REFUND,     ## 能量返还
	DRAW_CARD          ## 抽牌奖励
}

## 连锁ID
@export var chain_id: String = ""

## 连锁名称
@export var chain_name: String = ""

## 连锁描述
@export var description: String = ""

## 连锁类型
@export var chain_type: ChainType = ChainType.CARD_TYPE

## 触发条件（卡牌类型组合、元素组合等）
@export var trigger_conditions: Dictionary = {}

## 连锁效果类型
@export var effect_type: ChainEffectType = ChainEffectType.DAMAGE_BONUS

## 连锁效果数值
@export var effect_value: float = 0.5

## 连锁优先级（用于多连锁同时触发时的排序）
@export var priority: int = 0

## 连锁图标
@export var icon: Texture2D = null

## 连锁颜色（用于UI显示）
@export var chain_color: Color = Color(1.0, 0.8, 0.0)

## 初始化
func _init() -> void:
	pass

## 检查是否满足连锁条件
func check_conditions(played_cards: Array[CardData]) -> bool:
	if played_cards.is_empty():
		return false
	
	match chain_type:
		ChainType.CARD_TYPE:
			return _check_card_type_conditions(played_cards)
		ChainType.ELEMENT:
			return _check_element_conditions(played_cards)
		ChainType.KEYWORD:
			return _check_keyword_conditions(played_cards)
		ChainType.SEQUENCE:
			return _check_sequence_conditions(played_cards)
	
	return false

## 检查卡牌类型条件
func _check_card_type_conditions(played_cards: Array[CardData]) -> bool:
	var required_types: Array = trigger_conditions.get("card_types", [])
	if required_types.is_empty():
		return false
	
	# 检查是否所有必需类型都存在
	var played_types: Dictionary = {}
	for card in played_cards:
		played_types[card.card_type] = true
	
	for required_type in required_types:
		if not played_types.has(required_type):
			return false
	
	return true

## 检查元素条件
func _check_element_conditions(played_cards: Array[CardData]) -> bool:
	var required_elements: Array = trigger_conditions.get("elements", [])
	if required_elements.is_empty():
		return false
	
	# 检查是否所有必需元素都存在
	var played_elements: Dictionary = {}
	for card in played_cards:
		if card.element != CardEnums.Element.NONE:
			played_elements[card.element] = true
	
	for required_element in required_elements:
		if not played_elements.has(required_element):
			return false
	
	return true

## 检查关键词条件
func _check_keyword_conditions(played_cards: Array[CardData]) -> bool:
	var required_keywords: Array = trigger_conditions.get("keywords", [])
	if required_keywords.is_empty():
		return false
	
	# 检查是否所有必需关键词都存在
	var played_keywords: Dictionary = {}
	for card in played_cards:
		for keyword in card.keywords:
			played_keywords[keyword] = true
	
	for required_keyword in required_keywords:
		if not played_keywords.has(required_keyword):
			return false
	
	return true

## 检查顺序条件
func _check_sequence_conditions(played_cards: Array[CardData]) -> bool:
	var required_sequence: Array = trigger_conditions.get("sequence", [])
	if required_sequence.is_empty():
		return false
	
	# 检查出牌顺序是否匹配
	if played_cards.size() < required_sequence.size():
		return false
	
	var start_index: int = played_cards.size() - required_sequence.size()
	for i in range(required_sequence.size()):
		var required_type: int = required_sequence[i]
		var actual_card: CardData = played_cards[start_index + i]
		if actual_card.card_type != required_type:
			return false
	
	return true

## 获取连锁效果描述
func get_effect_description() -> String:
	match effect_type:
		ChainEffectType.DAMAGE_BONUS:
			return "Damage +%d%%" % int(effect_value * 100)
		ChainEffectType.EXTRA_EFFECT:
			return "Trigger extra effect"
		ChainEffectType.ENERGY_REFUND:
			return "Refund %d energy" % int(effect_value)
		ChainEffectType.DRAW_CARD:
			return "Draw %d cards" % int(effect_value)
		_:
			return "Unknown effect"

## 获取连锁条件描述
func get_conditions_description() -> String:
	var desc: String = ""
	
	match chain_type:
		ChainType.CARD_TYPE:
			var types: Array = trigger_conditions.get("card_types", [])
			for i in range(types.size()):
				if i > 0:
					desc += " + "
				desc += _get_card_type_name(types[i])
		ChainType.ELEMENT:
			var elements: Array = trigger_conditions.get("elements", [])
			for i in range(elements.size()):
				if i > 0:
					desc += " + "
				desc += _get_element_name(elements[i])
		ChainType.KEYWORD:
			var keywords: Array = trigger_conditions.get("keywords", [])
			desc = "关键词: " + ", ".join(keywords)
		ChainType.SEQUENCE:
			var sequence: Array = trigger_conditions.get("sequence", [])
			for i in range(sequence.size()):
				if i > 0:
					desc += " → "
				desc += _get_card_type_name(sequence[i])
	
	return desc

## 获取卡牌类型名称
func _get_card_type_name(card_type: int) -> String:
	match card_type:
		CardEnums.CardType.SUMMON:
			return "Summon"
		CardEnums.CardType.DIRECT_DAMAGE:
			return "Damage"
		CardEnums.CardType.ENVIRONMENT:
			return "Environment"
		CardEnums.CardType.BUFF_DEBUFF:
			return "Buff"
		_:
			return "Unknown"

## 获取元素名称
func _get_element_name(element: int) -> String:
	match element:
		CardEnums.Element.FIRE:
			return "Fire"
		CardEnums.Element.WATER:
			return "Water"
		CardEnums.Element.EARTH:
			return "Earth"
		CardEnums.Element.WIND:
			return "Wind"
		CardEnums.Element.LIGHTNING:
			return "Lightning"
		_:
			return "None"

## 序列化为字典
func to_dict() -> Dictionary:
	return {
		"chain_id": chain_id,
		"chain_name": chain_name,
		"description": description,
		"chain_type": chain_type,
		"trigger_conditions": trigger_conditions,
		"effect_type": effect_type,
		"effect_value": effect_value,
		"priority": priority
	}

## 从字典反序列化
static func from_dict(data: Dictionary) -> ComboChain:
	var chain: ComboChain = ComboChain.new()
	chain.chain_id = data.get("chain_id", "")
	chain.chain_name = data.get("chain_name", "")
	chain.description = data.get("description", "")
	chain.chain_type = data.get("chain_type", ChainType.CARD_TYPE)
	chain.trigger_conditions = data.get("trigger_conditions", {})
	chain.effect_type = data.get("effect_type", ChainEffectType.DAMAGE_BONUS)
	chain.effect_value = data.get("effect_value", 0.5)
	chain.priority = data.get("priority", 0)
	return chain
