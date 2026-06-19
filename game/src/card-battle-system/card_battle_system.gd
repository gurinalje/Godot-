# card_battle_system.gd
# 卡牌战斗系统 - 战斗逻辑的唯一真实来源
# 所有战斗状态、计算、效果处理都在此完成
# UI层（card_battle.gd）仅通过信号接收状态变化并更新显示
class_name CardBattleSystem
extends Node

## ==================== 信号：UI层监听 ====================

## 战斗生命周期
signal battle_started()
signal battle_ended(victory: bool)

## 回合生命周期
signal turn_started(turn_number: int)
signal turn_ended(turn_number: int)

## 卡牌操作
signal card_played(card: CardData, card_index: int)
signal energy_changed(current: int, max_value: int)
signal hand_changed(hand: Array[CardData])

## 伤害事件（UI用于显示浮动数字和震屏）
signal enemy_damaged(enemy_index: int, damage: int, is_critical: bool)
signal player_damaged(damage: int, is_critical: bool)
signal enemy_healed(enemy_index: int, amount: int)
signal player_healed(amount: int)

## 死亡事件
signal enemy_defeated(enemy_index: int, enemy_name: String)
signal player_defeated()

## Buff/Debuff事件
signal buff_applied(target: String, buff_type: String, value: int, duration: int)
signal buff_expired(target: String, buff_type: String)
signal debuff_applied(target: String, debuff_type: String, value: int, duration: int)

## 召唤物事件
signal summon_added(summon: Dictionary)
signal summon_removed(summon: Dictionary, index: int)
signal summon_damaged(index: int, damage: int)
signal summon_defeated(index: int, summon_name: String)

## 环境事件
signal environment_applied(env_name: String, duration: int)
signal environment_expired()

## DOT/HOT事件
signal dot_applied(target: String, damage: int, duration: int)
signal dot_damage(target: String, damage: int)

## 日志和提示（UI用于显示）
signal log_message(message: String)
signal turn_indicator(text: String)

## ==================== 枚举 ====================

## 战斗状态
enum BattleState {
	NOT_STARTED,
	PLAYER_TURN,
	ENEMY_TURN,
	VICTORY,
	DEFEAT
}

## ==================== 常量 ====================

## 游戏配置资源路径
const GAME_CONFIG_PATH: String = "res://src/resources/game_config.tres"
const MAX_HAND_SIZE: int = 10
const MAX_SUMMONS: int = 3

## ==================== 战斗状态 ====================

## 当前战斗状态
var battle_state: BattleState = BattleState.NOT_STARTED

## 当前回合数
var turn_number: int = 0

## 玩家能量
var player_energy: int = 0
var max_energy: int = 10

## 每回合抽牌数（从配置加载）
var draw_count: int = 5

## 玩家状态
var player_health: int = 100
var player_max_health: int = 100
var player_mana: int = 100
var player_max_mana: int = 100
var player_defense: int = 0

## 卡牌数据
var player_deck: Array[CardData] = []
var player_hand: Array[CardData] = []
var player_discard: Array[CardData] = []

## 敌人数据（使用字典而非Node，与现有代码兼容）
var enemies: Array[Dictionary] = []
var current_enemy_index: int = 0

## 召唤物
var summons: Array[Dictionary] = []

## 活跃的Buff/Debuff
var active_buffs: Array[Dictionary] = []

## 子系统引用
var damage_calculator: Node = null
var combo_manager: Node = null
var summon_manager: Node = null
var environment_manager: Node = null
var status_effect_manager: Node = null
var game_config: GameConfig = null

## 卡牌效果处理器映射（降低圈复杂度）
var _effect_handlers: Dictionary = {}

## ==================== 初始化 ====================

func _ready() -> void:
	_load_game_config()
	_init_effect_handlers()
	_init_subsystems()

## 加载游戏配置
func _load_game_config() -> void:
	if ResourceLoader.exists(GAME_CONFIG_PATH):
		game_config = load(GAME_CONFIG_PATH) as GameConfig
		if game_config:
			max_energy = game_config.default_max_energy
			draw_count = game_config.default_draw_count
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

