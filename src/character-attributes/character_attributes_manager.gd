# character_attributes_manager.gd
# 角色属性管理器
# 管理角色的所有属性、等级和经验值

extends Node

## 信号：属性值改变
signal attribute_changed(attribute_type: CharacterAttribute.AttributeType, old_value: int, new_value: int)

## 信号：等级提升
signal level_up(new_level: int)

## 信号：经验值改变
signal experience_changed(current_exp: int, required_exp: int)

## 角色名称
var character_name: String = "Player"

## 当前等级
var level: int = 1

## 当前经验值
var experience: int = 0

## 属性集合
var attributes: Dictionary = {}  # AttributeType -> CharacterAttribute

## 每级获得的属性点
const POINTS_PER_LEVEL: int = 3

## 属性上限
const MAX_ATTRIBUTE_VALUE: int = 149

## 经验值需求公式系数
const EXP_BASE: int = 100
const EXP_EXPONENT: float = 1.5

## 初始化
func _ready() -> void:
	_initialize_attributes()

## 初始化所有属性
func _initialize_attributes() -> void:
	for attr_type in CharacterAttribute.AttributeType.values():
		attributes[attr_type] = CharacterAttribute.new(attr_type, 10)

## 获取属性对象
func get_attribute(attr_type: CharacterAttribute.AttributeType) -> CharacterAttribute:
	return attributes.get(attr_type)

## 获取属性最终值
func get_attribute_value(attr_type: CharacterAttribute.AttributeType) -> int:
	var attr: CharacterAttribute = get_attribute(attr_type)
	if attr:
		return attr.get_final_value()
	return 0

## 获取属性修正值
func get_attribute_modifier(attr_type: CharacterAttribute.AttributeType) -> int:
	var attr: CharacterAttribute = get_attribute(attr_type)
	if attr:
		return attr.get_modifier()
	return 0

## 设置属性基础值
func set_attribute_base(attr_type: CharacterAttribute.AttributeType, value: int) -> void:
	var attr: CharacterAttribute = get_attribute(attr_type)
	if attr:
		var old_value: int = attr.get_final_value()
		attr.base_value = clampi(value, 0, MAX_ATTRIBUTE_VALUE)
		var new_value: int = attr.get_final_value()
		if old_value != new_value:
			attribute_changed.emit(attr_type, old_value, new_value)

## 增加属性基础值
func increase_attribute_base(attr_type: CharacterAttribute.AttributeType, amount: int) -> void:
	var attr: CharacterAttribute = get_attribute(attr_type)
	if attr:
		set_attribute_base(attr_type, attr.base_value + amount)

## 设置装备加成
func set_equipment_bonus(attr_type: CharacterAttribute.AttributeType, bonus: int) -> void:
	var attr: CharacterAttribute = get_attribute(attr_type)
	if attr:
		var old_value: int = attr.get_final_value()
		attr.set_equipment_bonus(bonus)
		var new_value: int = attr.get_final_value()
		if old_value != new_value:
			attribute_changed.emit(attr_type, old_value, new_value)

## 设置Buff加成
func set_buff_bonus(attr_type: CharacterAttribute.AttributeType, bonus: int) -> void:
	var attr: CharacterAttribute = get_attribute(attr_type)
	if attr:
		var old_value: int = attr.get_final_value()
		attr.set_buff_bonus(bonus)
		var new_value: int = attr.get_final_value()
		if old_value != new_value:
			attribute_changed.emit(attr_type, old_value, new_value)

## 重置所有Buff加成
func reset_all_buffs() -> void:
	for attr in attributes.values():
		attr.set_buff_bonus(0)

## ==================== 等级和经验值系统 ====================

## 计算升级所需经验值
func get_required_experience(target_level: int = -1) -> int:
	if target_level < 0:
		target_level = level + 1
	return int(EXP_BASE * pow(target_level, EXP_EXPONENT))

## 获取当前等级进度
func get_level_progress() -> Dictionary:
	var required: int = get_required_experience(level + 1)
	return {
		"current": experience,
		"required": required,
		"percentage": float(experience) / float(required) * 100.0 if required > 0 else 0.0
	}

## 添加经验值
func add_experience(amount: int) -> void:
	if amount <= 0:
		return
	
	experience += amount
	experience_changed.emit(experience, get_required_experience(level + 1))
	
	# 检查是否可以升级
	while experience >= get_required_experience(level + 1):
		_level_up()

## 升级
func _level_up() -> void:
	var required_exp: int = get_required_experience(level + 1)
	experience -= required_exp
	level += 1
	
	# 分配属性点
	_distribute_attribute_points()
	
	level_up.emit(level)
	experience_changed.emit(experience, get_required_experience(level + 1))

