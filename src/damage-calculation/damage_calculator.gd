## 伤害计算器
## 处理所有伤害计算逻辑
## 所有配置值从 GameConfig 读取，不再硬编码
class_name DamageCalculator
extends Node

# 信号
signal damage_calculated(result: Dictionary)

# 依赖注入
@export var game_config: GameConfig
@export var character_attributes_manager: Node

func _ready() -> void:
	initialize()

func initialize() -> void:
	# 如果没有设置game_config，尝试从GameManager获取
	if not game_config:
		_load_default_config()
	print("[DamageCalculator] Initialized")

## 加载默认配置
func _load_default_config() -> void:
	# 创建默认的GameConfig实例
	game_config = GameConfig.new()
	# 如果有GameManager，尝试获取CharacterAttributesManager
	if not character_attributes_manager and GameManager.has_system("CharacterAttributesManager"):
		character_attributes_manager = GameManager.get_system("CharacterAttributesManager")

## 设置GameConfig依赖
func set_game_config(config: GameConfig) -> void:
	game_config = config

## 设置CharacterAttributesManager依赖
func set_character_attributes_manager(manager: Node) -> void:
	character_attributes_manager = manager

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
	# 解析参数
	var params: Dictionary = _parse_arguments(arg1, arg2, arg3, arg4, arg5, arg6)

	# 提取属性
	var base_damage: int = params.base_damage
	var attack_element: CardEnums.Element = params.attack_element
	var defense_element: CardEnums.Element = params.defense_element
	var defense: int = params.defense
	var crit_rate: float = params.crit_rate
	var crit_damage: float = params.crit_damage

	# 计算基础伤害
	var damage: int = _calculate_base_damage(base_damage)

	# 应用元素克制
	var element_multiplier: float = _apply_element_modifier(attack_element, defense_element)
	damage = int(damage * element_multiplier)

	# 应用暴击
	var is_critical: bool = _apply_critical_hit(crit_rate)
	if is_critical:
		damage = int(damage * crit_damage)

	# 应用防御减伤
	var defense_reduction: float = _apply_defense_reduction(defense)
	damage = int(damage * (1.0 - defense_reduction))

	# 确保最小伤害
	damage = max(1, damage)

	var result: Dictionary = {
		"damage": damage,
		"final_damage": damage,
		"base_damage": base_damage,
		"element_multiplier": element_multiplier,
		"is_critical": is_critical,
		"defense_reduction": defense_reduction
	}

	damage_calculated.emit(result)
	return result

## 解析参数
func _parse_arguments(
	arg1,
	arg2,
	arg3,
	arg4,
	arg5,
	arg6
) -> Dictionary:
	var base_damage: int = 0
	var attack_element: CardEnums.Element = CardEnums.Element.NONE
	var defense_element: CardEnums.Element = CardEnums.Element.NONE
	var defense: int = 0
	var crit_rate: float = 0.0
	var crit_damage: float = 1.5

	# 检测调用签名
	if arg1 == null or arg1 is Node:
		# 签名 A: (attacker, defender, base_damage, element)
		var defender: Node = arg2
		base_damage = arg3 if arg3 is int else 0
		attack_element = arg4 if arg4 is int else CardEnums.Element.NONE

		# 从 defender 中提取属性
		if defender and defender is Node:
			defense_element = _extract_defense_element(defender)
			defense = _extract_defense(defender)

		# 从 CharacterAttributesManager 获取暴击属性
		var crit_stats: Dictionary = _extract_critical_stats()
		crit_rate = crit_stats.crit_rate
		crit_damage = crit_stats.crit_damage
	else:
		# 签名 B: (base_damage, attack_element, defense_element, defense, crit_rate, crit_damage)
		base_damage = arg1 if arg1 is int else 0
		attack_element = arg2 if arg2 is int else CardEnums.Element.NONE
		defense_element = arg3 if arg3 is int else CardEnums.Element.NONE
		defense = arg4 if arg4 is int else 0
		crit_rate = arg5 if arg5 is float else 0.0
		crit_damage = arg6 if arg6 is float else 1.5

	return {
		"base_damage": base_damage,
		"attack_element": attack_element,
		"defense_element": defense_element,
		"defense": defense,
		"crit_rate": crit_rate,
		"crit_damage": crit_damage
	}

## 提取防御元素
func _extract_defense_element(defender: Node) -> CardEnums.Element:
	if "element" in defender:
		return defender.element
	if defender.has_method("get_element"):
		return defender.get_element()
	var element = defender.get("element")
	return element if element != null else CardEnums.Element.NONE

## 提取防御力
func _extract_defense(defender: Node) -> int:
	if "defense" in defender:
		return defender.defense
	if defender.has_method("get_defense"):
		return defender.get_defense()
	var def_value = defender.get("defense")
	return def_value if def_value != null else 0

## 提取暴击属性
func _extract_critical_stats() -> Dictionary:
	# 使用 GameConfig 的默认值（已在 _load_default_config 中确保存在）
	var crit_rate: float = game_config.default_crit_rate
	var crit_damage: float = game_config.default_crit_damage

	if character_attributes_manager:
		if character_attributes_manager.has_method("calculate_critical_rate"):
			crit_rate = character_attributes_manager.calculate_critical_rate() / 100.0
		if character_attributes_manager.has_method("calculate_critical_damage"):
			crit_damage = character_attributes_manager.calculate_critical_damage() / 100.0

	return {
		"crit_rate": crit_rate,
		"crit_damage": crit_damage
	}

## 计算基础伤害
func _calculate_base_damage(base_damage: int) -> int:
	return base_damage

## 应用元素克制
## 统一使用 CardEnums.get_element_modifier() 作为单一数据源
func _apply_element_modifier(
	attack_element: CardEnums.Element,
	defense_element: CardEnums.Element
) -> float:
	return CardEnums.get_element_modifier(attack_element, defense_element, game_config)

## 应用暴击
func _apply_critical_hit(crit_rate: float) -> bool:
	return randf() < crit_rate

## 应用防御减伤
func _apply_defense_reduction(defense: int) -> float:
	# 使用 GameConfig 的防御常数（已在 _load_default_config 中确保存在）
	var defense_constant: float = game_config.defense_constant
	return defense / (defense + defense_constant)

## 计算治疗量
func calculate_heal(base_heal: int, heal_bonus: float) -> int:
	return int(base_heal * (1.0 + heal_bonus))

## 计算护甲
func calculate_armor(base_armor: int, armor_bonus: float) -> int:
	return int(base_armor * (1.0 + armor_bonus))
