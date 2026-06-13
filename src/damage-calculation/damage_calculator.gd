## 伤害计算器
## 处理所有伤害计算逻辑

class_name DamageCalculator
extends Node

# 信号
signal damage_calculated(result: Dictionary)

func _ready() -> void:
	initialize()

func initialize() -> void:
	print("[DamageCalculator] Initialized")

## 计算伤害
## 计算伤害 (支持多种签名)
func calculate_damage(
	arg1,
	arg2 = null,
	arg3 = null,
	arg4 = null,
	arg5 = null,
	arg6 = null
) -> Dictionary:
	var base_damage: int = 0
	var attack_element = CardEnums.Element.NONE
	var defense_element = CardEnums.Element.NONE
	var defense: int = 0
	var crit_rate: float = 0.0
	var crit_damage: float = 1.5

	# 检测调用签名
	if arg1 == null or arg1 is Node:
		# 签名 A: (attacker, defender, base_damage, element)
		var defender = arg2
		base_damage = arg3 if arg3 is int else 0
		attack_element = arg4 if arg4 is int else CardEnums.Element.NONE
		
		# 从 defender 中提取属性
		if defender and defender is Node:
			if "element" in defender:
				defense_element = defender.element
			elif defender.has_method("get_element"):
				defense_element = defender.get_element()
			else:
				defense_element = defender.get("element") if defender.get("element") != null else CardEnums.Element.NONE
				
			if "defense" in defender:
				defense = defender.defense
			elif defender.has_method("get_defense"):
				defense = defender.get_defense()
			else:
				defense = defender.get("defense") if defender.get("defense") != null else 0
		
		# 从 CharacterAttributesManager 获取暴击属性
		var char_attr = GameManager.get_system("CharacterAttributesManager")
		if char_attr:
			crit_rate = char_attr.calculate_critical_rate() / 100.0 if char_attr.has_method("calculate_critical_rate") else 0.05
			crit_damage = char_attr.calculate_critical_damage() / 100.0 if char_attr.has_method("calculate_critical_damage") else 1.5
		else:
			crit_rate = 0.05
			crit_damage = 1.5
	else:
		# 签名 B: (base_damage, attack_element, defense_element, defense, crit_rate, crit_damage)
		base_damage = arg1 if arg1 is int else 0
		attack_element = arg2 if arg2 is int else CardEnums.Element.NONE
		defense_element = arg3 if arg3 is int else CardEnums.Element.NONE
		defense = arg4 if arg4 is int else 0
		crit_rate = arg5 if arg5 is float else 0.0
		crit_damage = arg6 if arg6 is float else 1.5

	# 基础伤害
	var damage = base_damage
	
	# 元素克制
	var element_multiplier = _get_element_multiplier(attack_element, defense_element)
	damage = int(damage * element_multiplier)
	
	# 暴击计算
	var is_critical = randf() < crit_rate
	if is_critical:
		damage = int(damage * crit_damage)
	
	# 防御减伤
	var defense_reduction = _calculate_defense_reduction(defense)
	damage = int(damage * (1.0 - defense_reduction))
	
	# 确保最小伤害
	damage = max(1, damage)
	
	var result = {
		"damage": damage,
		"final_damage": damage,
		"base_damage": base_damage,
		"element_multiplier": element_multiplier,
		"is_critical": is_critical,
		"defense_reduction": defense_reduction
	}
	
	damage_calculated.emit(result)
	return result

## 获取元素克制倍率
func _get_element_multiplier(attack: CardEnums.Element, defense: CardEnums.Element) -> float:
	# 元素克制关系
	match attack:
		CardEnums.Element.FIRE:
			if defense == CardEnums.Element.WIND:
				return 1.5
			elif defense == CardEnums.Element.WATER:
				return 0.75
		CardEnums.Element.WATER:
			if defense == CardEnums.Element.FIRE:
				return 1.5
			elif defense == CardEnums.Element.EARTH:
				return 0.75
		CardEnums.Element.WIND:
			if defense == CardEnums.Element.EARTH:
				return 1.5
			elif defense == CardEnums.Element.FIRE:
				return 0.75
		CardEnums.Element.EARTH:
			if defense == CardEnums.Element.LIGHTNING:
				return 1.5
			elif defense == CardEnums.Element.WIND:
				return 0.75
		CardEnums.Element.LIGHTNING:
			if defense == CardEnums.Element.WATER:
				return 1.5
			elif defense == CardEnums.Element.EARTH:
				return 0.75
	
	return 1.0

## 计算防御减伤
func _calculate_defense_reduction(defense: int) -> float:
	# 防御减伤公式
	return defense / (defense + 100.0)

## 计算治疗量
func calculate_heal(base_heal: int, heal_bonus: float) -> int:
	return int(base_heal * (1.0 + heal_bonus))

## 计算护甲
func calculate_armor(base_armor: int, armor_bonus: float) -> int:
	return int(base_armor * (1.0 + armor_bonus))