## 初始化子系统引用
func _init_subsystems() -> void:
	damage_calculator = GameManager.get_system("DamageCalculator")
	combo_manager = GameManager.get_system("ComboChainManager")
	summon_manager = GameManager.get_system("SummonManager")
	environment_manager = GameManager.get_system("EnvironmentManager")
	status_effect_manager = GameManager.get_system("StatusEffectManager")

## ==================== 战斗管理 ====================

## 开始战斗
## [param] deck: 玩家卡组
## [param] enemy_list: 敌人数据列表（字典数组）
## [param] player_stats: 可选的玩家状态字典 {health, max_health, mana, max_mana, defense}
func start_battle(deck: Array[CardData], enemy_list: Array[Dictionary], player_stats: Dictionary = {}) -> void:
	battle_state = BattleState.PLAYER_TURN
	turn_number = 1
	
	# 初始化玩家状态
	_init_player_stats(player_stats)
	player_energy = max_energy
	
	# 初始化卡组
	player_deck = deck.duplicate()
	player_deck.shuffle()
	player_hand.clear()
	player_discard.clear()
	
	# 初始化敌人
	enemies = enemy_list.duplicate()
	_ensure_enemy_defaults()
	
	# 初始化召唤物和Buff
	summons.clear()
	active_buffs.clear()
	
	# 抽初始手牌
	for i in range(draw_count):
		draw_card()
	
	battle_started.emit()
	turn_started.emit(turn_number)
	log_message.emit("战斗开始！")
	turn_indicator.emit("你的回合 - 选择卡牌使用")

## 初始化玩家状态
func _init_player_stats(stats: Dictionary) -> void:
	if stats.is_empty():
		# 从GameManager获取
		if GameManager:
			player_health = GameManager.player_health
			player_max_health = GameManager.player_max_health
			player_mana = GameManager.player_mana
			player_max_mana = GameManager.player_max_mana
			player_defense = GameManager.player_defense
		else:
			player_health = 100
			player_max_health = 100
			player_mana = 100
			player_max_mana = 100
			player_defense = 0
	else:
		player_health = stats.get("health", 100)
		player_max_health = stats.get("max_health", 100)
		player_mana = stats.get("mana", 100)
		player_max_mana = stats.get("max_mana", 100)
		player_defense = stats.get("defense", 0)

## 确保敌人数据有默认值
func _ensure_enemy_defaults() -> void:
	for i in range(enemies.size()):
		if not enemies[i].has("max_health"):
			enemies[i]["max_health"] = enemies[i].get("health", 50)
		if not enemies[i].has("effects"):
			enemies[i]["effects"] = []

## 结束战斗
func end_battle(victory: bool) -> void:
	battle_state = BattleState.VICTORY if victory else BattleState.DEFEAT
	battle_ended.emit(victory)
	
	if victory:
		log_message.emit("战斗胜利！")
	else:
		log_message.emit("战斗失败...")

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
	log_message.emit("敌人回合开始")
	turn_indicator.emit("敌人回合...")
	
	# 先处理所有敌人的持续效果（DOT等）
	_process_enemy_effects()
	
	# 对每个敌人执行行动
	for i in range(enemies.size()):
		var enemy = enemies[i]
		if enemy.get("health", 0) <= 0:
			continue
		_enemy_attack(i)
	
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
	for i in range(draw_count):
		draw_card()
	
	# 重置连击
	if combo_manager:
		combo_manager.reset_turn()
	
	# 处理Buff持续时间
	_process_buffs_at_turn_end()
	
	turn_started.emit(turn_number)
	log_message.emit("回合 " + str(turn_number) + " 开始")
	turn_indicator.emit("你的回合 - 选择卡牌使用")

## 处理回合结束效果
func _process_turn_end_effects() -> void:
	if status_effect_manager:
		status_effect_manager.process_turn_end(null)
	if summon_manager:
		summon_manager.process_turn_end()
	if environment_manager:
		environment_manager.process_turn_end()

## ==================== 敌人管理 ====================

## 设置敌人列表
func set_enemies(enemy_list: Array[Dictionary]) -> void:
	enemies = enemy_list.duplicate()
	_ensure_enemy_defaults()