## 分配属性点（自动分配或等待玩家手动分配）
func _distribute_attribute_points() -> void:
	# 这里可以实现自动分配逻辑
	# 或者发送信号让UI层处理
	pass

## 手动分配属性点
func distribute_point(attr_type: CharacterAttribute.AttributeType) -> bool:
	# 检查是否有可用属性点
	var available_points: int = _get_available_points()
	if available_points <= 0:
		return false
	
	# 增加属性
	increase_attribute_base(attr_type, 1)
	return true

## 获取可用属性点数
func _get_available_points() -> int:
	var total_points: int = level * POINTS_PER_LEVEL
	var used_points: int = 0
	
	for attr in attributes.values():
		used_points += attr.base_value - 10  # 初始值为10
	
	return total_points - used_points

## ==================== 属性计算工具 ====================

## 计算最大生命值
## 公式：基础生命值 + 体质 * 10 + 等级 * 5
func calculate_max_health() -> int:
	var base_health: int = 100
	var constitution: int = get_attribute_value(CharacterAttribute.AttributeType.CONSTITUTION)
	return base_health + constitution * 10 + level * 5

## 计算物理攻击力
## 公式：基础攻击 + 力量 * 2 + 武器加成
func calculate_physical_attack(weapon_bonus: int = 0) -> int:
	var base_attack: int = 10
	var strength: int = get_attribute_value(CharacterAttribute.AttributeType.STRENGTH)
	return base_attack + strength * 2 + weapon_bonus

## 计算魔法攻击力
## 公式：基础攻击 + 智力 * 2 + 法杖加成
func calculate_magic_attack(staff_bonus: int = 0) -> int:
	var base_attack: int = 10
	var intelligence: int = get_attribute_value(CharacterAttribute.AttributeType.INTELLIGENCE)
	return base_attack + intelligence * 2 + staff_bonus

## 计算暴击率
## 公式：基础暴击率 + 敏捷 * 0.5%
func calculate_critical_rate() -> float:
	var base_crit: float = 5.0
	var dexterity: int = get_attribute_value(CharacterAttribute.AttributeType.DEXTERITY)
	return base_crit + dexterity * 0.5

## 计算暴击伤害
## 公式：150% + 敏捷 * 1%
func calculate_critical_damage() -> float:
	var base_crit_damage: float = 150.0
	var dexterity: int = get_attribute_value(CharacterAttribute.AttributeType.DEXTERITY)
	return base_crit_damage + dexterity * 1.0

## 计算闪避率
## 公式：基础闪避率 + 敏捷 * 0.3%
func calculate_dodge_rate() -> float:
	var base_dodge: float = 3.0
	var dexterity: int = get_attribute_value(CharacterAttribute.AttributeType.DEXTERITY)
	return base_dodge + dexterity * 0.3

## 计算物理防御
## 公式：基础防御 + 体质 * 1 + 护甲加成
func calculate_physical_defense(armor_bonus: int = 0) -> int:
	var base_defense: int = 5
	var constitution: int = get_attribute_value(CharacterAttribute.AttributeType.CONSTITUTION)
	return base_defense + constitution + armor_bonus

## 计算命中率
## 公式：基础命中率 + 感知 * 0.5%
func calculate_hit_rate() -> float:
	var base_hit: float = 90.0
	var perception: int = get_attribute_value(CharacterAttribute.AttributeType.PERCEPTION)
	return base_hit + perception * 0.5

## ==================== 序列化 ====================

## 序列化为字典
func to_dict() -> Dictionary:
	var attrs_data: Dictionary = {}
	for attr_type in attributes:
		attrs_data[attr_type] = attributes[attr_type].to_dict()
	
	return {
		"character_name": character_name,
		"level": level,
		"experience": experience,
		"attributes": attrs_data
	}

## 从字典反序列化
static func from_dict(data: Dictionary) -> Node:
	# 这里需要返回一个CharacterAttributesManager实例
	# 由于静态方法限制，实际使用时需要在调用处处理
	return null

## 加载存档数据
func load_from_dict(data: Dictionary) -> void:
	character_name = data.get("character_name", "玩家")
	level = data.get("level", 1)
	experience = data.get("experience", 0)
	
	var attrs_data: Dictionary = data.get("attributes", {})
	for attr_type in attrs_data:
		if attributes.has(attr_type):
			attributes[attr_type] = CharacterAttribute.from_dict(attrs_data[attr_type])
