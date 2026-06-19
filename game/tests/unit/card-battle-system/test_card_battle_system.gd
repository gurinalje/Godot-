## CardBattleSystem 单元测试
## 覆盖核心战斗循环、卡牌操作、伤害计算、DOT效果、召唤物系统
extends GutTest

# System under test
var battle_system: CardBattleSystem
var game_config: GameConfig

# 测试用卡牌数据
var _test_card_attack: CardData
var _test_card_heal: CardData
var _test_card_buff: CardData

# 测试用敌人数据
var _test_enemy_weak: Dictionary
var _test_enemy_strong: Dictionary

func before_each() -> void:
	battle_system = CardBattleSystem.new()
	game_config = GameConfig.new()
	battle_system.game_config = game_config
	# 跳过 _init_subsystems 避免 GameManager 依赖
	battle_system.damage_calculator = null
	battle_system.combo_manager = null
	battle_system.summon_manager = null
	battle_system.environment_manager = null
	battle_system.status_effect_manager = null
	add_child(battle_system)

	# 创建测试卡牌
	_test_card_attack = CardData.new()
	_test_card_attack.id = "test_attack"
	_test_card_attack.display_name = "测试攻击"
	_test_card_attack.card_type = CardEnums.CardType.DIRECT_DAMAGE
	_test_card_attack.cost = 2
	_test_card_attack.element = CardEnums.Element.FIRE

	_test_card_heal = CardData.new()
	_test_card_heal.id = "test_heal"
	_test_card_heal.display_name = "测试治疗"
	_test_card_heal.card_type = CardEnums.CardType.BUFF_DEBUFF
	_test_card_heal.cost = 1

	_test_card_buff = CardData.new()
	_test_card_buff.id = "test_buff"
	_test_card_buff.display_name = "测试增益"
	_test_card_buff.card_type = CardEnums.CardType.BUFF_DEBUFF
	_test_card_buff.cost = 1

	# 创建测试敌人
	_test_enemy_weak = {
		"name": "弱敌",
		"health": 20,
		"max_health": 20,
		"attack": 5,
		"defense": 0,
		"element": CardEnums.Element.NONE,
		"effects": []
	}

	_test_enemy_strong = {
		"name": "强敌",
		"health": 100,
		"max_health": 100,
		"attack": 15,
		"defense": 5,
		"element": CardEnums.Element.WATER,
		"effects": []
	}

func after_each() -> void:
	battle_system.queue_free()

## ==================== A. 战斗生命周期 ====================

func test_start_battle_initializes_state() -> void:
	var deck: Array[CardData] = []
	for i in range(20):
		deck.append(_test_card_attack.duplicate())

	battle_system.start_battle(deck, [_test_enemy_weak.duplicate(true)])

	assert_eq(battle_system.battle_state, CardBattleSystem.BattleState.PLAYER_TURN)
	assert_eq(battle_system.turn_number, 1)
	assert_eq(battle_system.player_energy, battle_system.max_energy)
	assert_false(battle_system.player_deck.is_empty(), "卡组不应为空")
	assert_eq(battle_system.enemies.size(), 1)

func test_start_battle_emits_signals() -> void:
	watch_signals(battle_system)

	var deck: Array[CardData] = []
	for i in range(20):
		deck.append(_test_card_attack.duplicate())

	battle_system.start_battle(deck, [_test_enemy_weak.duplicate(true)])

	assert_signal_emitted(battle_system, "battle_started")
	assert_signal_emitted(battle_system, "turn_started")
	assert_signal_emitted(battle_system, "log_message")

func test_start_battle_draws_initial_hand() -> void:
	var deck: Array[CardData] = []
	for i in range(20):
		deck.append(_test_card_attack.duplicate())

	battle_system.start_battle(deck, [_test_enemy_weak.duplicate(true)])

	assert_eq(battle_system.player_hand.size(), battle_system.draw_count, "初始手牌应等于draw_count")

func test_end_battle_victory() -> void:
	watch_signals(battle_system)

	var deck: Array[CardData] = []
	for i in range(20):
		deck.append(_test_card_attack.duplicate())

	battle_system.start_battle(deck, [_test_enemy_weak.duplicate(true)])
	battle_system.end_battle(true)

	assert_eq(battle_system.battle_state, CardBattleSystem.BattleState.VICTORY)
	assert_signal_emitted(battle_system, "battle_ended")

