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

## 计算伤害（从数值参数直接调用）
## 明确的类型签名，用于已知所有数值的场景
func calculate_damage_from_stats(
	base_damage: int,
	attack_element: CardEnums.Element,
	defense_element: CardEnums.Element,
	defense: int,
	crit_rate: float,
	crit_damage: float
) -> Dictionary:
	return _compute_damage(base_damage, attack_element, defense_element, defense, crit_rate, crit_damage)

## 计算伤害（从节点提取属性）
## 从攻击者/防御者节点自动提取属性，用于 Node-based 调用
func calculate_damage_from_nodes(
	attacker: Node,
	defender: Node,
	base_damage: int,
	element: CardEnums.Element
) -> Dictionary:
	var defense_element: CardEnums.Element = CardEnums.Element.NONE
	var defense: int = 0

	if defender and defender is Node:
		defense_element = _extract_defense_element(defender)
		defense = _extract_defense(defender)

	var crit_stats: Dictionary = _extract_critical_stats()

	return _compute_damage(
		base_damage,
		element,
		defense_element,
		defense,
		crit_stats.crit_rate,
		crit_stats.crit_damage
	)

## 计算伤害（已弃用，保留向后兼容）
## @deprecated 使用 calculate_damage_from_stats() 或 calculate_damage_from_nodes()
func calculate_damage(
	arg1,
	arg2 = null,
	arg3 = null,
	arg4 = null,
	arg5 = null,
	arg6 = null
) -> Dictionary:
	push_warning("DamageCalculator.calculate_damage() is deprecated. Use calculate_damage_from_stats() or calculate_damage_from_nodes().")
	if arg1 == null or arg1 is Node:
		var defender: Node = arg2
		var bd: int = arg3 if arg3 is int else 0
		var el: CardEnums.Element = arg4 if arg4 is int else CardEnums.Element.NONE
		return calculate_damage_from_nodes(arg1, defender, bd, el)
	else:
		var bd: int = arg1 if arg1 is int else 0
		var ae: CardEnums.Element = arg2 if arg2 is int else CardEnums.Element.NONE
		var de: CardEnums.Element = arg3 if arg3 is int else CardEnums.Element.NONE
		var df: int = arg4 if arg4 is int else 0
		var cr: float = arg5 if arg5 is float else 0.0
		var cd: float = arg6 if arg6 is float else 1.5
		return calculate_damage_from_stats(bd, ae, de, df, cr, cd)

## 内部伤害计算核心（所有公开方法最终调用此方法）
func _compute_damage(
	base_damage: int,
	attack_element: CardEnums.Element,
	defense_element: CardEnums.Element,
	defense: int,
	crit_rate: float,
	crit_damage: float
) -> Dictionary:
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