## 获取敌人数量
func get_enemy_count() -> int:
	return enemies.size()

## 获取敌人数据
func get_enemy(index: int) -> Dictionary:
	if index >= 0 and index < enemies.size():
		return enemies[index]
	return {}

## 获取当前目标敌人
func get_current_target() -> Dictionary:
	return get_enemy(current_enemy_index)

## 设置当前目标敌人
func set_current_target(index: int) -> void:
	if index >= 0 and index < enemies.size():
		current_enemy_index = index

## 检查是否所有敌人已被击败
func _are_all_enemies_defeated() -> bool:
	if enemies.is_empty():
		# 没有敌人 = 所有敌人已被击败
		return true
	for enemy in enemies:
		if enemy.get("health", 0) > 0:
			return false
	return true

## ==================== 敌人攻击 ====================

## 敌人攻击
func _enemy_attack(enemy_index: int) -> void:
	if enemy_index < 0 or enemy_index >= enemies.size():
		return
	
	var enemy = enemies[enemy_index]
	var damage = enemy.get("attack", 0)
	
	# 检查是否有召唤物可以挡伤害
	if summons.size() > 0:
		var summon = summons[0]
		summon["health"] -= damage
		summon_damaged.emit(0, damage)
		log_message.emit(enemy.get("name", "敌人") + " 攻击召唤物 " + summon["name"] + "，造成 " + str(damage) + " 点伤害")
		
		if summon["health"] <= 0:
			var summon_name = summon["name"]
			summons.remove_at(0)
			summon_defeated.emit(0, summon_name)
			log_message.emit(summon_name + " 被击败！")
	else:
		_apply_damage_to_player(damage)

## 对玩家造成伤害
func _apply_damage_to_player(damage: int) -> void:
	var actual_damage = max(1, damage - player_defense)
	player_health -= actual_damage
	
	player_damaged.emit(actual_damage, false)
	log_message.emit("玩家受到 " + str(actual_damage) + " 点伤害")
	
	if player_health <= 0:
		player_health = 0
		_on_player_defeated()

## 玩家失败处理
func _on_player_defeated() -> void:
	battle_state = BattleState.DEFEAT
	player_defeated.emit()
	end_battle(false)

## ==================== 敌人效果处理（DOT等） ====================

## 处理敌人的持续效果
func _process_enemy_effects() -> void:
	for i in range(enemies.size()):
		var enemy = enemies[i]
		if enemy.get("health", 0) <= 0:
			continue
		
		if not enemy.has("effects") or enemy["effects"].is_empty():
			continue
		
		var effects_to_remove: Array[int] = []
		for j in range(enemy["effects"].size()):
			var effect = enemy["effects"][j]
			
			match effect.get("type", ""):
				"dot":
					var dot_value = effect.get("value", 0)
					enemy["health"] -= dot_value
					self.dot_damage.emit(enemy.get("name", "敌人"), dot_value)
					enemy_damaged.emit(i, dot_value, false)
					log_message.emit(enemy.get("name", "敌人") + " 受到 " + str(dot_value) + " 点持续伤害")
					
					effect["duration"] -= 1
					if effect["duration"] <= 0:
						effects_to_remove.append(j)
				
				"debuff":
					effect["duration"] -= 1
					if effect["duration"] <= 0:
						effects_to_remove.append(j)
		
		# 从后往前移除过期效果
		effects_to_remove.reverse()
		for index in effects_to_remove:
			enemy["effects"].remove_at(index)
		
		# 检查敌人是否被DOT杀死
		if enemy.get("health", 0) <= 0:
			enemy["health"] = 0
			var enemy_name = enemy.get("name", "敌人")
			enemy_defeated.emit(i, enemy_name)
			log_message.emit(enemy_name + " 被击败！")

## ==================== Buff管理 ====================

## 处理回合结束时的Buff持续时间
func _process_buffs_at_turn_end() -> void:
	var buffs_to_remove: Array[int] = []
	for i in range(active_buffs.size()):
		active_buffs[i]["duration"] -= 1
		if active_buffs[i]["duration"] <= 0:
			buffs_to_remove.append(i)
	
	buffs_to_remove.reverse()
	for index in buffs_to_remove:
		var buff = active_buffs[index]
		# 撤销Buff效果
		match buff["type"]:
			"defense_boost":
				player_defense -= buff["value"]
		buff_expired.emit("player", buff["type"])
		active_buffs.remove_at(index)

