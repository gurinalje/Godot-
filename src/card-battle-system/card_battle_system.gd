# card_battle_system.gd
# 卡牌战斗系统
# 整合所有战斗相关系统的核心战斗循环
class_name CardBattleSystem
extends Node

## 信号：回合开始
signal turn_started(turn_number: int)

## 信号：回合结束
signal turn_ended(turn_number: int)

## 信号：卡牌打出
signal card_played(card: CardData, player: Node)

## 信号：战斗开始
signal battle_started()

## 信号：战斗结束
signal battle_ended(victory: bool)

## 信号：能量改变
signal energy_changed(current: int, max_value: int)

## 战斗状态枚举
enum BattleState {
	NOT_STARTED,
	PLAYER_TURN,
	ENEMY_TURN,
	VICTORY,
	DEFEAT
}

## 游戏配置资源路径
const GAME_CONFIG_PATH: String = "res://src/resources/game_config.tres"

## 当前战斗状态
var battle_state: BattleState = BattleState.NOT_STARTED

## 当前回合数
var turn_number: int = 0

## 玩家能量
var player_energy: int = 0
var max_energy: int = 10

## 每回合抽牌数（从配置加载）
var draw_count: int = 5

## 玩家卡组
var player_deck: Array[CardData] = []

## 玩家手牌
var player_hand: Array[CardData] = []

## 玩家弃牌堆
var player_discard: Array[CardData] = []

## 敌人列表
var enemies: Array[Node] = []

## 子系统引用
var damage_calculator: Node = null
var combo_manager: Node = null
var summon_manager: Node = null
var environment_manager: Node = null
var status_effect_manager: Node = null

## 卡牌效果处理器映射（降低圈复杂度）
var _effect_handlers: Dictionary = {}

## 初始化
func _ready() -> void:
	# 从配置加载游戏参数
	_load_game_config()
	
	# 初始化效果处理器映射
	_init_effect_handlers()
	
	# 获取子系统引用
	damage_calculator = GameManager.get_system("DamageCalculator")
	combo_manager = GameManager.get_system("ComboChainManager")
	summon_manager = GameManager.get_system("SummonManager")
	environment_manager = GameManager.get_system("EnvironmentManager")
	status_effect_manager = GameManager.get_system("StatusEffectManager")

## 加载游戏配置
func _load_game_config() -> void:
	if ResourceLoader.exists(GAME_CONFIG_PATH):
		var config: GameConfig = load(GAME_CONFIG_PATH) as GameConfig
		if config:
			max_energy = config.default_max_energy
			draw_count = config.default_draw_count
			return
	
	# 使用默认值
	max_energy = 10
	draw_count = 5

## 初始化效果处理器映射
func _init_effect_handlers() -> void:
	_effect_handlers = {
		CardEnums.EffectType.DAMAGE: _apply_damage_effect,
		CardEnums.EffectType.HEAL: _apply_heal_effect,
		CardEnums.EffectType.SUMMON: _apply_summon_effect,
		CardEnums.EffectType.BUFF: _apply_buff_effect,
		CardEnums.EffectType.DEBUFF: _apply_debuff_effect,
		CardEnums.EffectType.ENVIRONMENT_CHANGE: _apply_environment_effect,
	}

## ==================== 战斗管理 ====================

## 开始战斗
func start_battle(deck: Array[CardData], enemy_list: Array[Node]) -> void:
	battle_state = BattleState.PLAYER_TURN
	turn_number = 1
	player_energy = max_energy
	
	# 初始化卡组
	player_deck = deck.duplicate()
	player_deck.shuffle()
	player_hand.clear()
	player_discard.clear()
	
	# 初始化敌人
	enemies = enemy_list
	
	# 抽初始手牌（从配置加载数量）
	for i in range(draw_count):
		draw_card()
	
	battle_started.emit()
	turn_started.emit(turn_number)

## 结束战斗
func end_battle(victory: bool) -> void:
	battle_state = BattleState.VICTORY if victory else BattleState.DEFEAT
	battle_ended.emit(victory)

## ==================== 回合管理 ====================

## 结束玩家回合
func end_player_turn() -> void:
	if battle_state != BattleState.PLAYER_TURN:
		return
	
	# 处理回合结束效果
	_process_turn_end_effects()
	
	# 切换到敌人回合
	battle_state = BattleState.ENEMY_TURN
	turn_ended.emit(turn_number)
	
	# 执行敌人回合
	_execute_enemy_turn()

## 执行敌人回合
func _execute_enemy_turn() -> void:
	# 简化实现：敌人随机攻击
	for enemy in enemies:
		if enemy.has_method("take_action"):
			enemy.take_action()
	
	# 检查战斗是否结束
	if check_battle_end():
		return
	
	# 开始新回合
	_start_new_turn()