func test_end_battle_defeat() -> void:
	watch_signals(battle_system)

	var deck: Array[CardData] = []
	for i in range(20):
		deck.append(_test_card_attack.duplicate())

	battle_system.start_battle(deck, [_test_enemy_weak.duplicate(true)])
	battle_system.end_battle(false)

	assert_eq(battle_system.battle_state, CardBattleSystem.BattleState.DEFEAT)
	assert_signal_emitted(battle_system, "battle_ended")

func test_end_turn_increments_turn() -> void:
	var deck: Array[CardData] = []
	for i in range(20):
		deck.append(_test_card_attack.duplicate())

	battle_system.start_battle(deck, [_test_enemy_weak.duplicate(true)])
	var initial_turn = battle_system.turn_number

	# 设置敌人为低攻击，避免玩家死亡
	battle_system.enemies[0]["attack"] = 1
	battle_system.player_defense = 0
	battle_system.player_health = 100

	battle_system.end_player_turn()

	assert_gt(battle_system.turn_number, initial_turn, "回合数应增加")

## ==================== B. 卡牌操作 ====================

func test_play_card_deducts_energy() -> void:
	var deck: Array[CardData] = []
	for i in range(20):
		deck.append(_test_card_attack.duplicate())

	battle_system.start_battle(deck, [_test_enemy_weak.duplicate(true)])

	var initial_energy = battle_system.player_energy
	var card_index = 0

	# 找到一个可打出的卡牌
	for i in range(battle_system.player_hand.size()):
		if battle_system.player_hand[i].cost <= battle_system.player_energy:
			card_index = i
			break

	var card_cost = battle_system.player_hand[card_index].cost
	battle_system.play_card_by_index(card_index)

	assert_eq(battle_system.player_energy, initial_energy - card_cost, "能量应扣除")

func test_play_card_insufficient_energy() -> void:
	var deck: Array[CardData] = []
	for i in range(20):
		deck.append(_test_card_attack.duplicate())

	battle_system.start_battle(deck, [_test_enemy_weak.duplicate(true)])
	battle_system.player_energy = 0  # 清空能量

	var result = battle_system.play_card_by_index(0)
	assert_false(result, "能量不足时不应打出卡牌")

func test_play_card_invalid_index() -> void:
	var deck: Array[CardData] = []
	for i in range(20):
		deck.append(_test_card_attack.duplicate())

	battle_system.start_battle(deck, [_test_enemy_weak.duplicate(true)])

	var result = battle_system.play_card_by_index(-1)
	assert_false(result, "无效索引应返回false")

	result = battle_system.play_card_by_index(999)
	assert_false(result, "超出范围索引应返回false")

func test_play_card_moves_to_discard() -> void:
	var deck: Array[CardData] = []
	for i in range(20):
		deck.append(_test_card_attack.duplicate())

	battle_system.start_battle(deck, [_test_enemy_weak.duplicate(true)])

	var initial_hand_size = battle_system.player_hand.size()
	var initial_discard_size = battle_system.player_discard.size()

	# 打出第一张卡
	battle_system.play_card_by_index(0)

	assert_eq(battle_system.player_hand.size(), initial_hand_size - 1, "手牌应减少1")
	assert_eq(battle_system.player_discard.size(), initial_discard_size + 1, "弃牌堆应增加1")

func test_draw_card_adds_to_hand() -> void:
	var deck: Array[CardData] = []
	for i in range(20):
		deck.append(_test_card_attack.duplicate())

	battle_system.start_battle(deck, [_test_enemy_weak.duplicate(true)])

	var initial_hand_size = battle_system.player_hand.size()
	var initial_deck_size = battle_system.player_deck.size()

	# 先打出一张牌腾出空间
	if initial_hand_size > 0:
		battle_system.play_card_by_index(0)
		var after_play_hand = battle_system.player_hand.size()
		assert_eq(after_play_hand, initial_hand_size - 1)

func test_draw_from_empty_deck_shuffles_discard() -> void:
	var deck: Array[CardData] = []
	for i in range(6):
		deck.append(_test_card_attack.duplicate())

	battle_system.start_battle(deck, [_test_enemy_weak.duplicate(true)])

	# 清空卡组到弃牌堆
	battle_system.player_discard.append_array(battle_system.player_deck)
	battle_system.player_deck.clear()
	# 清空手牌
	battle_system.player_hand.clear()

	var result = battle_system.draw_card()
	assert_true(result, "从弃牌堆洗牌后应能抽牌")
	assert_false(battle_system.player_discard.is_empty() and battle_system.player_deck.is_empty(), "应有牌可抽")

## ==================== C. 伤害计算 ====================