## 应用Buff
func _apply_buff(buff_type: String, value: int, duration: int) -> void:
	var buff = {
		"type": buff_type,
		"value": value,
		"duration": duration
	}
	active_buffs.append(buff)
	
	match buff_type:
		"attack_boost":
			buff_applied.emit("player", "attack_boost", value, duration)
			log_message.emit("攻击力提升 " + str(value) + " 点，持续 " + str(duration) + " 回合")
			turn_indicator.emit("攻击力 +" + str(value))
		"defense_boost":
			player_defense += value
			buff_applied.emit("player", "defense_boost", value, duration)
			log_message.emit("防御力提升 " + str(value) + " 点，持续 " + str(duration) + " 回合")
			turn_indicator.emit("防御力 +" + str(value))
		"heal":
			var old_health = player_health
			player_health = min(player_max_health, player_health + value)
			var healed = player_health - old_health
			player_healed.emit(healed)
			log_message.emit("恢复 " + str(healed) + " 点生命值")
			turn_indicator.emit("恢复 " + str(healed) + " HP")

## ==================== 召唤物管理 ====================

## 获取召唤物列表
func get_summons() -> Array[Dictionary]:
	return summons

## 获取召唤物数量
func get_summon_count() -> int:
	return summons.size()

## ==================== 卡牌操作 ====================

## 抽牌
func draw_card() -> bool:
	if player_hand.size() >= MAX_HAND_SIZE:
		return false
	
	if player_deck.is_empty():
		if player_discard.is_empty():
			return false
		player_deck = player_discard.duplicate()
		player_deck.shuffle()
		player_discard.clear()
		log_message.emit("卡组已重新洗牌")
	
	var card: CardData = player_deck.pop_back()
	player_hand.append(card)
	hand_changed.emit(player_hand)
	return true

## 按索引打出卡牌（UI层调用此方法）
func play_card_by_index(card_index: int) -> bool:
	if battle_state != BattleState.PLAYER_TURN:
		turn_indicator.emit("现在不是你的回合！")
		return false
	
	if card_index < 0 or card_index >= player_hand.size():
		return false
	
	var card = player_hand[card_index]
	
	# 检查能量
	if card.cost > player_energy:
		turn_indicator.emit("能量不足！需要 " + str(card.cost) + " 能量")
		return false
	
	# 检查HP消耗
	if card.hp_cost > 0 and player_health <= card.hp_cost:
		turn_indicator.emit("生命值不足！需要 " + str(card.hp_cost) + " 生命值")
		return false
	
	# 检查MP消耗
	if card.mp_cost > 0 and player_mana < card.mp_cost:
		turn_indicator.emit("魔法值不足！需要 " + str(card.mp_cost) + " 魔法值")
		return false
	
	# 消耗能量
	player_energy -= card.cost
	energy_changed.emit(player_energy, max_energy)
	
	# 消耗HP和MP
	if card.hp_cost > 0:
		player_health -= card.hp_cost
		log_message.emit("消耗了 " + str(card.hp_cost) + " 点生命值")
	if card.mp_cost > 0:
		player_mana -= card.mp_cost
		log_message.emit("消耗了 " + str(card.mp_cost) + " 点魔法值")
	
	# 记录出牌（用于连锁检测）
	if combo_manager:
		combo_manager.record_card_played(card)
	
	# 应用卡牌效果
	_apply_card_effects(card)
	
	# 从手牌移除
	player_hand.remove_at(card_index)
	if card.is_single_use:
		log_message.emit("道具「" + card.display_name + "」已被消耗销毁")
	else:
		player_discard.append(card)
	
	hand_changed.emit(player_hand)
	card_played.emit(card, card_index)
	log_message.emit("打出卡牌: " + card.display_name)
	
	# 检查战斗是否结束
	check_battle_end()
	
	return true

