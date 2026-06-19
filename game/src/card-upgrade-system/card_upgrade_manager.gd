## 卡牌升级管理器
## 管理卡牌的升级和强化

class_name CardUpgradeManager
extends Node

# 升级材料
var upgrade_materials: Dictionary = {}

# 升级费用
var upgrade_costs: Dictionary = {
	1: {"gold": 100, "materials": {}},
	2: {"gold": 200, "materials": {"common_essence": 1}},
	3: {"gold": 400, "materials": {"rare_essence": 1}},
	4: {"gold": 800, "materials": {"epic_essence": 1}},
	5: {"gold": 1600, "materials": {"legendary_essence": 1}}
}

# 信号
signal card_upgraded(card_id: String, new_level: int)
signal upgrade_failed(card_id: String, reason: String)

func _ready() -> void:
	initialize()

func initialize() -> void:
	print("[CardUpgradeManager] Initialized")

## 升级卡牌
func upgrade_card(card: CardData) -> bool:
	if not card:
		push_warning("[CardUpgradeManager] Invalid card")
		return false
	
	var current_level = card.upgrade_level
	var max_level = 5
	
	if current_level >= max_level:
		upgrade_failed.emit(card.id, "Card already at max level")
		return false
	
	# 检查升级费用
	var cost = upgrade_costs.get(current_level + 1, {})
	if not _check_upgrade_cost(cost):
		upgrade_failed.emit(card.id, "Not enough resources")
		return false
	
	# 消耗材料
	_consume_upgrade_cost(cost)
	
	# 升级卡牌
	card.upgrade_level += 1
	_apply_upgrade_bonus(card)
	
	card_upgraded.emit(card.id, card.upgrade_level)
	print("[CardUpgradeManager] Upgraded card: ", card.id, " to level ", card.upgrade_level)
	return true

## 检查升级费用
func _check_upgrade_cost(cost: Dictionary) -> bool:
	# TODO: 检查玩家资源是否足够
	return true

## 消耗升级费用
func _consume_upgrade_cost(cost: Dictionary) -> void:
	# TODO: 消耗玩家资源
	pass

## 应用升级加成
func _apply_upgrade_bonus(card: CardData) -> void:
	# 根据卡牌类型应用不同的加成
	match card.card_type:
		CardEnums.CardType.DIRECT_DAMAGE:
			card.base_damage += 2
		CardEnums.CardType.SUMMON:
			card.base_damage += 1
		CardEnums.CardType.ENVIRONMENT:
			card.base_damage += 1
		CardEnums.CardType.BUFF_DEBUFF:
			card.base_heal += 2

## 获取升级费用
func get_upgrade_cost(card: CardData) -> Dictionary:
	if not card:
		return {}
	
	var next_level = card.upgrade_level + 1
	return upgrade_costs.get(next_level, {})

## 获取升级预览
func get_upgrade_preview(card: CardData) -> Dictionary:
	if not card:
		return {}
	
	var preview = {
		"current_level": card.upgrade_level,
		"next_level": card.upgrade_level + 1,
		"cost": get_upgrade_cost(card),
		"bonuses": {}
	}
	
	# 计算升级加成
	match card.card_type:
		CardEnums.CardType.DIRECT_DAMAGE:
			preview["bonuses"] = {"damage": 2}
		CardEnums.CardType.SUMMON:
			preview["bonuses"] = {"damage": 1}
		CardEnums.CardType.ENVIRONMENT:
			preview["bonuses"] = {"damage": 1}
		CardEnums.CardType.BUFF_DEBUFF:
			preview["bonuses"] = {"heal": 2}
	
	return preview

## 检查卡牌是否可以升级
func can_upgrade_card(card: CardData) -> bool:
	if not card:
		return false
	
	if card.upgrade_level >= 5:
		return false
	
	var cost = get_upgrade_cost(card)
	return _check_upgrade_cost(cost)

## 获取升级材料数量
func get_material_count(material_id: String) -> int:
	return upgrade_materials.get(material_id, 0)

## 添加升级材料
func add_material(material_id: String, amount: int) -> void:
	upgrade_materials[material_id] = upgrade_materials.get(material_id, 0) + amount
	print("[CardUpgradeManager] Added ", amount, " ", material_id)
