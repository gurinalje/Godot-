# status_effect_manager.gd
# 状态效果管理器
# 管理实体上的所有状态效果
class_name StatusEffectManager
extends Node

## 信号：状态效果被施加
signal effect_applied(effect: StatusEffect, target: Node)

## 信号：状态效果被移除
signal effect_removed(effect: StatusEffect, target: Node)

## 信号：状态效果更新（叠加或持续时间变化）
signal effect_updated(effect: StatusEffect, target: Node)

## 信号：回合结束处理完成
signal turn_processed(effects_count: int)

## 当前实体上的所有状态效果
var active_effects: Array[StatusEffect] = []

## 效果字典（按ID索引，便于快速查找）
var effects_by_id: Dictionary = {}  # effect_id -> Array[StatusEffect]

## 初始化
func _ready() -> void:
	pass

## ==================== 效果管理 ====================

## 施加状态效果
func apply_effect(effect: StatusEffect, target: Node) -> bool:
	if effect == null:
		push_warning("StatusEffectManager: 尝试施加空效果")
		return false
	
	# 检查是否已存在相同效果
	var existing_effect: StatusEffect = _find_effect_by_id(effect.effect_id)
	
	if existing_effect:
		# 尝试叠加
		if existing_effect.add_stack():
			# 刷新持续时间
			existing_effect.duration = maxi(existing_effect.duration, effect.duration)
			effect_updated.emit(existing_effect, target)
			return true
		else:
			# 已达最大叠加层数，刷新持续时间
			existing_effect.duration = maxi(existing_effect.duration, effect.duration)
			effect_updated.emit(existing_effect, target)
			return false
	else:
		# 施加新效果
		var new_effect: StatusEffect = effect.clone()
		active_effects.append(new_effect)
		
		# 更新索引
		if not effects_by_id.has(new_effect.effect_id):
			effects_by_id[new_effect.effect_id] = []
		effects_by_id[new_effect.effect_id].append(new_effect)
		
		effect_applied.emit(new_effect, target)
		return true

## 移除状态效果
func remove_effect(effect_id: String, target: Node) -> bool:
	var effect: StatusEffect = _find_effect_by_id(effect_id)
	if effect == null:
		return false
	
	_remove_effect_from_list(effect, target)
	return true

## 移除所有负面效果（驱散）
func dispel_all_negative(target: Node) -> int:
	var removed_count: int = 0
	var effects_to_remove: Array[StatusEffect] = []
	
	for effect in active_effects:
		if effect.is_negative and effect.can_be_dispeled:
			effects_to_remove.append(effect)
	
	for effect in effects_to_remove:
		_remove_effect_from_list(effect, target)
		removed_count += 1
	
	return removed_count

## 移除所有效果
func remove_all_effects(target: Node) -> void:
	var effects_to_remove: Array[StatusEffect] = active_effects.duplicate()
	for effect in effects_to_remove:
		_remove_effect_from_list(effect, target)

## ==================== 回合处理 ====================

## 处理回合结束
func process_turn_end(target: Node) -> void:
	var effects_to_remove: Array[StatusEffect] = []
	
	# 处理所有效果
	for effect in active_effects:
		# 应用持续伤害/治疗
		_apply_sustained_effect(effect, target)
		
		# 减少持续时间
		effect.on_turn_end()
		
		# 检查是否过期
		if effect.is_expired():
			effects_to_remove.append(effect)
	
	# 移除过期效果
	for effect in effects_to_remove:
		_remove_effect_from_list(effect, target)
	
	turn_processed.emit(effects_to_remove.size())

## 应用持续效果
func _apply_sustained_effect(effect: StatusEffect, target: Node) -> void:
	match effect.effect_type:
		StatusEffect.EffectType.DOT:
			# 持续伤害
			if target.has_method("take_damage"):
				target.take_damage(effect.get_effective_value())
		StatusEffect.EffectType.HOT:
			# 持续治疗
			if target.has_method("heal"):
				target.heal(effect.get_effective_value())
		StatusEffect.EffectType.SHIELD:
			# 护盾不在此处理，由外部系统处理
			pass

## ==================== 查询接口 ====================

## 检查是否有指定效果
func has_effect(effect_id: String) -> bool:
	return effects_by_id.has(effect_id) and not effects_by_id[effect_id].is_empty()

## 获取指定效果
func get_effect(effect_id: String) -> StatusEffect:
	return _find_effect_by_id(effect_id)

## 获取所有增益效果
func get_all_buffs() -> Array[StatusEffect]:
	var buffs: Array[StatusEffect] = []
	for effect in active_effects:
		if effect.effect_type == StatusEffect.EffectType.BUFF:
			buffs.append(effect)
	return buffs

## 获取所有减益效果
func get_all_debuffs() -> Array[StatusEffect]:
	var debuffs: Array[StatusEffect] = []
	for effect in active_effects:
		if effect.effect_type == StatusEffect.EffectType.DEBUFF:
			debuffs.append(effect)
	return debuffs

## 获取所有负面效果
func get_all_negative_effects() -> Array[StatusEffect]:
	var negative_effects: Array[StatusEffect] = []
	for effect in active_effects:
		if effect.is_negative:
			negative_effects.append(effect)
	return negative_effects

## 获取效果总加成值
func get_total_buff_value(effect_type: StatusEffect.EffectType) -> int:
	var total: int = 0
	for effect in active_effects:
		if effect.effect_type == effect_type:
			total += effect.get_effective_value()
	return total

## 获取活动效果数量
func get_effect_count() -> int:
	return active_effects.size()

## ==================== 内部方法 ====================

## 根据ID查找效果
func _find_effect_by_id(effect_id: String) -> StatusEffect:
	if effects_by_id.has(effect_id):
		var effects: Array = effects_by_id[effect_id]
		if not effects.is_empty():
			return effects[0]
	return null

## 从列表中移除效果
func _remove_effect_from_list(effect: StatusEffect, target: Node) -> void:
	# 从主列表移除
	active_effects.erase(effect)
	
	# 从索引中移除
	if effects_by_id.has(effect.effect_id):
		effects_by_id[effect.effect_id].erase(effect)
		if effects_by_id[effect.effect_id].is_empty():
			effects_by_id.erase(effect.effect_id)
	
	effect_removed.emit(effect, target)

## ==================== 序列化 ====================

## 序列化为字典
func to_dict() -> Dictionary:
	var effects_data: Array[Dictionary] = []
	for effect in active_effects:
		effects_data.append(effect.to_dict())
	
	return {
		"effects": effects_data
	}

## 从字典反序列化
func load_from_dict(data: Dictionary) -> void:
	clear_all_effects()
	
	var effects_data: Array = data.get("effects", [])
	for effect_data in effects_data:
		if effect_data is Dictionary:
			var effect: StatusEffect = StatusEffect.from_dict(effect_data)
			active_effects.append(effect)
			
			if not effects_by_id.has(effect.effect_id):
				effects_by_id[effect.effect_id] = []
			effects_by_id[effect.effect_id].append(effect)

## 清除所有效果（用于重置）
func clear_all_effects() -> void:
	active_effects.clear()
	effects_by_id.clear()