## 打出卡牌（原始方法，保持兼容）
func play_card(card: CardData, target: Dictionary = {}) -> bool:
	if battle_state != BattleState.PLAYER_TURN:
		return false
	if card.cost > player_energy:
		return false
	if not player_hand.has(card):
		return false
	
	player_energy -= card.cost
	energy_changed.emit(player_energy, max_energy)
	
	if combo_manager:
		combo_manager.record_card_played(card)
	
	_apply_card_effects(card)
	
	player_hand.erase(card)
	player_discard.append(card)
	hand_changed.emit(player_hand)
	card_played.emit(card, -1)
	
	check_battle_end()
	return true

## 应用卡牌效果（使用字典映射降低圈复杂度）
func _apply_card_effects(card: CardData) -> void:
	for effect in card.effects:
		var handler: Callable = _effect_handlers.get(effect.effect_type)
		if handler:
			if effect.effect_type == CardEnums.EffectType.DAMAGE:
				handler.call(effect, card)
			elif effect.effect_type in [CardEnums.EffectType.SUMMON, CardEnums.EffectType.ENVIRONMENT_CHANGE]:
				handler.call(effect, card)
			else:
				handler.call(effect)

## ==================== 效果处理器 ====================

## 应用伤害效果
func _apply_damage_effect(effect: CardEffect, card: CardData) -> void:
	var target = get_current_target()
	if target.is_empty():
		return
	
	var base_damage: int = effect.value
	if base_damage == 0:
		base_damage = card.cost * 5
	
	# 召唤物攻击加成
	var summon_bonus = 0
	for summon in summons:
		summon_bonus += int(summon.get("attack", 0) / 2.0)
	base_damage += summon_bonus
	
	# 应用连锁加成
	if combo_manager:
		var matching_combos: Array[ComboChain] = combo_manager.get_matching_combos()
		for combo in matching_combos:
			if combo.effect_type == ComboChain.ChainEffectType.DAMAGE_BONUS:
				base_damage = int(float(base_damage) * (1.0 + combo.effect_value))
	
	# 获取暴击配置
	var crit_rate: float = 0.05
	var crit_damage: float = 1.5
	if game_config:
		crit_rate = game_config.default_crit_rate
		crit_damage = game_config.default_crit_damage
	
	# 计算最终伤害
	var final_damage = base_damage
	var is_critical = false
	
	if damage_calculator:
		var result = damage_calculator.calculate_damage_from_stats(
			base_damage,
			card.element,
			target.get("element", CardEnums.Element.NONE),
			target.get("defense", 0),
			crit_rate,
			crit_damage
		)
		final_damage = result.get("final_damage", base_damage)
		is_critical = result.get("is_critical", false)
	else:
		# 简单伤害计算
		var defense = target.get("defense", 0)
		final_damage = max(1, base_damage - defense)
	
	# 应用伤害
	_apply_damage_to_enemy(current_enemy_index, final_damage, is_critical)

## 对敌人造成伤害
func _apply_damage_to_enemy(enemy_index: int, damage: int, is_critical: bool = false) -> void:
	if enemy_index < 0 or enemy_index >= enemies.size():
		return
	
	enemies[enemy_index]["health"] -= damage
	enemy_damaged.emit(enemy_index, damage, is_critical)
	
	if enemies[enemy_index]["health"] <= 0:
		enemies[enemy_index]["health"] = 0
		var enemy_name = enemies[enemy_index].get("name", "敌人")
		enemy_defeated.emit(enemy_index, enemy_name)
		log_message.emit(enemy_name + " 被击败！")

## 应用治疗效果
func _apply_heal_effect(effect: CardEffect) -> void:
	var old_health = player_health
	player_health = min(player_max_health, player_health + effect.value)
	var healed = player_health - old_health
	player_healed.emit(healed)
	log_message.emit("恢复 " + str(healed) + " 点生命值")

