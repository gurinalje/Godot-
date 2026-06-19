# summon_unit.gd
# 召唤物资源类
# 定义单个召唤物的所有属性

@tool
class_name SummonUnit
extends Resource

## 召唤物状态枚举
enum SummonState {
	ALIVE,    ## 存活
	DEAD,     ## 死亡
	BUFFED,   ## 增益状态
	DEBUFFED  ## 减益状态
}

## 召唤物ID
@export var summon_id: String = ""

## 召唤物名称
@export var summon_name: String = ""

## 召唤物描述
@export var description: String = ""

## 基础生命值
@export var base_health: int = 10

## 当前生命值
var current_health: int = 10

## 基础攻击力
@export var base_attack: int = 5

## 当前攻击力
var current_attack: int = 5

## 防御力
@export var defense: int = 0

## 速度
@export var speed: int = 10

## 元素类型
@export var element: CardEnums.Element = CardEnums.Element.NONE

## 召唤物状态
var state: SummonState = SummonState.ALIVE

## 召唤物图标
@export var icon: Texture2D = null

## 召唤物颜色
@export var summon_color: Color = Color.WHITE

## 持续回合数（-1表示永久）
@export var duration: int = -1

## 当前剩余回合
var remaining_turns: int = -1

## 状态效果管理器
var status_effects: Array[StatusEffect] = []

## 初始化
func _init() -> void:
	current_health = base_health
	current_attack = base_attack
	remaining_turns = duration

## 召唤物初始化
func initialize() -> void:
	current_health = base_health
	current_attack = base_attack
	remaining_turns = duration
	state = SummonState.ALIVE

## ==================== 战斗相关 ====================

## 受到伤害
func take_damage(damage: int) -> int:
	if state == SummonState.DEAD:
		return 0
	
	# 计算实际伤害（考虑防御）
	var actual_damage: int = maxi(1, damage - defense)
	current_health -= actual_damage
	
	# 检查是否死亡
	if current_health <= 0:
		current_health = 0
		state = SummonState.DEAD
	
	return actual_damage

## 治疗
func heal(amount: int) -> int:
	if state == SummonState.DEAD:
		return 0
	
	var actual_heal: int = mini(amount, base_health - current_health)
	current_health += actual_heal
	return actual_heal

## 造成伤害
func deal_damage() -> int:
	if state == SummonState.DEAD:
		return 0
	return current_attack

## 检查是否存活
func is_alive() -> bool:
	return state != SummonState.DEAD

## ==================== 状态管理 ====================

## 添加状态效果
func add_status_effect(effect: StatusEffect) -> void:
	if state == SummonState.DEAD:
		return
	
	# 检查是否已存在相同效果
	for existing_effect in status_effects:
		if existing_effect.effect_id == effect.effect_id:
			# 尝试叠加
			existing_effect.add_stack()
			existing_effect.duration = maxi(existing_effect.duration, effect.duration)
			return
	
	# 添加新效果
	status_effects.append(effect.clone())
	_update_state_from_effects()

## 移除状态效果
func remove_status_effect(effect_id: String) -> void:
	for i in range(status_effects.size()):
		if status_effects[i].effect_id == effect_id:
			status_effects.remove_at(i)
			_update_state_from_effects()
			return

## 处理回合结束
func process_turn_end() -> void:
	if state == SummonState.DEAD:
		return
	
	# 处理状态效果
	var effects_to_remove: Array[StatusEffect] = []
	for effect in status_effects:
		# 应用持续伤害/治疗
		if effect.effect_type == StatusEffect.EffectType.DOT:
			take_damage(effect.get_effective_value())
		elif effect.effect_type == StatusEffect.EffectType.HOT:
			heal(effect.get_effective_value())
		
		# 减少持续时间
		effect.on_turn_end()
		if effect.is_expired():
			effects_to_remove.append(effect)
	
	# 移除过期效果
	for effect in effects_to_remove:
		status_effects.erase(effect)
	
	# 减少剩余回合
	if remaining_turns > 0:
		remaining_turns -= 1
		if remaining_turns == 0:
			state = SummonState.DEAD
	
	_update_state_from_effects()

## 根据状态效果更新召唤物状态
func _update_state_from_effects() -> void:
	if state == SummonState.DEAD:
		return
	
	var has_buff: bool = false
	var has_debuff: bool = false
	
	for effect in status_effects:
		if effect.effect_type == StatusEffect.EffectType.BUFF:
			has_buff = true
		elif effect.effect_type == StatusEffect.EffectType.DEBUFF:
			has_debuff = true
	
	if has_buff and not has_debuff:
		state = SummonState.BUFFED
	elif has_debuff and not has_buff:
		state = SummonState.DEBUFFED
	else:
		state = SummonState.ALIVE

## ==================== 查询接口 ====================

## 获取生命值百分比
func get_health_percentage() -> float:
	if base_health == 0:
		return 0.0
	return float(current_health) / float(base_health) * 100.0

## 获取状态描述
func get_state_description() -> String:
	match state:
		SummonState.ALIVE:
			return "存活"
		SummonState.DEAD:
			return "死亡"
		SummonState.BUFFED:
			return "增益"
		SummonState.DEBUFFED:
			return "减益"
		_:
			return "未知"

## 获取信息字典
func get_info() -> Dictionary:
	return {
		"summon_id": summon_id,
		"summon_name": summon_name,
		"current_health": current_health,
		"base_health": base_health,
		"current_attack": current_attack,
		"base_attack": base_attack,
		"defense": defense,
		"element": element,
		"state": get_state_description(),
		"remaining_turns": remaining_turns,
		"status_effects": status_effects.size()
	}

## ==================== 序列化 ====================

## 序列化为字典
func to_dict() -> Dictionary:
	var effects_data: Array[Dictionary] = []
	for effect in status_effects:
		effects_data.append(effect.to_dict())
	
	return {
		"summon_id": summon_id,
		"summon_name": summon_name,
		"current_health": current_health,
		"base_health": base_health,
		"current_attack": current_attack,
		"base_attack": base_attack,
		"defense": defense,
		"speed": speed,
		"element": element,
		"state": state,
		"remaining_turns": remaining_turns,
		"status_effects": effects_data
	}

## 从字典反序列化
static func from_dict(data: Dictionary) -> SummonUnit:
	var unit: SummonUnit = SummonUnit.new()
	unit.summon_id = data.get("summon_id", "")
	unit.summon_name = data.get("summon_name", "")
	unit.current_health = data.get("current_health", 10)
	unit.base_health = data.get("base_health", 10)
	unit.current_attack = data.get("current_attack", 5)
	unit.base_attack = data.get("base_attack", 5)
	unit.defense = data.get("defense", 0)
	unit.speed = data.get("speed", 10)
	unit.element = data.get("element", CardEnums.Element.NONE)
	unit.state = data.get("state", SummonState.ALIVE)
	unit.remaining_turns = data.get("remaining_turns", -1)
	
	# 反序列化状态效果
	var effects_data: Array = data.get("status_effects", [])
	for effect_data in effects_data:
		if effect_data is Dictionary:
			unit.status_effects.append(StatusEffect.from_dict(effect_data))
	
	return unit
