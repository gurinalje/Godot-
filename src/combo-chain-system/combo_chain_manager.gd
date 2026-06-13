# combo_chain_manager.gd
# 连锁管理器
# 管理所有连锁规则和出牌序列
class_name ComboChainManager
extends Node

## 信号：连锁触发
signal combo_triggered(combo: ComboChain, damage_bonus: float)

## 信号：连锁检测完成
signal combo_check_completed(matched_combos: Array[ComboChain])

## 所有连锁规则
var combo_chains: Array[ComboChain] = []

## 当前出牌序列
var played_cards: Array[CardData] = []

## 本回合已触发的连锁
var triggered_combos: Array[String] = []

## 连锁触发次数限制
const MAX_COMBOS_PER_TURN: int = 3

## 当前回合连锁触发次数
var combo_count_this_turn: int = 0

## 初始化
func _ready() -> void:
	_load_default_combos()

## 加载默认连锁规则
func _load_default_combos() -> void:
	# 卡牌类型连锁
	var summon_buff_combo: ComboChain = ComboChain.new()
	summon_buff_combo.chain_id = "combo_summon_buff"
	summon_buff_combo.chain_name = "召唤强化"
	summon_buff_combo.description = "召唤生物后施加增益，伤害增加50%"
	summon_buff_combo.chain_type = ComboChain.ChainType.CARD_TYPE
	summon_buff_combo.trigger_conditions = {"card_types": [CardEnums.CardType.SUMMON, CardEnums.CardType.BUFF_DEBUFF]}
	summon_buff_combo.effect_type = ComboChain.ChainEffectType.DAMAGE_BONUS
	summon_buff_combo.effect_value = 0.5
	summon_buff_combo.priority = 10
	combo_chains.append(summon_buff_combo)
	
	# 元素连锁
	var fire_wind_combo: ComboChain = ComboChain.new()
	fire_wind_combo.chain_id = "combo_fire_wind"
	fire_wind_combo.chain_name = "风火轮"
	fire_wind_combo.description = "火+风元素连锁，触发火焰风暴"
	fire_wind_combo.chain_type = ComboChain.ChainType.ELEMENT
	fire_wind_combo.trigger_conditions = {"elements": [CardEnums.Element.FIRE, CardEnums.Element.WIND]}
	fire_wind_combo.effect_type = ComboChain.ChainEffectType.EXTRA_EFFECT
	fire_wind_combo.effect_value = 0.0
	fire_wind_combo.priority = 20
	combo_chains.append(fire_wind_combo)
	
	# 关键词连锁
	var explosion_combo: ComboChain = ComboChain.new()
	explosion_combo.chain_id = "combo_explosion"
	explosion_combo.chain_name = "连锁爆炸"
	explosion_combo.description = "火焰+爆炸关键词连锁，全体伤害"
	explosion_combo.chain_type = ComboChain.ChainType.KEYWORD
	explosion_combo.trigger_conditions = {"keywords": ["火焰", "爆炸"]}
	explosion_combo.effect_type = ComboChain.ChainEffectType.DAMAGE_BONUS
	explosion_combo.effect_value = 0.75
	explosion_combo.priority = 30
	combo_chains.append(explosion_combo)
	
	# 顺序连锁
	var sequence_combo: ComboChain = ComboChain.new()
	sequence_combo.chain_id = "combo_damage_heal"
	sequence_combo.chain_name = "攻守兼备"
	sequence_combo.description = "先伤害后治疗，返还1点能量"
	sequence_combo.chain_type = ComboChain.ChainType.SEQUENCE
	sequence_combo.trigger_conditions = {"sequence": [CardEnums.CardType.DIRECT_DAMAGE, CardEnums.CardType.BUFF_DEBUFF]}
	sequence_combo.effect_type = ComboChain.ChainEffectType.ENERGY_REFUND
	sequence_combo.effect_value = 1.0
	sequence_combo.priority = 15
	combo_chains.append(sequence_combo)

## ==================== 连锁管理 ====================

## 添加连锁规则
func add_combo_chain(combo: ComboChain) -> void:
	combo_chains.append(combo)