## 开始新回合
func _start_new_turn() -> void:
	turn_number += 1
	battle_state = BattleState.PLAYER_TURN
	player_energy = max_energy
	
	# 抽牌
	draw_card()
	draw_card()
	
	# 重置连击
	if combo_manager:
		combo_manager.reset_turn()
	
	turn_started.emit(turn_number)

## 处理回合结束效果
func _process_turn_end_effects() -> void:
	# 处理状态效果
	if status_effect_manager:
		status_effect_manager.process_turn_end(null)
	
	# 处理召唤物
	if summon_manager:
		summon_manager.process_turn_end()
	
	# 处理环境
	if environment_manager:
		environment_manager.process_turn_end()

## ==================== 卡牌操作 ====================

## 抽牌
func draw_card() -> bool:
	if player_deck.is_empty():
		# 洗牌弃牌堆
		if player_discard.is_empty():
			return false
		player_deck = player_discard.duplicate()
		player_deck.shuffle()
		player_discard.clear()
	
	var card: CardData = player_deck.pop_back()
	player_hand.append(card)
	return true

## 打出卡牌
func play_card(card: CardData, target: Node = null) -> bool:
	# 检查是否在玩家回合
	if battle_state != BattleState.PLAYER_TURN:
		return false
	
	# 检查能量
	if card.cost > player_energy:
		return false
	
	# 检查手牌
	if not player_hand.has(card):
		return false
	
	# 消耗能量
	player_energy -= card.cost
	energy_changed.emit(player_energy, max_energy)
	
	# 记录出牌（用于连锁检测）
	if combo_manager:
		combo_manager.record_card_played(card)
	
	# 应用卡牌效果
	_apply_card_effects(card, target)
	
	# 从手牌移除
	player_hand.erase(card)
	player_discard.append(card)
	
	card_played.emit(card, null)
	
	# 检查战斗是否结束
	check_battle_end()
	
	return true

## 应用卡牌效果（使用字典映射降低圈复杂度）
func _apply_card_effects(card: CardData, target: Node) -> void:
	for effect in card.effects:
		var handler: Callable = _effect_handlers.get(effect.effect_type)
		if handler:
			if effect.effect_type == CardEnums.EffectType.DAMAGE:
				handler.call(effect, card, target)
			elif effect.effect_type in [CardEnums.EffectType.SUMMON, CardEnums.EffectType.ENVIRONMENT_CHANGE]:
				handler.call(effect, card)
			else:
				handler.call(effect, target)

## 应用伤害效果
func _apply_damage_effect(effect: CardEffect, card: CardData, target: Node) -> void:
	if target == null:
		target = _get_default_target(effect.target)
	
	if target == null:
		return
	
	var base_damage: int = effect.value
	
	# 应用连锁加成
	if combo_manager:
		var matching_combos: Array[ComboChain] = combo_manager.get_matching_combos()
		for combo in matching_combos:
			if combo.effect_type == ComboChain.ChainEffectType.DAMAGE_BONUS:
				base_damage = int(float(base_damage) * (1.0 + combo.effect_value))
	
	# 计算最终伤害
	if damage_calculator:
		var result: Dictionary = damage_calculator.calculate_damage(null, target, base_damage, card.element)
		var final_damage: int = result.get("damage", base_damage)
		
		if target.has_method("take_damage"):
			target.take_damage(final_damage)

## 应用治疗效果
func _apply_heal_effect(effect: CardEffect, target: Node) -> void:
	if target == null:
		target = self  # 默认治疗自己
	
	if target.has_method("heal"):
		target.heal(effect.value)

## 应用召唤效果
func _apply_summon_effect(effect: CardEffect, card: CardData) -> void:
	if summon_manager == null:
		return
	
	var unit: SummonUnit = SummonUnit.new()
	unit.summon_id = "summon_" + str(randi())
	unit.summon_name = card.display_name + " Summon"
	unit.base_health = effect.value
	unit.base_attack = effect.value / 2
	unit.element = card.element
	summon_manager.summon_unit(unit)

## 应用增益效果
func _apply_buff_effect(effect: CardEffect, target: Node) -> void:
	if target == null:
		target = self
	
	if target.has_method("add_status_effect"):
		var status_effect: StatusEffect = StatusEffect.new()
		status_effect.effect_id = "buff_" + str(randi())
		status_effect.effect_name = "Buff"
		status_effect.effect_type = StatusEffect.EffectType.BUFF
		status_effect.value = effect.value
		status_effect.duration = effect.duration if effect.duration > 0 else 3
		target.add_status_effect(status_effect)

## 应用减益效果
func _apply_debuff_effect(effect: CardEffect, target: Node) -> void:
	if target == null:
		target = _get_default_target(effect.target)
	
	if target == null:
		return
	
	if target.has_method("add_status_effect"):
		var status_effect: StatusEffect = StatusEffect.new()
		status_effect.effect_id = "debuff_" + str(randi())
		status_effect.effect_name = "Debuff"
		status_effect.effect_type = StatusEffect.EffectType.DEBUFF
		status_effect.value = effect.value
		status_effect.duration = effect.duration if effect.duration > 0 else 3
		status_effect.is_negative = true
		target.add_status_effect(status_effect)

