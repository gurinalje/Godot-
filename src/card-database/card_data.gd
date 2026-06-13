# card_data.gd
# 卡牌数据资源类
# 定义单张卡牌的所有属性和行为

class_name CardData
extends Resource

## 卡牌唯一标识符
@export var id: String = ""

## 卡牌显示名称
@export var name: String = ""

## 卡牌效果描述
@export var description: String = ""

## 卡牌类型
@export var card_type: CardEnums.CardType = CardEnums.CardType.DIRECT_DAMAGE

## 能量消耗
@export_range(0, 10) var cost: int = 1

## 效果列表
@export var effects: Array[CardEffect] = []

## 稀有度
@export var rarity: CardEnums.Rarity = CardEnums.Rarity.COMMON

## 元素类型
@export var element: CardEnums.Element = CardEnums.Element.NONE

## 卡牌插画
@export var artwork: Texture2D = null

## 额外HP消耗
@export var hp_cost: int = 0

## 额外MP消耗
@export var mp_cost: int = 0

## 是否是一次性道具（使用后销毁）
@export var is_single_use: bool = false

## 关键词标签
@export var keywords: Array[String] = []

## 卡牌状态（运行时）
var state: CardEnums.CardState = CardEnums.CardState.UNLOCKED

## 获取卡牌类型名称
func get_type_name() -> String:
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

## 获取稀有度名称
func get_rarity_name() -> String:
	match rarity:
		CardEnums.Rarity.COMMON:
			return "Common"
		CardEnums.Rarity.UNCOMMON:
			return "Uncommon"
		CardEnums.Rarity.RARE:
			return "Rare"
		CardEnums.Rarity.LEGENDARY:
			return "Legendary"
		_:
			return "Unknown"

## 获取元素名称
func get_element_name() -> String:
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

## 获取完整描述（包含所有效果）
func get_full_description() -> String:
	var full_desc: String = description + "\n"
	for effect in effects:
		full_desc += "\n• " + effect.get_description()
	return full_desc

## 计算效果总价值（用于平衡性检查）
func calculate_effect_value() -> float:
	var total_value: float = 0.0
	var rarity_mult: float = CardEnums.get_rarity_multiplier(rarity)
	
	for effect in effects:
		var base_value: float = float(effect.value)
		# 持续效果价值更高
		if effect.duration > 0:
			base_value *= (1.0 + effect.duration * 0.3)
		total_value += base_value
	
	return total_value * rarity_mult

## 检查能量消耗是否合理
func is_cost_balanced() -> bool:
	var effect_value: float = calculate_effect_value()
	# 简单平衡检查：效果价值应该在成本的8-15倍之间
	var min_value: float = cost * 8.0
	var max_value: float = cost * 15.0
	return effect_value >= min_value and effect_value <= max_value

## 克隆卡牌（用于创建独立副本）
func clone() -> CardData:
	var new_card: CardData = CardData.new()
	new_card.id = id
	new_card.name = name
	new_card.description = description
	new_card.card_type = card_type
	new_card.cost = cost
	new_card.rarity = rarity
	new_card.element = element
	new_card.artwork = artwork
	new_card.hp_cost = hp_cost
	new_card.mp_cost = mp_cost
	new_card.is_single_use = is_single_use
	new_card.keywords = keywords.duplicate()
	
	# 克隆效果列表
	new_card.effects.clear()
	for effect in effects:
		new_card.effects.append(effect.clone())
	
	return new_card

## 序列化为字典（用于存档）
func to_dict() -> Dictionary:
	var effects_data: Array[Dictionary] = []
	for effect in effects:
		effects_data.append(effect.to_dict())
	
	return {
		"id": id,
		"name": name,
		"description": description,
		"card_type": card_type,
		"cost": cost,
		"rarity": rarity,
		"element": element,
		"hp_cost": hp_cost,
		"mp_cost": mp_cost,
		"is_single_use": is_single_use,
		"effects": effects_data,
		"keywords": keywords,
		"state": state
	}

## 从字典反序列化
static func from_dict(data: Dictionary) -> CardData:
	var card: CardData = CardData.new()
	card.id = data.get("id", "")
	card.name = data.get("name", "")
	card.description = data.get("description", "")
	card.card_type = data.get("card_type", CardEnums.CardType.DIRECT_DAMAGE)
	card.cost = data.get("cost", 1)
	card.rarity = data.get("rarity", CardEnums.Rarity.COMMON)
	card.element = data.get("element", CardEnums.Element.NONE)
	card.hp_cost = data.get("hp_cost", 0)
	card.mp_cost = data.get("mp_cost", 0)
	card.is_single_use = data.get("is_single_use", false)
	card.keywords = data.get("keywords", [])
	card.state = data.get("state", CardEnums.CardState.UNLOCKED)
	
	# 反序列化效果
	var effects_data: Array = data.get("effects", [])
	for effect_data in effects_data:
		if effect_data is Dictionary:
			card.effects.append(CardEffect.from_dict(effect_data))
	
	return card

## 检查是否包含关键词
func has_keyword(keyword: String) -> bool:
	return keywords.has(keyword)

## 检查是否匹配过滤条件
func matches_filter(filter: Dictionary) -> bool:
	# 过滤卡牌类型
	if filter.has("card_type") and filter["card_type"] != card_type:
		return false
	
	# 过滤稀有度
	if filter.has("rarity") and filter["rarity"] != rarity:
		return false
	
	# 过滤元素
	if filter.has("element") and filter["element"] != element:
		return false
	
	# 过滤费用范围
	if filter.has("min_cost") and cost < filter["min_cost"]:
		return false
	if filter.has("max_cost") and cost > filter["max_cost"]:
		return false
	
	# 过滤关键词
	if filter.has("keyword") and not has_keyword(filter["keyword"]):
		return false
	
	return true
