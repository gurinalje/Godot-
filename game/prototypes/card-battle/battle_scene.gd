# PROTOTYPE - NOT FOR PRODUCTION
# Question: 卡牌战斗系统的"爽快感"是否可行？
# Date: 2026-06-03

extends Node2D

# 战斗状态
enum BattleState { PLAYER_TURN, PLAYER_ACTION, CARD_PLAYED, ENEMY_TURN, TURN_END, BATTLE_WIN, BATTLE_LOSE }

var current_state: BattleState = BattleState.PLAYER_TURN
var player_hp: int = 50
var player_max_hp: int = 50
var player_energy: int = 3
var player_max_energy: int = 3
var enemy_hp: int = 30
var enemy_max_hp: int = 30

# 手牌
var hand: Array[Dictionary] = []
var deck: Array[Dictionary] = []
var discard: Array[Dictionary] = []

# 卡牌定义
var cards: Array[Dictionary] = [
	{"id": "strike", "name": "打击", "type": "attack", "cost": 1, "value": 6, "description": "造成6点伤害"},
	{"id": "defend", "name": "防御", "type": "defense", "cost": 1, "value": 5, "description": "获得5点护甲"},
	{"id": "fireball", "name": "火球术", "type": "attack", "cost": 2, "value": 10, "description": "造成10点火焰伤害"},
	{"id": "heal", "name": "治疗", "type": "heal", "cost": 1, "value": 5, "description": "恢复5点生命"},
	{"id": "combo", "name": "连击", "type": "attack", "cost": 1, "value": 3, "description": "造成3点伤害，可连锁"}
]

# 状态
var player_armor: int = 0
var combo_count: int = 0

# UI引用
@onready var player_hp_label: Label = $UI/PlayerHP
@onready var player_energy_label: Label = $UI/PlayerEnergy
@onready var enemy_hp_label: Label = $UI/EnemyHP
@onready var hand_container: HBoxContainer = $UI/HandContainer
@onready var end_turn_button: Button = $UI/EndTurnButton
@onready var message_label: Label = $UI/MessageLabel
@onready var damage_label: Label = $UI/DamageLabel

func _ready():
	_init_deck()
	_start_battle()
	end_turn_button.pressed.connect(_on_end_turn_pressed)

func _init_deck():
	deck.clear()
	for card in cards:
		deck.append(card.duplicate())
	deck.shuffle()

func _start_battle():
	player_hp = player_max_hp
	enemy_hp = enemy_max_hp
	player_energy = player_max_energy
	player_armor = 0
	combo_count = 0
	hand.clear()
	discard.clear()
	
	_draw_cards(5)
	_update_ui()
	_change_state(BattleState.PLAYER_TURN)
	_show_message("战斗开始！")

func _draw_cards(count: int):
	for i in range(count):
		if deck.is_empty():
			# 洗牌弃牌堆
			deck = discard.duplicate()
			deck.shuffle()
			discard.clear()
		
		if not deck.is_empty():
			hand.append(deck.pop_front())
	
	_update_hand_ui()

func _play_card(card_index: int):
	if card_index < 0 or card_index >= hand.size():
		return
	
	var card = hand[card_index]
	
	if player_energy < card.cost:
		_show_message("能量不足！")
		return
	
	player_energy -= card.cost
	
	# 执行卡牌效果
	match card.type:
		"attack":
			var damage = card.value
			if card.id == "combo":
				combo_count += 1
				damage = card.value * combo_count
				_show_combo(combo_count)
			else:
				combo_count = 0
			
			_deal_damage_to_enemy(damage)
			_show_damage(damage, false)
		
		"defense":
			player_armor += card.value
			_show_message("获得 %d 护甲" % card.value)
		
		"heal":
			player_hp = min(player_hp + card.value, player_max_hp)
			_show_message("恢复 %d 生命" % card.value)
	
	# 移除手牌
	hand.remove_at(card_index)
	discard.append(card)
	
	_update_ui()
	_update_hand_ui()
	
	# 检查胜负
	if enemy_hp <= 0:
		_change_state(BattleState.BATTLE_WIN)
		_show_message("胜利！")

