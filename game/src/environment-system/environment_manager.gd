# environment_manager.gd
# 环境管理器
# 管理战场环境的切换和效果应用
class_name EnvironmentManager
extends Node

## 信号：环境改变
signal environment_changed(old_env: EnvironmentEffect, new_env: EnvironmentEffect)

## 信号：环境效果应用
signal environment_effect_applied(effect: Dictionary, target: Node)

## 信号：环境结束
signal environment_ended(environment: EnvironmentEffect)

## 当前环境
var current_environment: EnvironmentEffect = null

## 环境历史
var environment_history: Array[String] = []

## 初始化
func _ready() -> void:
	pass

## ==================== 环境管理 ====================

## 设置新环境
func set_environment(environment: EnvironmentEffect) -> void:
	var old_env: EnvironmentEffect = current_environment
	
	# 结束旧环境
	if old_env != null:
		environment_history.append(old_env.environment_id)
	
	# 设置新环境
	current_environment = environment
	current_environment.activate()
	
	environment_changed.emit(old_env, current_environment)

## 清除当前环境
func clear_environment() -> void:
	if current_environment != null:
		environment_history.append(current_environment.environment_id)
		var old_env: EnvironmentEffect = current_environment
		current_environment = null
		environment_ended.emit(old_env)

## 获取当前环境
func get_current_environment() -> EnvironmentEffect:
	return current_environment

## 检查是否有激活的环境
func has_active_environment() -> bool:
	return current_environment != null and current_environment.is_active()

## ==================== 效果应用 ====================

## 应用环境效果到单位
func apply_environment_effects(ally_units: Array[Node], enemy_units: Array[Node]) -> void:
	if not has_active_environment():
		return
	
	# 应用友方效果
	for unit in ally_units:
		for effect in current_environment.get_ally_effects():
			_apply_effect_to_unit(effect, unit, true)
	
	# 应用敌方效果
	for unit in enemy_units:
		for effect in current_environment.get_enemy_effects():
			_apply_effect_to_unit(effect, unit, false)

## 应用单个效果到单位
func _apply_effect_to_unit(effect: Dictionary, unit: Node, is_ally: bool) -> void:
	var effect_name: String = effect.get("name", "未知")
	var effect_value: int = effect.get("value", 0)
	var effect_type: String = effect.get("type", "buff")
	
	# 根据效果类型应用
	match effect_type:
		"damage":
			if unit.has_method("take_damage"):
				unit.take_damage(effect_value)
				environment_effect_applied.emit(effect, unit)
		"heal":
			if unit.has_method("heal"):
				unit.heal(effect_value)
				environment_effect_applied.emit(effect, unit)
		"buff":
			if unit.has_method("add_status_effect"):
				var status_effect: StatusEffect = StatusEffect.new()
				status_effect.effect_id = "env_" + effect_name
				status_effect.effect_name = effect_name
				status_effect.effect_type = StatusEffect.EffectType.BUFF
				status_effect.value = effect_value
				status_effect.duration = current_environment.remaining_turns
				unit.add_status_effect(status_effect)
				environment_effect_applied.emit(effect, unit)
		"debuff":
			if unit.has_method("add_status_effect"):
				var status_effect: StatusEffect = StatusEffect.new()
				status_effect.effect_id = "env_" + effect_name
				status_effect.effect_name = effect_name
				status_effect.effect_type = StatusEffect.EffectType.DEBUFF
				status_effect.value = effect_value
				status_effect.duration = current_environment.remaining_turns
				unit.add_status_effect(status_effect)
				environment_effect_applied.emit(effect, unit)

## ==================== 回合处理 ====================

## 处理回合结束
func process_turn_end() -> void:
	if not has_active_environment():
		return
	
	# 减少环境持续时间
	current_environment.process_turn_end()
	
	# 检查环境是否结束
	if not current_environment.is_active():
		environment_ended.emit(current_environment)
		environment_history.append(current_environment.environment_id)
		current_environment = null

## ==================== 查询接口 ====================

## 获取环境效果预览
func get_environment_preview() -> Dictionary:
	if not has_active_environment():
		return {}
	
	return {
		"environment_name": current_environment.environment_name,
		"environment_type": current_environment.get_type_name(),
		"remaining_turns": current_environment.remaining_turns,
		"ally_effects": current_environment.get_ally_effects(),
		"enemy_effects": current_environment.get_enemy_effects(),
		"description": current_environment.get_description()
	}

## 获取环境历史
func get_environment_history() -> Array[String]:
	return environment_history

## ==================== 序列化 ====================

## 序列化为字典
func to_dict() -> Dictionary:
	var data: Dictionary = {
		"environment_history": environment_history
	}
	
	if current_environment != null:
		data["current_environment"] = current_environment.to_dict()
	
	return data

## 从字典反序列化
func load_from_dict(data: Dictionary) -> void:
	environment_history = data.get("environment_history", [])
	
	if data.has("current_environment"):
		current_environment = EnvironmentEffect.from_dict(data["current_environment"])
	else:
		current_environment = null