## 移除连锁规则
func remove_combo_chain(chain_id: String) -> void:
	for i in range(combo_chains.size()):
		if combo_chains[i].chain_id == chain_id:
			combo_chains.remove_at(i)
			return

## 获取连锁规则
func get_combo_chain(chain_id: String) -> ComboChain:
	for combo in combo_chains:
		if combo.chain_id == chain_id:
			return combo
	return null

## ==================== 出牌序列管理 ====================

## 记录出牌
func record_card_played(card: CardData) -> void:
	played_cards.append(card)
	_check_for_combos()

## 清空出牌序列
func clear_played_cards() -> void:
	played_cards.clear()

## 重置回合状态
func reset_turn() -> void:
	clear_played_cards()
	triggered_combos.clear()
	combo_count_this_turn = 0

## ==================== 连锁检测 ====================

## 检查是否有连锁触发
func _check_for_combos() -> void:
	if combo_count_this_turn >= MAX_COMBOS_PER_TURN:
		return
	
	var matched_combos: Array[ComboChain] = []
	
	# 按优先级排序
	combo_chains.sort_custom(func(a: ComboChain, b: ComboChain): return a.priority > b.priority)
	
	# 检查每个连锁规则
	for combo in combo_chains:
		# 跳过已触发的连锁
		if triggered_combos.has(combo.chain_id):
			continue
		
		# 检查条件
		if combo.check_conditions(played_cards):
			matched_combos.append(combo)
			
			# 触发连锁
			_trigger_combo(combo)
			
			# 达到限制时停止
			if combo_count_this_turn >= MAX_COMBOS_PER_TURN:
				break
	
	combo_check_completed.emit(matched_combos)

## 触发连锁
func _trigger_combo(combo: ComboChain) -> void:
	triggered_combos.append(combo.chain_id)
	combo_count_this_turn += 1
	
	# 计算连锁效果
	var effect_value: float = combo.effect_value
	
	# 发送信号
	combo_triggered.emit(combo, effect_value)

## ==================== 查询接口 ====================

## 获取当前出牌序列
func get_played_cards() -> Array[CardData]:
	return played_cards

## 获取本回合已触发的连锁
func get_triggered_combos() -> Array[String]:
	return triggered_combos

## 获取本回合连锁触发次数
func get_combo_count_this_turn() -> int:
	return combo_count_this_turn

## 检查是否还能触发连锁
func can_trigger_more_combos() -> bool:
	return combo_count_this_turn < MAX_COMBOS_PER_TURN

## 获取所有可用的连锁规则
func get_available_combos() -> Array[ComboChain]:
	return combo_chains

## 获取匹配当前出牌序列的连锁
func get_matching_combos() -> Array[ComboChain]:
	var matching: Array[ComboChain] = []
	for combo in combo_chains:
		if combo.check_conditions(played_cards):
			matching.append(combo)
	return matching

## 获取连锁预览（用于UI显示）
func get_combo_preview(card: CardData) -> Array[Dictionary]:
	var preview: Array[Dictionary] = []
	
	# 模拟出牌
	var simulated_cards: Array[CardData] = played_cards.duplicate()
	simulated_cards.append(card)
	
	# 检查所有连锁
	for combo in combo_chains:
		if combo.check_conditions(simulated_cards):
			preview.append({
				"chain_name": combo.chain_name,
				"description": combo.description,
				"effect": combo.get_effect_description(),
				"color": combo.chain_color
			})
	
	return preview

## ==================== 序列化 ====================

## 序列化为字典
func to_dict() -> Dictionary:
	var combos_data: Array[Dictionary] = []
	for combo in combo_chains:
		combos_data.append(combo.to_dict())
	
	return {
		"combo_chains": combos_data,
		"triggered_combos": triggered_combos,
		"combo_count_this_turn": combo_count_this_turn
	}

## 从字典反序列化
func load_from_dict(data: Dictionary) -> void:
	combo_chains.clear()
	
	var combos_data: Array = data.get("combo_chains", [])
	for combo_data in combos_data:
		if combo_data is Dictionary:
			combo_chains.append(ComboChain.from_dict(combo_data))
	
	triggered_combos = data.get("triggered_combos", [])
	combo_count_this_turn = data.get("combo_count_this_turn", 0)
