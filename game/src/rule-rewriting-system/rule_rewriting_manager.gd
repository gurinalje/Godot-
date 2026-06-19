## 规则改写管理器
## 管理玩家选择对战斗规则的永久改变

class_name RuleRewritingManager
extends Node

# 规则改写类型
enum RuleType {
	CARD_EFFECT,      # 卡牌效果
	BATTLE_RULE,      # 战斗规则
	SUMMON_RULE,      # 召唤物规则
	ENVIRONMENT_RULE  # 环境规则
}

# 已激活的规则改写
var active_rules: Dictionary = {}

# 规则改写上限
const MAX_ACTIVE_RULES = 10

# 信号
signal rule_activated(rule_id: String)
signal rule_deactivated(rule_id: String)
signal rule_effect_applied(rule_id: String, effect: String)

func _ready() -> void:
	initialize()

func initialize() -> void:
	print("[RuleRewritingManager] Initialized")
	_load_default_rules()

## 加载默认规则
func _load_default_rules() -> void:
	# TODO: 从文件加载规则数据
	pass

## 激活规则
func activate_rule(rule_id: String, rule_data: Dictionary) -> bool:
	if active_rules.size() >= MAX_ACTIVE_RULES:
		push_warning("[RuleRewritingManager] Max active rules reached")
		return false
	
	if active_rules.has(rule_id):
		push_warning("[RuleRewritingManager] Rule already active: " + rule_id)
		return false
	
	active_rules[rule_id] = rule_data
	rule_activated.emit(rule_id)
	print("[RuleRewritingManager] Activated rule: ", rule_id)
	return true

## 停用规则
func deactivate_rule(rule_id: String) -> bool:
	if not active_rules.has(rule_id):
		push_warning("[RuleRewritingManager] Rule not active: " + rule_id)
		return false
	
	active_rules.erase(rule_id)
	rule_deactivated.emit(rule_id)
	print("[RuleRewritingManager] Deactivated rule: ", rule_id)
	return true

## 检查规则是否激活
func is_rule_active(rule_id: String) -> bool:
	return active_rules.has(rule_id)

## 获取规则数据
func get_rule_data(rule_id: String) -> Dictionary:
	return active_rules.get(rule_id, {})

## 获取所有激活规则
func get_active_rules() -> Dictionary:
	return active_rules.duplicate()

## 应用规则效果
func apply_rule_effects(context: Dictionary) -> Dictionary:
	var modified_context = context.duplicate()
	
	for rule_id in active_rules:
		var rule = active_rules[rule_id]
		var effects = rule.get("effects", {})
		
		for effect_type in effects:
			var effect_value = effects[effect_type]
			_apply_single_effect(modified_context, effect_type, effect_value)
			rule_effect_applied.emit(rule_id, effect_type)
	
	return modified_context

## 应用单个效果
func _apply_single_effect(context: Dictionary, effect_type: String, value: Variant) -> void:
	match effect_type:
		"damage_bonus":
			context["damage"] = context.get("damage", 0) + value
		"defense_bonus":
			context["defense"] = context.get("defense", 0) + value
		"heal_bonus":
			context["heal"] = context.get("heal", 0) + value
		"draw_bonus":
			context["draw"] = context.get("draw", 0) + value
		"energy_bonus":
			context["energy"] = context.get("energy", 0) + value
		"critical_bonus":
			context["critical_rate"] = context.get("critical_rate", 0.0) + value

## 获取规则类型名称
func get_rule_type_name(rule_type: RuleType) -> String:
	match rule_type:
		RuleType.CARD_EFFECT:
			return "Card Effect"
		RuleType.BATTLE_RULE:
			return "Battle Rule"
		RuleType.SUMMON_RULE:
			return "Summon Rule"
		RuleType.ENVIRONMENT_RULE:
			return "Environment Rule"
		_:
			return "Unknown"

## 重置所有规则
func reset_rules() -> void:
	active_rules.clear()
	print("[RuleRewritingManager] All rules reset")
