# summon_manager.gd
# 召唤物管理器
# 管理所有召唤物的生命周期
class_name SummonManager
extends Node

## 信号：召唤物被召唤
signal unit_summoned(unit: SummonUnit)

## 信号：召唤物死亡
signal unit_died(unit: SummonUnit)

## 信号：召唤物受伤
signal unit_damaged(unit: SummonUnit, damage: int)

## 信号：召唤物治疗
signal unit_healed(unit: SummonUnit, amount: int)

## 信号：回合结束处理完成
signal turn_processed()

## 所有召唤物
var summoned_units: Array[SummonUnit] = []

## 最大召唤物数量
const MAX_SUMMONS: int = 5

## 初始化
func _ready() -> void:
	pass

## ==================== 召唤管理 ====================

## 召唤新单位
func summon_unit(unit_data: SummonUnit) -> bool:
	# 检查召唤物数量限制
	if summoned_units.size() >= MAX_SUMMONS:
		push_warning("SummonManager: 已达最大召唤物数量 (%d)" % MAX_SUMMONS)
		return false
	
	# 初始化召唤物
	unit_data.initialize()
	summoned_units.append(unit_data)
	unit_summoned.emit(unit_data)
	return true

## 移除召唤物
func remove_unit(summon_id: String) -> bool:
	for i in range(summoned_units.size()):
		if summoned_units[i].summon_id == summon_id:
			var unit: SummonUnit = summoned_units[i]
			summoned_units.remove_at(i)
			if unit.is_alive():
				unit.state = SummonUnit.SummonState.DEAD
			return true
	return false

## 获取召唤物
func get_unit(summon_id: String) -> SummonUnit:
	for unit in summoned_units:
		if unit.summon_id == summon_id:
			return unit
	return null

## 获取所有存活的召唤物
func get_alive_units() -> Array[SummonUnit]:
	var alive: Array[SummonUnit] = []
	for unit in summoned_units:
		if unit.is_alive():
			alive.append(unit)
	return alive

## 获取所有死亡的召唤物
func get_dead_units() -> Array[SummonUnit]:
	var dead: Array[SummonUnit] = []
	for unit in summoned_units:
		if not unit.is_alive():
			dead.append(unit)
	return dead

## 清除所有死亡的召唤物
func clear_dead_units() -> void:
	summoned_units = get_alive_units()

## ==================== 战斗相关 ====================

## 对召唤物造成伤害
func damage_unit(summon_id: String, damage: int) -> int:
	var unit: SummonUnit = get_unit(summon_id)
	if unit == null or not unit.is_alive():
		return 0
	
	var actual_damage: int = unit.take_damage(damage)
	unit_damaged.emit(unit, actual_damage)
	
	# 检查是否死亡
	if not unit.is_alive():
		unit_died.emit(unit)
	
	return actual_damage

## 治疗召唤物
func heal_unit(summon_id: String, amount: int) -> int:
	var unit: SummonUnit = get_unit(summon_id)
	if unit == null or not unit.is_alive():
		return 0
	
	var actual_heal: int = unit.heal(amount)
	unit_healed.emit(unit, actual_heal)
	return actual_heal

## 对所有召唤物造成伤害
func damage_all_units(damage: int) -> int:
	var total_damage: int = 0
	for unit in get_alive_units():
		var actual_damage: int = unit.take_damage(damage)
		total_damage += actual_damage
		unit_damaged.emit(unit, actual_damage)
		
		if not unit.is_alive():
			unit_died.emit(unit)
	
	return total_damage

## 治疗所有召唤物
func heal_all_units(amount: int) -> int:
	var total_heal: int = 0
	for unit in get_alive_units():
		var actual_heal: int = unit.heal(amount)
		total_heal += actual_heal
		unit_healed.emit(unit, actual_heal)
	
	return total_heal

## ==================== 回合处理 ====================

## 处理回合结束
func process_turn_end() -> void:
	# 处理所有召唤物
	for unit in summoned_units:
		if unit.is_alive():
			unit.process_turn_end()
			
			# 检查是否死亡
			if not unit.is_alive():
				unit_died.emit(unit)
	
	# 清除死亡单位
	clear_dead_units()
	
	turn_processed.emit()

## ==================== 查询接口 ====================

## 获取召唤物数量
func get_unit_count() -> int:
	return summoned_units.size()

## 获取存活召唤物数量
func get_alive_count() -> int:
	return get_alive_units().size()

## 检查是否可以召唤更多单位
func can_summon_more() -> bool:
	return summoned_units.size() < MAX_SUMMONS

## 获取所有召唤物信息
func get_all_units_info() -> Array[Dictionary]:
	var info: Array[Dictionary] = []
	for unit in summoned_units:
		info.append(unit.get_info())
	return info

## 获取总攻击力
func get_total_attack() -> int:
	var total: int = 0
	for unit in get_alive_units():
		total += unit.deal_damage()
	return total

## 获取总生命值
func get_total_health() -> int:
	var total: int = 0
	for unit in get_alive_units():
		total += unit.current_health
	return total

## ==================== 序列化 ====================

## 序列化为字典
func to_dict() -> Dictionary:
	var units_data: Array[Dictionary] = []
	for unit in summoned_units:
		units_data.append(unit.to_dict())
	
	return {
		"summoned_units": units_data
	}

## 从字典反序列化
func load_from_dict(data: Dictionary) -> void:
	summoned_units.clear()
	
	var units_data: Array = data.get("summoned_units", [])
	for unit_data in units_data:
		if unit_data is Dictionary:
			var unit: SummonUnit = SummonUnit.from_dict(unit_data)
			summoned_units.append(unit)