## 应用召唤效果
func _apply_summon_effect(effect: CardEffect, card: CardData) -> void:
	if summons.size() >= MAX_SUMMONS:
		log_message.emit("场上召唤物已满！最多 " + str(MAX_SUMMONS) + " 个")
		return
	
	var unit = {
		"name": card.display_name + " Summon",
		"health": effect.value,
		"max_health": effect.value,
		"attack": int(effect.value / 2.0),
		"element": CardEnums.get_element_name(card.element)
	}
	summons.append(unit)
	summon_added.emit(unit)
	log_message.emit("召唤了 " + unit["name"] + "（HP:" + str(unit["health"]) + " 攻击:" + str(unit["attack"]) + "）")

## 应用增益效果
func _apply_buff_effect(effect: CardEffect) -> void:
	_apply_buff("attack_boost", effect.value, effect.duration if effect.duration > 0 else 3)

## 应用减益效果
func _apply_debuff_effect(effect: CardEffect) -> void:
	var target = get_current_target()
	if target.is_empty():
		return
	
	# 对敌人施加减益
	var debuff = {
		"type": "debuff",
		"value": effect.value,
		"duration": effect.duration if effect.duration > 0 else 3
	}
	if not target.has("effects"):
		target["effects"] = []
	target["effects"].append(debuff)
	debuff_applied.emit(target.get("name", "敌人"), "debuff", effect.value, debuff["duration"])
	log_message.emit("对 " + target.get("name", "敌人") + " 施加减益效果")

## 应用环境效果
func _apply_environment_effect(effect: CardEffect, card: CardData) -> void:
	var env_duration = effect.duration if effect.duration > 0 else 3
	
	# 对所有敌人添加DOT效果
	for i in range(enemies.size()):
		var enemy = enemies[i]
		if enemy.get("health", 0) > 0:
			var dot = {
				"type": "dot",
				"value": effect.value,
				"duration": env_duration
			}
			if not enemy.has("effects"):
				enemy["effects"] = []
			enemy["effects"].append(dot)
			dot_applied.emit(enemy.get("name", "敌人"), effect.value, env_duration)
	
	environment_applied.emit(card.display_name, env_duration)
	log_message.emit("施放环境效果：" + card.display_name + "，持续 " + str(env_duration) + " 回合")

## ==================== 战斗结束条件检查 ====================

## 检查战斗是否结束
func check_battle_end() -> bool:
	if _are_all_enemies_defeated():
		end_battle(true)
		return true
	
	if player_health <= 0:
		end_battle(false)
		return true
	
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
		"enemy_count": enemies.size(),
		"player_health": player_health,
		"player_max_health": player_max_health,
		"player_mana": player_mana,
		"player_max_mana": player_max_mana,
		"player_defense": player_defense,
		"summon_count": summons.size()
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

## 获取玩家状态
func get_player_stats() -> Dictionary:
	return {
		"health": player_health,
		"max_health": player_max_health,
		"mana": player_mana,
		"max_mana": player_max_mana,
		"defense": player_defense,
		"energy": player_energy,
		"max_energy": max_energy
	}

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
		"player_discard": discard_data,
		"player_health": player_health,
		"player_max_health": player_max_health,
		"player_mana": player_mana,
		"player_max_mana": player_max_mana,
		"player_defense": player_defense,
		"enemies": enemies,
		"summons": summons,
		"active_buffs": active_buffs
	}

## 从字典反序列化
func load_from_dict(data: Dictionary) -> void:
	battle_state = data.get("battle_state", BattleState.NOT_STARTED)
	turn_number = data.get("turn_number", 0)
	player_energy = data.get("player_energy", 0)
	max_energy = data.get("max_energy", 10)
	player_health = data.get("player_health", 100)
	player_max_health = data.get("player_max_health", 100)
	player_mana = data.get("player_mana", 100)
	player_max_mana = data.get("player_max_mana", 100)
	player_defense = data.get("player_defense", 0)
	
	player_hand.clear()
	for card_data in data.get("player_hand", []):
		player_hand.append(CardData.from_dict(card_data))
	
	player_deck.clear()
	for card_data in data.get("player_deck", []):
		player_deck.append(CardData.from_dict(card_data))
	
	player_discard.clear()
	for card_data in data.get("player_discard", []):
		player_discard.append(CardData.from_dict(card_data))
	
	enemies = data.get("enemies", [])
	summons = data.get("summons", [])
	active_buffs = data.get("active_buffs", [])