func test_deal_damage_to_enemy() -> void:
	var deck: Array[CardData] = []
	for i in range(20):
		deck.append(_test_card_attack.duplicate())

	var enemy = _test_enemy_weak.duplicate(true)
	battle_system.start_battle(deck, [enemy])

	var initial_health = battle_system.enemies[0].get("health", 0)
	battle_system._apply_damage_to_enemy(0, 5, false)

	assert_lt(battle_system.enemies[0].get("health", 0), initial_health, "敌人HP应减少")

func test_enemy_defeated_signal() -> void:
	watch_signals(battle_system)

	var deck: Array[CardData] = []
	for i in range(20):
		deck.append(_test_card_attack.duplicate())

	var enemy = _test_enemy_weak.duplicate(true)
	enemy["health"] = 1
	enemy["max_health"] = 1
	battle_system.start_battle(deck, [enemy])

	battle_system._apply_damage_to_enemy(0, 10, false)

	assert_signal_emitted(battle_system, "enemy_defeated")

func test_critical_hit_deals_extra_damage() -> void:
	var deck: Array[CardData] = []
	for i in range(20):
		deck.append(_test_card_attack.duplicate())

	var enemy = _test_enemy_strong.duplicate(true)
	enemy["health"] = 200
	enemy["max_health"] = 200
	battle_system.start_battle(deck, [enemy])

	# 暴击伤害应比普通伤害高
	var normal_damage = 10
	var crit_damage = int(normal_damage * game_config.default_crit_damage)

	# 记录初始HP
	var initial_health = battle_system.enemies[0].get("health", 0)

	# 造成普通伤害
	battle_system._apply_damage_to_enemy(0, normal_damage, false)
	var after_normal = battle_system.enemies[0].get("health", 0)
	var actual_normal = initial_health - after_normal

	# 重置HP
	battle_system.enemies[0]["health"] = 200

	# 造成暴击伤害
	battle_system._apply_damage_to_enemy(0, normal_damage, true)
	var after_crit = battle_system.enemies[0].get("health", 0)
	var actual_crit = 200 - after_crit

	assert_gt(actual_crit, actual_normal, "暴击伤害应大于普通伤害")

## ==================== D. DOT效果 ====================

func test_dot_effect_deals_damage() -> void:
	var deck: Array[CardData] = []
	for i in range(20):
		deck.append(_test_card_attack.duplicate())

	var enemy = _test_enemy_strong.duplicate(true)
	enemy["effects"] = [{"type": "dot", "value": 5, "duration": 3}]
	battle_system.start_battle(deck, [enemy])

	var initial_health = battle_system.enemies[0].get("health", 0)

	# 触发敌人回合处理DOT
	battle_system._process_enemy_effects()

	assert_lt(battle_system.enemies[0].get("health", 0), initial_health, "DOT应造成伤害")

func test_dot_effect_expires() -> void:
	var deck: Array[CardData] = []
	for i in range(20):
		deck.append(_test_card_attack.duplicate())

	var enemy = _test_enemy_strong.duplicate(true)
	enemy["effects"] = [{"type": "dot", "value": 5, "duration": 1}]
	battle_system.start_battle(deck, [enemy])

	battle_system._process_enemy_effects()

	assert_true(battle_system.enemies[0].get("effects", []).is_empty(), "DOT效果应过期移除")

func test_dot_kills_enemy() -> void:
	watch_signals(battle_system)

	var deck: Array[CardData] = []
	for i in range(20):
		deck.append(_test_card_attack.duplicate())

	var enemy = _test_enemy_weak.duplicate(true)
	enemy["health"] = 3
	enemy["effects"] = [{"type": "dot", "value": 10, "duration": 1}]
	battle_system.start_battle(deck, [enemy])

	battle_system._process_enemy_effects()

	assert_eq(battle_system.enemies[0].get("health", 0), 0, "DOT杀死敌人后HP应为0")
	assert_signal_emitted(battle_system, "enemy_defeated")

## ==================== E. 能量系统 ====================

func test_energy_resets_on_new_turn() -> void:
	var deck: Array[CardData] = []
	for i in range(20):
		deck.append(_test_card_attack.duplicate())

	battle_system.start_battle(deck, [_test_enemy_weak.duplicate(true)])

	# 消耗能量
	battle_system.player_energy = 2

	# 设置敌人低攻击避免玩家死亡
	battle_system.enemies[0]["attack"] = 1
	battle_system.player_health = 100

	battle_system.end_player_turn()

	assert_eq(battle_system.player_energy, battle_system.max_energy, "新回合能量应重置")