func _deal_damage_to_enemy(damage: int):
	enemy_hp = max(enemy_hp - damage, 0)

func _deal_damage_to_player(damage: int):
	var actual_damage = max(damage - player_armor, 0)
	player_armor = max(player_armor - damage, 0)
	player_hp = max(player_hp - actual_damage, 0)

func _on_end_turn_pressed():
	_change_state(BattleState.ENEMY_TURN)
	_enemy_turn()

func _enemy_turn():
	# 简单AI：随机攻击
	var damage = randi_range(5, 10)
	_deal_damage_to_player(damage)
	_show_damage(damage, true)
	_show_message("敌人造成 %d 伤害" % damage)
	
	await get_tree().create_timer(1.0).timeout
	
	if player_hp <= 0:
		_change_state(BattleState.BATTLE_LOSE)
		_show_message("失败！")
	else:
		_change_state(BattleState.TURN_END)
		_end_turn()

func _end_turn():
	player_energy = player_max_energy
	player_armor = 0
	combo_count = 0
	_draw_cards(2)
	_change_state(BattleState.PLAYER_TURN)
	_update_ui()

func _change_state(new_state: BattleState):
	current_state = new_state
	match new_state:
		BattleState.PLAYER_TURN:
			end_turn_button.disabled = false
		BattleState.ENEMY_TURN:
			end_turn_button.disabled = true
		BattleState.BATTLE_WIN:
			end_turn_button.disabled = true
			_show_win_animation()
		BattleState.BATTLE_LOSE:
			end_turn_button.disabled = true
			_show_lose_animation()

func _update_ui():
	player_hp_label.text = "HP: %d/%d" % [player_hp, player_max_hp]
	player_energy_label.text = "能量: %d/%d" % [player_energy, player_max_energy]
	enemy_hp_label.text = "敌人 HP: %d/%d" % [enemy_hp, enemy_max_hp]

func _update_hand_ui():
	# 清除现有手牌UI
	for child in hand_container.get_children():
		child.queue_free()
	
	# 创建手牌UI
	for i in range(hand.size()):
		var card = hand[i]
		var button = Button.new()
		button.text = "%s\n费用: %d\n%s" % [card.name, card.cost, card.description]
		button.custom_minimum_size = Vector2(100, 150)
		
		# 根据卡牌类型设置颜色
		match card.type:
			"attack":
				button.modulate = Color(1, 0.8, 0.8)  # 红色
			"defense":
				button.modulate = Color(0.8, 0.8, 1)  # 蓝色
			"heal":
				button.modulate = Color(0.8, 1, 0.8)  # 绿色
		
		var index = i
		button.pressed.connect(func(): _play_card(index))
		hand_container.add_child(button)

func _show_message(text: String):
	message_label.text = text
	message_label.modulate = Color.WHITE
	var tween = create_tween()
	tween.tween_property(message_label, "modulate:a", 0.0, 2.0)

func _show_damage(amount: int, is_player: bool):
	damage_label.text = "-%d" % amount
	damage_label.modulate = Color.RED if not is_player else Color.ORANGE
	damage_label.position = Vector2(400, 200) if not is_player else Vector2(400, 400)
	damage_label.visible = true
	
	var tween = create_tween()
	tween.tween_property(damage_label, "position:y", damage_label.position.y - 50, 0.5)
	tween.parallel().tween_property(damage_label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func(): damage_label.visible = false)

func _show_combo(count: int):
	if count > 1:
		_show_message("COMBO x%d!" % count)
		# 屏幕震动
		var tween = create_tween()
		tween.tween_property($Camera2D, "offset", Vector2(5, 5), 0.05)
		tween.tween_property($Camera2D, "offset", Vector2(-5, -5), 0.05)
		tween.tween_property($Camera2D, "offset", Vector2.ZERO, 0.05)

func _show_win_animation():
	_show_message("胜利！获得奖励！")

func _show_lose_animation():
	_show_message("失败！请重试")