## 应用环境效果
func _apply_environment_effect(effect: CardEffect, card: CardData) -> void:
	if environment_manager == null:
		return
	
	var env: EnvironmentEffect = EnvironmentEffect.new()
	env.environment_id = "env_" + card.id
	env.environment_name = card.display_name + " Environment"
	env.description = card.description
	env.duration = effect.duration if effect.duration > 0 else 3
	
	# 根据卡牌元素设置环境类型
	match card.element:
		CardEnums.Element.FIRE:
			env.environment_type = EnvironmentEffect.EnvironmentType.FIRE
		CardEnums.Element.WATER:
			env.environment_type = EnvironmentEffect.EnvironmentType.WATER
		CardEnums.Element.EARTH:
			env.environment_type = EnvironmentEffect.EnvironmentType.EARTH
		CardEnums.Element.WIND:
			env.environment_type = EnvironmentEffect.EnvironmentType.WIND
		CardEnums.Element.LIGHTNING:
			env.environment_type = EnvironmentEffect.EnvironmentType.LIGHTNING
	
	environment_manager.set_environment(env)

## 获取默认目标
func _get_default_target(target_type: int) -> Node:
	match target_type:
		CardEnums.TargetType.SELF:
			return self
		CardEnums.TargetType.ENEMY:
			if not enemies.is_empty():
				return enemies[0]
		CardEnums.TargetType.RANDOM:
			if not enemies.is_empty():
				return enemies[randi() % enemies.size()]
	return null

## ==================== 战斗结束条件检查 ====================

## 检查战斗是否结束
## 在每次关键操作后调用（出牌、敌人行动等）
func check_battle_end() -> bool:
	# 检查敌人是否全部死亡
	if _are_all_enemies_defeated():
		end_battle(true)
		return true
	
	# 检查玩家是否死亡（需要外部传入玩家引用或使用GameManager）
	if _is_player_defeated():
		end_battle(false)
		return true
	
	return false

## 检查是否所有敌人已被击败
func _are_all_enemies_defeated() -> bool:
	if enemies.is_empty():
		return false
	
	for enemy in enemies:
		if enemy and is_instance_valid(enemy):
			# 检查敌人是否有 is_alive 方法
			if enemy.has_method("is_alive") and enemy.is_alive():
				return false
			# 检查敌人是否有 health 属性
			elif enemy.has_method("get") and enemy.get("health", 0) > 0:
				return false
	return true

## 检查玩家是否已被击败
func _is_player_defeated() -> bool:
	# 通过 GameManager 检查玩家状态
	if GameManager and GameManager.has_method("get"):
		var player_health: int = GameManager.get("player_health", 0)
		return player_health <= 0
	return false

## ==================== 查询接口 ====================

## 获取当前战斗状态
func get_battle_state() -> Dictionary:
	return {
		"state": battle_state,
		"turn_number": turn_number,
		"player_energy": player_energy,
		"max_energy": max_energy,
		"hand_size": player_hand.size(),
		"deck_size": player_deck.size(),
		"discard_size": player_discard.size(),
		"enemy_count": enemies.size()
	}

## 获取手牌
func get_hand() -> Array[CardData]:
	return player_hand

## 检查是否可以打出卡牌
func can_play_card(card: CardData) -> bool:
	if battle_state != BattleState.PLAYER_TURN:
		return false
	if card.cost > player_energy:
		return false
	if not player_hand.has(card):
		return false
	return true

## ==================== 序列化 ====================

## 序列化为字典
func to_dict() -> Dictionary:
	var hand_data: Array[Dictionary] = []
	for card in player_hand:
		hand_data.append(card.to_dict())
	
	var deck_data: Array[Dictionary] = []
	for card in player_deck:
		deck_data.append(card.to_dict())
	
	var discard_data: Array[Dictionary] = []
	for card in player_discard:
		discard_data.append(card.to_dict())
	
	return {
		"battle_state": battle_state,
		"turn_number": turn_number,
		"player_energy": player_energy,
		"max_energy": max_energy,
		"player_hand": hand_data,
		"player_deck": deck_data,
		"player_discard": discard_data
	}

## 从字典反序列化
func load_from_dict(data: Dictionary) -> void:
	battle_state = data.get("battle_state", BattleState.NOT_STARTED)
	turn_number = data.get("turn_number", 0)
	player_energy = data.get("player_energy", 0)
	max_energy = data.get("max_energy", 10)
	
	player_hand.clear()
	for card_data in data.get("player_hand", []):
		player_hand.append(CardData.from_dict(card_data))
	
	player_deck.clear()
	for card_data in data.get("player_deck", []):
		player_deck.append(CardData.from_dict(card_data))
	
	player_discard.clear()
	for card_data in data.get("player_discard", []):
		player_discard.append(CardData.from_dict(card_data))