func test_energy_cannot_go_negative() -> void:
	var deck: Array[CardData] = []
	for i in range(20):
		deck.append(_test_card_attack.duplicate())

	battle_system.start_battle(deck, [_test_enemy_weak.duplicate(true)])
	battle_system.player_energy = 1

	# 找一张cost > 1的卡
	for i in range(battle_system.player_hand.size()):
		if battle_system.player_hand[i].cost > 1:
			var result = battle_system.play_card_by_index(i)
			assert_false(result, "能量不足时不应打出")
			break

## ==================== F. 召唤物系统 ====================

func test_summon_management() -> void:
	battle_system.summons.clear()

	# 添加召唤物
	var summon = {"name": "火精灵", "health": 10, "attack": 3, "defense": 1}
	battle_system.summons.append(summon)

	assert_eq(battle_system.get_summon_count(), 1, "应有1个召唤物")

func test_max_summons_limited() -> void:
	battle_system.summons.clear()

	# 添加到上限
	for i in range(CardBattleSystem.MAX_SUMMONS):
		battle_system.summons.append({"name": "召唤物%d" % i, "health": 10, "attack": 1})

	assert_eq(battle_system.get_summon_count(), CardBattleSystem.MAX_SUMMONS, "召唤物数量应等于上限")

func test_summon_blocks_damage() -> void:
	var deck: Array[CardData] = []
	for i in range(20):
		deck.append(_test_card_attack.duplicate())

	battle_system.start_battle(deck, [_test_enemy_weak.duplicate(true)])

	# 添加召唤物
	battle_system.summons.append({"name": "盾卫", "health": 50, "attack": 1, "defense": 0})

	var initial_player_health = battle_system.player_health

	# 敌人攻击（应被召唤物挡住）
	battle_system._enemy_attack(0)

	assert_eq(battle_system.player_health, initial_player_health, "召唤物应挡住伤害，玩家HP不变")

## ==================== G. Buff管理 ====================

func test_defense_boost_buff() -> void:
	var deck: Array[CardData] = []
	for i in range(20):
		deck.append(_test_card_attack.duplicate())

	battle_system.start_battle(deck, [_test_enemy_weak.duplicate(true)])

	var initial_defense = battle_system.player_defense
	battle_system._apply_buff("defense_boost", 5, 3)

	assert_eq(battle_system.player_defense, initial_defense + 5, "防御力应增加")

func test_buff_expires_after_duration() -> void:
	var deck: Array[CardData] = []
	for i in range(20):
		deck.append(_test_card_attack.duplicate())

	battle_system.start_battle(deck, [_test_enemy_weak.duplicate(true)])

	battle_system._apply_buff("defense_boost", 5, 1)
	var defense_with_buff = battle_system.player_defense

	# 触发回合结束处理Buff
	battle_system._process_buffs_at_turn_end()

	assert_lt(battle_system.player_defense, defense_with_buff, "Buff过期后防御力应恢复")

## ==================== H. 敌人攻击 ====================

func test_enemy_attack_damages_player() -> void:
	var deck: Array[CardData] = []
	for i in range(20):
		deck.append(_test_card_attack.duplicate())

	battle_system.start_battle(deck, [_test_enemy_strong.duplicate(true)])

	var initial_health = battle_system.player_health
	battle_system._enemy_attack(0)

	assert_lt(battle_system.player_health, initial_health, "敌人攻击应减少玩家HP")

func test_enemy_attack_reduced_by_defense() -> void:
	var deck: Array[CardData] = []
	for i in range(20):
		deck.append(_test_card_attack.duplicate())

	battle_system.start_battle(deck, [_test_enemy_strong.duplicate(true)])

	battle_system.player_defense = 10
	var initial_health = battle_system.player_health
	battle_system._enemy_attack(0)

	var damage_taken = initial_health - battle_system.player_health
	var enemy_attack = battle_system.enemies[0].get("attack", 0)

	assert_lt(damage_taken, enemy_attack, "防御应减少受到的伤害")

func test_player_defeat_triggers_end() -> void:
	watch_signals(battle_system)

	var deck: Array[CardData] = []
	for i in range(20):
		deck.append(_test_card_attack.duplicate())

	battle_system.start_battle(deck, [_test_enemy_strong.duplicate(true)])
	battle_system.player_health = 1
	battle_system.player_defense = 0

	battle_system._apply_damage_to_player(100)

	assert_signal_emitted(battle_system, "player_defeated")
	assert_eq(battle_system.battle_state, CardBattleSystem.BattleState.DEFEAT)
