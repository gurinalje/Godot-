## 卡牌战斗场景
## 核心战斗系统，处理卡牌对战逻辑

class_name CardBattle
extends Control

# 战斗状态
enum BattleState {
	INITIALIZING,
	PLAYER_TURN,
	ENEMY_TURN,
	VICTORY,
	DEFEAT
}

# 常量
const MAX_HAND_SIZE = 10
const MAX_ENERGY = 10
const DRAW_PER_TURN = 5

# 战斗状态
var current_state: BattleState = BattleState.INITIALIZING
var current_turn: int = 0
var player_energy: int = MAX_ENERGY
var player_max_energy: int = MAX_ENERGY

# 卡牌数据
var deck: Array[CardData] = []
var hand: Array[CardData] = []
var discard_pile: Array[CardData] = []

# 逃跑按钮引用
var flee_button: Button = null

# 玩家状态
var player_health: int = 100
var player_max_health: int = 100
var player_mana: int = 100
var player_max_mana: int = 100
var player_defense: int = 0
var active_buffs: Array[Dictionary] = []  # 当前激活的增益效果

# 敌人数据
var enemies: Array[Dictionary] = []
var current_enemy_index: int = 0

# 外部传入的敌人数据（从世界地图传入）
var enemy_data: Dictionary = {}

# 召唤物
var summons: Array[Dictionary] = []  # 当前场上的召唤物
const MAX_SUMMONS = 3  # 最多3个召唤物

# 打击感 - 屏幕震动
var shake_intensity: float = 0.0
var shake_decay: float = 5.0

# UI引用
@onready var player_health_bar: ProgressBar = $UI/PlayerHealthBar
@onready var player_mana_bar: ProgressBar = $UI/PlayerManaBar
@onready var energy_label: Label = $UI/EnergyLabel
@onready var hand_container: HBoxContainer = $UI/HandContainer
@onready var enemy_container: HBoxContainer = $UI/EnemyContainer
@onready var end_turn_button: Button = $UI/EndTurnButton
@onready var log_text: RichTextLabel = $UI/LogText

# 系统引用
var damage_calculator = null
var status_effect_manager = null
var combo_chain_manager = null
var element_system = null
var environment_manager = null
var summon_manager = null
var card_battle_system = null

# 信号
signal turn_started(turn_number: int)
signal turn_ended(turn_number: int)
signal card_played(card: CardData)
signal enemy_defeated(enemy_index: int)
signal battle_won()
signal battle_lost()
signal battle_fled()

func _ready() -> void:
	# 初始化系统
	_initialize_systems()
	
	# 初始化战斗
	_initialize_battle()
	
	# 连接信号
	_connect_signals()
	
	# 创建战斗UI覆盖层（回合指示器、提示等）
	_create_battle_overlay()
	
	# 动态创建与配置逃跑按钮
	_setup_flee_button()
	
	# 显示战斗开始提示
	_show_turn_indicator("战斗开始！")
	
	# 检查是否是第一次战斗，显示教程
	_check_and_show_tutorial()

func _process(delta: float) -> void:
	# 屏幕震动衰减
	if shake_intensity > 0:
		shake_intensity = max(0, shake_intensity - shake_decay * delta)
		var offset = Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
		$UI.position = offset
		if shake_intensity <= 0.1:
			$UI.position = Vector2.ZERO
			shake_intensity = 0.0

## 初始化系统
func _initialize_systems() -> void:
	damage_calculator = GameManager.get_system("DamageCalculator")
	status_effect_manager = GameManager.get_system("StatusEffectManager")
	combo_chain_manager = GameManager.get_system("ComboChainManager")
	element_system = GameManager.get_system("ElementSystem")
	environment_manager = GameManager.get_system("EnvironmentManager")
	summon_manager = GameManager.get_system("SummonManager")
	card_battle_system = GameManager.get_system("CardBattleSystem")

## 初始化战斗
func _initialize_battle() -> void:
	print("[CardBattle] Initializing battle...")
	
	# 初始化卡组
	_initialize_deck()
	
	# 初始化敌人
	_initialize_enemies()
	
	# 初始化玩家状态
	_initialize_player_state()
	
	# 开始第一回合
	_start_turn()

## 初始化卡组
func _initialize_deck() -> void:
	# 从卡组管理器获取卡组
	var deck_manager = get_node_or_null("/root/GameManager/DeckBuildingManager")
	if not deck_manager:
		deck_manager = get_node_or_null("/root/DeckBuildingManager")
	if deck_manager:
		deck = deck_manager.get_current_deck()
	else:
		# 使用默认卡组
		deck = _create_default_deck()
	
	# 洗牌
	deck.shuffle()
	
	print("[CardBattle] Deck initialized: ", deck.size(), " cards")

## 创建默认卡组
func _create_default_deck() -> Array[CardData]:
	var default_deck: Array[CardData] = []
	
	# 添加默认卡牌
	var card_database = get_node_or_null("/root/GameManager/CardDatabase")
	if not card_database:
		card_database = get_node_or_null("/root/CardDatabase")
	if card_database:
		# 添加攻击卡
		for i in range(5):
			var card = card_database.get_card("fireball")
			if card:
				default_deck.append(card)
		
		# 添加防御卡
		for i in range(3):
			var card = card_database.get_card("shield")
			if card:
				default_deck.append(card)
		
		# 添加治疗卡
		for i in range(2):
			var card = card_database.get_card("holy_blessing")
			if card:
				default_deck.append(card)
		
		# 添加测试道具卡（包括HP/MP消耗道具、无消耗道具、一次性道具）
		for item_id in ["item_health_potion", "item_rage_potion", "item_elixir"]:
			var card = card_database.get_card(item_id)
			if card:
				default_deck.append(card)
	
	return default_deck

## 初始化敌人
func _initialize_enemies() -> void:
	# 如果有外部传入的敌人数据，使用它
	if not enemy_data.is_empty():
		enemies = [enemy_data.duplicate()]
		# 确保有max_health
		if not enemies[0].has("max_health"):
			enemies[0]["max_health"] = enemies[0].get("health", 50)
	else:
		# 使用默认敌人数据
		enemies = [
			{
				"id": "skeleton",
				"name": "骷髅战士",
				"health": 50,
				"max_health": 50,
				"attack": 8,
				"defense": 3,
				"element": "earth"
			}
		]
	
	# 创建敌人UI
	_create_enemy_ui()
	
	# 判定当前战斗是否包含 Boss，若有则禁用逃跑按钮并文字提示
	var is_boss_battle = false
	for enemy in enemies:
		if enemy.get("is_boss", false):
			is_boss_battle = true
			break
	if is_boss_battle and flee_button:
		flee_button.disabled = true
		flee_button.text = "无法逃跑"

## 创建敌人UI
func _create_enemy_ui() -> void:
	# 清除现有敌人UI
	for child in enemy_container.get_children():
		child.queue_free()
	
	# 创建敌人UI
	for i in range(enemies.size()):
		var enemy = enemies[i]
		
		# 创建敌人容器
		var enemy_ui = VBoxContainer.new()
		enemy_ui.name = "Enemy" + str(i)
		
		# 创建敌人精灵（程序化生成占位符）
		var sprite = TextureRect.new()
		sprite.texture = _create_enemy_placeholder(enemy.get("element", "none"))
		sprite.custom_minimum_size = Vector2(128, 128)
		sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		enemy_ui.add_child(sprite)
		
		# 创建生命值条
		var health_bar = ProgressBar.new()
		health_bar.name = "HealthBar"
		health_bar.value = enemy.get("health", 0)
		health_bar.max_value = enemy.get("max_health", 0)
		health_bar.custom_minimum_size = Vector2(128, 20)
		enemy_ui.add_child(health_bar)
		
		# 创建名称标签
		var name_label = Label.new()
		name_label.name = "NameLabel"
		name_label.text = enemy.get("name", "Enemy")
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		enemy_ui.add_child(name_label)
		
		# 添加到容器
		enemy_container.add_child(enemy_ui)

## 初始化玩家状态
func _initialize_player_state() -> void:
	# 从全局 GameManager 同步玩家的基础状态
	player_health = GameManager.player_health
	player_max_health = GameManager.player_max_health
	player_mana = GameManager.player_mana if "player_mana" in GameManager else 100
	player_max_mana = GameManager.player_max_mana if "player_max_mana" in GameManager else 100
	player_defense = GameManager.player_defense
	player_max_energy = MAX_ENERGY
	player_energy = player_max_energy
	
	# 更新UI
	_update_player_ui()

## 连接信号
func _connect_signals() -> void:
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	turn_started.connect(_on_turn_started)
	turn_ended.connect(_on_turn_ended)
	card_played.connect(_on_card_played)
	enemy_defeated.connect(_on_enemy_defeated)
	battle_won.connect(_on_battle_won)
	battle_lost.connect(_on_battle_lost)

## 开始回合
func _start_turn() -> void:
	current_turn += 1
	current_state = BattleState.PLAYER_TURN
	
	# 重置能量
	player_energy = player_max_energy
	
	# 抽牌
	_draw_cards(DRAW_PER_TURN)
	
	# 更新UI
	_update_player_ui()
	_update_hand_ui()
	
	# 发送回合开始信号
	turn_started.emit(current_turn)
	
	# 添加日志
	_add_log("回合 " + str(current_turn) + " 开始")
	
	# 显示回合指示
	_show_turn_indicator("你的回合 - 选择卡牌使用")

## 抽牌
func _draw_cards(count: int) -> void:
	for i in range(count):
		if hand.size() >= MAX_HAND_SIZE:
			break
		
		if deck.is_empty():
			# 从弃牌堆洗牌到卡组
			_shuffle_discard_to_deck()
		
		if not deck.is_empty():
			var card = deck.pop_front()
			hand.append(card)
	
	print("[CardBattle] Drew ", count, " cards. Hand size: ", hand.size())

## 从弃牌堆洗牌到卡组
func _shuffle_discard_to_deck() -> void:
	deck = discard_pile.duplicate()
	discard_pile.clear()
	deck.shuffle()
	_add_log("卡组已重新洗牌")

## 打出卡牌
func _play_card(card_index: int) -> void:
	if current_state != BattleState.PLAYER_TURN:
		_show_turn_indicator("现在不是你的回合！")
		return
	
	if card_index < 0 or card_index >= hand.size():
		return
	
	var card = hand[card_index]
	
	# 检查能量
	if card.cost > player_energy:
		_show_turn_indicator("能量不足！需要 " + str(card.cost) + " 能量")
		_shake_screen(3.0)  # 轻微震动提示
		return
	
	# 检查 HP 消耗（HP需要保留至少1点，不能扣到0）
	if card.hp_cost > 0 and player_health <= card.hp_cost:
		_show_turn_indicator("生命值不足！需要 " + str(card.hp_cost) + " 生命值")
		_shake_screen(3.0)
		return
	
	# 检查 MP 消耗
	if card.mp_cost > 0 and player_mana < card.mp_cost:
		_show_turn_indicator("魔法值不足！需要 " + str(card.mp_cost) + " 魔法值")
		_shake_screen(3.0)
		return
	
	# 消耗能量
	player_energy -= card.cost
	
	# 消耗 HP 与 MP
	if card.hp_cost > 0:
		player_health -= card.hp_cost
		_add_log("消耗了 " + str(card.hp_cost) + " 点生命值")
	if card.mp_cost > 0:
		player_mana -= card.mp_cost
		_add_log("消耗了 " + str(card.mp_cost) + " 点魔法值")
	
	# 执行卡牌效果
	_execute_card_effect(card)
	
	# 移动到弃牌堆，或者若是一次性卡牌则直接移出战斗手牌且不进弃牌堆
	hand.remove_at(card_index)
	if card.is_single_use:
		_add_log("道具「" + card.display_name + "」已被消耗销毁")
	else:
		discard_pile.append(card)
	
	# 发送卡牌打出信号
	card_played.emit(card)
	
	# 更新UI
	_update_player_ui()
	_update_hand_ui()
	
	# 添加日志
	_add_log("打出卡牌: " + card.display_name)
	
	# 打出卡牌的视觉反馈
	_shake_screen(5.0)  # 中等震动

## 创建敌人占位符精灵
func _create_enemy_placeholder(element: String) -> ImageTexture:
	var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	# 根据元素选择颜色
	var body_color = Color(0.6, 0.4, 0.3)  # 默认棕色
	match element:
		"fire": body_color = Color(0.9, 0.3, 0.2)
		"water": body_color = Color(0.2, 0.5, 0.9)
		"earth": body_color = Color(0.5, 0.4, 0.2)
		"wind": body_color = Color(0.6, 0.9, 0.6)
		"lightning": body_color = Color(0.9, 0.9, 0.3)
	
	# 绘制简单的敌人形状（方块化风格）
	# 身体
	for x in range(8, 24):
		for y in range(8, 24):
			image.set_pixel(x, y, body_color)
	
	# 眼睛（红色发光）
	for x in range(10, 14):
		for y in range(12, 16):
			image.set_pixel(x, y, Color.RED)
	for x in range(18, 22):
		for y in range(12, 16):
			image.set_pixel(x, y, Color.RED)
	
	# 暗边框
	var border_color = body_color.darkened(0.3)
	for x in range(8, 24):
		image.set_pixel(x, 8, border_color)
		image.set_pixel(x, 23, border_color)
	for y in range(8, 24):
		image.set_pixel(8, y, border_color)
		image.set_pixel(23, y, border_color)
	
	var texture = ImageTexture.create_from_image(image)
	return texture

## 创建卡牌占位符精灵
func _create_card_placeholder(card_type: CardEnums.CardType) -> ImageTexture:
	var image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	# 根据卡牌类型选择颜色
	var card_color = _get_card_color(card_type)
	
	# 绘制卡牌背景
	for x in range(2, 62):
		for y in range(2, 62):
			image.set_pixel(x, y, card_color)
	
	# 绘制白色边框
	for x in range(60):
		image.set_pixel(x, 1, Color.WHITE)
		image.set_pixel(x, 62, Color.WHITE)
	for y in range(62):
		image.set_pixel(1, y, Color.WHITE)
		image.set_pixel(62, y, Color.WHITE)
	
	var texture = ImageTexture.create_from_image(image)
	return texture

## 执行卡牌效果
func _execute_card_effect(card: CardData) -> void:
	# 根据卡牌类型执行效果
	match card.card_type:
		CardEnums.CardType.DIRECT_DAMAGE:
			_execute_damage_card(card)
		CardEnums.CardType.SUMMON:
			_execute_summon_card(card)
		CardEnums.CardType.ENVIRONMENT:
			_execute_environment_card(card)
		CardEnums.CardType.BUFF_DEBUFF:
			_execute_buff_card(card)

## 执行伤害卡牌
func _execute_damage_card(card: CardData) -> void:
	# 获取目标敌人
	var target = _get_current_target()
	if not target:
		return
	
	# 计算伤害
	var damage = _calculate_damage(card, target)
	
	# 应用伤害
	_apply_damage_to_enemy(current_enemy_index, damage)
	
	# 添加日志
	_add_log("对 " + target.get("name", "敌人") + " 造成 " + str(damage) + " 点伤害")
	
	# 打击感：浮动伤害数字
	_show_floating_damage(damage, current_enemy_index, false)
	
	# 打击感：敌人闪白
	_flash_enemy(current_enemy_index)
	
	# 打击感：屏幕震动
	_shake_screen(8.0)

## 执行召唤卡牌
func _execute_summon_card(card: CardData) -> void:
	if summons.size() >= MAX_SUMMONS:
		_add_log("场上召唤物已满！最多 " + str(MAX_SUMMONS) + " 个")
		return
	
	# 从卡牌效果中获取召唤物属性
	var summon_health = 10
	var summon_attack = 5
	var summon_name = "召唤物"
	
	for effect in card.effects:
		match effect.effect_type:
			CardEnums.EffectType.SUMMON:
				summon_health = effect.value
				summon_attack = effect.secondary_value if "secondary_value" in effect else 5
	
	# 创建召唤物
	var summon = {
		"name": summon_name,
		"health": summon_health,
		"max_health": summon_health,
		"attack": summon_attack
	}
	summons.append(summon)
	
	# 更新UI
	_update_summons_ui()
	_add_log("召唤了 " + summon_name + "（HP:" + str(summon_health) + " 攻击:" + str(summon_attack) + "）")

## 执行环境卡牌
func _execute_environment_card(card: CardData) -> void:
	# 从卡牌效果中获取环境效果
	var effect_type = ""
	var effect_value = 0
	var effect_duration = 3
	
	for effect in card.effects:
		match effect.effect_type:
			CardEnums.EffectType.ENVIRONMENT_CHANGE:
				effect_type = "damage_over_time"
				effect_value = effect.value
				effect_duration = effect.duration if "duration" in effect else 3
	
	# 应用环境效果（对所有敌人造成持续伤害）
	if effect_type == "damage_over_time":
		for i in range(enemies.size()):
			var enemy = enemies[i]
			if enemy.get("health", 0) > 0:
				# 添加持续伤害效果
				var dot_effect = {
					"type": "dot",
					"value": effect_value,
					"duration": effect_duration
				}
				if not enemy.has("effects"):
					enemy["effects"] = []
				enemy["effects"].append(dot_effect)
		
		_add_log("施放环境效果：" + card.display_name + "，持续 " + str(effect_duration) + " 回合")
	else:
		_add_log("使用环境卡牌：" + card.display_name)

## 执行增益卡牌
func _execute_buff_card(card: CardData) -> void:
	# 从卡牌效果中获取增益属性
	var buff_type = "heal"
	var buff_value = 0
	var buff_duration = 1
	
	for effect in card.effects:
		match effect.effect_type:
			CardEnums.EffectType.HEAL:
				buff_type = "heal"
				buff_value = effect.value
			CardEnums.EffectType.BUFF:
				buff_type = "attack_boost"
				buff_value = effect.value
				buff_duration = effect.duration if "duration" in effect else 3
			CardEnums.EffectType.DEBUFF:
				buff_type = "defense_boost"
				buff_value = effect.value
				buff_duration = effect.duration if "duration" in effect else 3
	
	# 应用增益效果
	_apply_buff(buff_type, buff_value, buff_duration)
	_add_log("使用增益卡牌：" + card.display_name)

## 计算伤害
func _calculate_damage(card: CardData, target: Dictionary) -> int:
	# 从卡牌效果中获取基础伤害
	var base_damage = 0
	for effect in card.effects:
		if effect.effect_type == CardEnums.EffectType.DAMAGE:
			base_damage = effect.value
			break
	
	if base_damage == 0:
		base_damage = card.cost * 5  # 默认伤害公式
	
	# 召唤物攻击加成
	var summon_bonus = 0
	for summon in summons:
		summon_bonus += summon["attack"] / 2  # 召唤物提供一半攻击力加成
	
	base_damage += summon_bonus
	
	# 如果有伤害计算器，使用它
	if damage_calculator:
		var result = damage_calculator.calculate_damage(
			base_damage,
			card.element,
			target.get("element", "none"),
			target.get("defense", 0),
			1.0,  # 暴击率
			1.0   # 暴击伤害
		)
		return result.get("final_damage", base_damage)
	
	# 简单伤害计算：基础伤害 - 敌人防御
	var defense = target.get("defense", 0)
	return max(1, base_damage - defense)

## 获取当前目标
func _get_current_target() -> Dictionary:
	if current_enemy_index >= 0 and current_enemy_index < enemies.size():
		return enemies[current_enemy_index]
	return {}

## 对敌人造成伤害
func _apply_damage_to_enemy(enemy_index: int, damage: int) -> void:
	if enemy_index < 0 or enemy_index >= enemies.size():
		return
	
	enemies[enemy_index]["health"] -= damage
	
	# 检查敌人是否死亡
	if enemies[enemy_index]["health"] <= 0:
		enemies[enemy_index]["health"] = 0
		_on_enemy_defeated(enemy_index)
	
	# 更新敌人UI
	_update_enemy_ui()

## 应用增益效果
func _apply_buff(buff_type: String, value: int, duration: int) -> void:
	var buff = {
		"type": buff_type,
		"value": value,
		"duration": duration
	}
	active_buffs.append(buff)
	
	match buff_type:
		"attack_boost":
			# 临时增加攻击力（在伤害计算时应用）
			_add_log("攻击力提升 " + str(value) + " 点，持续 " + str(duration) + " 回合")
			_show_turn_indicator("攻击力 +" + str(value))
		"defense_boost":
			player_defense += value
			_add_log("防御力提升 " + str(value) + " 点，持续 " + str(duration) + " 回合")
			_show_turn_indicator("防御力 +" + str(value))
		"heal":
			var old_health = player_health
			player_health = min(player_max_health, player_health + value)
			var healed = player_health - old_health
			_add_log("恢复 " + str(healed) + " 点生命值")
			# 打击感：治疗浮动数字（绿色）
			_show_floating_heal(healed)
			_show_turn_indicator("恢复 " + str(healed) + " HP")

## 处理回合结束时的buff持续时间
func _process_buffs_at_turn_end() -> void:
	var buffs_to_remove: Array[int] = []
	for i in range(active_buffs.size()):
		active_buffs[i]["duration"] -= 1
		if active_buffs[i]["duration"] <= 0:
			buffs_to_remove.append(i)
	
	# 移除过期的buff（从后往前移除以保持索引正确）
	buffs_to_remove.reverse()
	for index in buffs_to_remove:
		var buff = active_buffs[index]
		match buff["type"]:
			"defense_boost":
				player_defense -= buff["value"]
		active_buffs.remove_at(index)

## 结束回合
func _end_turn() -> void:
	current_state = BattleState.ENEMY_TURN
	
	# 处理buff持续时间
	_process_buffs_at_turn_end()
	
	# 发送回合结束信号
	turn_ended.emit(current_turn)
	
	# 执行敌人回合
	_execute_enemy_turn()

## 执行敌人回合
func _execute_enemy_turn() -> void:
	_add_log("敌人回合开始")
	_show_turn_indicator("敌人回合...")
	
	# 对每个敌人执行行动
	for i in range(enemies.size()):
		var enemy = enemies[i]
		if enemy.get("health", 0) <= 0:
			continue
		
		# 敌人攻击
		_enemy_attack(i)
	
	# 检查战斗结果
	_check_battle_result()
	
	# 开始新回合（如果战斗还在继续）
	if current_state != BattleState.VICTORY and current_state != BattleState.DEFEAT:
		_start_turn()

## 敌人攻击
func _enemy_attack(enemy_index: int) -> void:
	if enemy_index < 0 or enemy_index >= enemies.size():
		return
	
	var enemy = enemies[enemy_index]
	var damage = enemy.get("attack", 0)
	
	# 检查是否有召唤物可以挡伤害
	if summons.size() > 0:
		var summon = summons[0]  # 第一个召唤物挡伤害
		summon["health"] -= damage
		_add_log(enemy.get("name", "敌人") + " 攻击召唤物 " + summon["name"] + "，造成 " + str(damage) + " 点伤害")
		
		# 打击感：召唤物受伤
		_shake_screen(5.0)
		
		# 检查召唤物是否死亡
		if summon["health"] <= 0:
			_add_log(summon["name"] + " 被击败！")
			summons.remove_at(0)
			_update_summons_ui()
			_show_turn_indicator(summon["name"] + " 被击败！")
	else:
		# 没有召唤物，直接攻击玩家
		_apply_damage_to_player(damage)
		_add_log(enemy.get("name", "敌人") + " 攻击造成 " + str(damage) + " 点伤害")
		_show_turn_indicator(enemy.get("name", "敌人") + " 发动攻击！")

## 对玩家造成伤害
func _apply_damage_to_player(damage: int) -> void:
	# 计算实际伤害（考虑防御）
	var actual_damage = max(1, damage - player_defense)
	player_health -= actual_damage
	
	# 检查玩家是否死亡
	if player_health <= 0:
		player_health = 0
		_on_player_defeated()
	
	# 更新UI
	_update_player_ui()
	_add_log("玩家受到 " + str(actual_damage) + " 点伤害")
	
	# 打击感：玩家受伤浮动数字
	_show_floating_damage(actual_damage, -1, true)
	
	# 打击感：强烈屏幕震动
	_shake_screen(12.0)
	
	# 打击感：屏幕闪红
	_flash_screen_damage()

## 玩家失败
func _on_player_defeated() -> void:
	current_state = BattleState.DEFEAT
	_add_log("你被击败了...")
	_on_battle_lost()

## 检查战斗结果
func _check_battle_result() -> void:
	# 检查是否所有敌人都被击败
	var all_defeated = true
	for enemy in enemies:
		if enemy.get("health", 0) > 0:
			all_defeated = false
			break
	
	if all_defeated:
		_on_battle_won()
		return
	
	# 检查玩家是否死亡
	if player_health <= 0:
		_on_player_defeated()

## 更新玩家UI
func _update_player_ui() -> void:
	# 更新能量显示
	if energy_label:
		energy_label.text = "能量: " + str(player_energy) + "/" + str(player_max_energy)
	
	# 更新生命值条
	if player_health_bar:
		player_health_bar.value = player_health
		player_health_bar.max_value = player_max_health
		
	# 更新魔法值条
	if player_mana_bar:
		player_mana_bar.value = player_mana
		player_mana_bar.max_value = player_max_mana

## 更新手牌UI
func _update_hand_ui() -> void:
	# 清除现有手牌UI
	for child in hand_container.get_children():
		child.queue_free()
	
	# 动态调整手牌间距以防多张手牌超出屏幕
	var num_cards = hand.size()
	var base_separation = 20
	if num_cards > 5:
		# 手牌数多于5张时，采用负的间距让卡牌相互叠加显示（最大重叠-80像素）
		base_separation = max(-80, 20 - (num_cards - 5) * 20)
	hand_container.add_theme_constant_override("separation", base_separation)
	
	# 创建手牌UI
	for i in range(hand.size()):
		var card = hand[i]
		var card_ui = _create_card_ui(card, i)
		hand_container.add_child(card_ui)

## 创建卡牌UI
func _create_card_ui(card: CardData, index: int) -> Control:
	# 创建卡牌容器（带边框效果）
	var card_panel = PanelContainer.new()
	card_panel.name = "Card" + str(index)
	card_panel.custom_minimum_size = Vector2(140, 200)
	
	# 设置卡牌样式（带颜色边框的面板）
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2, 0.95)
	style.border_color = _get_card_color(card.card_type)
	style.set_border_width_all(3)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(6)
	card_panel.add_theme_stylebox_override("panel", style)
	
	# 内部垂直布局
	var card_container = VBoxContainer.new()
	card_container.name = "CardContent"
	card_panel.add_child(card_container)
	
	# 卡牌类型图标（程序化生成）
	var icon = TextureRect.new()
	icon.texture = _create_card_placeholder(card.card_type)
	icon.custom_minimum_size = Vector2(48, 48)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	card_container.add_child(icon)
	
	# 卡牌名称（带颜色标识）
	var name_label = Label.new()
	name_label.text = card.display_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", _get_card_color(card.card_type))
	card_container.add_child(name_label)
	
	# 卡牌费用（金色显示）
	var cost_label = Label.new()
	cost_label.text = "⚡ " + str(card.cost)
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_label.add_theme_font_size_override("font_size", 12)
	cost_label.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	card_container.add_child(cost_label)
	
	# 卡牌效果摘要
	var effect_label = Label.new()
	effect_label.text = _get_card_effect_summary(card)
	effect_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	effect_label.add_theme_font_size_override("font_size", 10)
	effect_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	card_container.add_child(effect_label)
	
	# 添加弹性空间
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card_container.add_child(spacer)
	
	# 添加点击事件按钮
	var button = Button.new()
	button.text = "使用"
	button.custom_minimum_size = Vector2(0, 30)
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = _get_card_color(card.card_type).darkened(0.3)
	btn_style.set_corner_radius_all(4)
	button.add_theme_stylebox_override("normal", btn_style)
	var btn_hover = StyleBoxFlat.new()
	btn_hover.bg_color = _get_card_color(card.card_type)
	btn_hover.set_corner_radius_all(4)
	button.add_theme_stylebox_override("hover", btn_hover)
	button.pressed.connect(_on_card_clicked.bind(index))
	card_container.add_child(button)
	
	return card_panel

## 获取卡牌效果摘要
func _get_card_effect_summary(card: CardData) -> String:
	var summary = ""
	for effect in card.effects:
		match effect.effect_type:
			CardEnums.EffectType.DAMAGE:
				summary = "伤害: " + str(effect.value)
			CardEnums.EffectType.HEAL:
				summary = "治疗: " + str(effect.value)
			CardEnums.EffectType.BUFF:
				summary = "增益 +" + str(effect.value)
			CardEnums.EffectType.DEBUFF:
				summary = "减益 " + str(effect.value)
			CardEnums.EffectType.SUMMON:
				summary = "召唤 HP:" + str(effect.value)
			CardEnums.EffectType.ENVIRONMENT_CHANGE:
				summary = "环境: " + str(effect.value) + "/回合"
	if summary.is_empty():
		summary = card.description.substr(0, 20) if card.description.length() > 0 else "无效果"
	return summary

## 获取卡牌颜色
func _get_card_color(card_type: CardEnums.CardType) -> Color:
	match card_type:
		CardEnums.CardType.DIRECT_DAMAGE:
			return Color(0.9, 0.2, 0.2, 0.8)  # 红色
		CardEnums.CardType.SUMMON:
			return Color(0.5, 0.3, 0.8, 0.8)  # 紫色
		CardEnums.CardType.ENVIRONMENT:
			return Color(0.2, 0.7, 0.4, 0.8)  # 绿色
		CardEnums.CardType.BUFF_DEBUFF:
			return Color(0.9, 0.7, 0.1, 0.8)  # 金色
		_:
			return Color(0.5, 0.5, 0.5, 0.8)  # 灰色

## 更新敌人UI
func _update_enemy_ui() -> void:
	for i in range(enemies.size()):
		var enemy = enemies[i]
		var enemy_ui = enemy_container.get_node_or_null("Enemy" + str(i))
		if not enemy_ui:
			continue
		
		# 更新生命值条
		var health_bar = enemy_ui.get_node_or_null("HealthBar")
		if health_bar:
			health_bar.value = enemy.get("health", 0)
			health_bar.max_value = enemy.get("max_health", 0)

## 更新召唤物UI
func _update_summons_ui() -> void:
	# 在敌人容器下方显示召唤物
	var summons_container = enemy_container.get_node_or_null("SummonsContainer")
	if not summons_container:
		summons_container = VBoxContainer.new()
		summons_container.name = "SummonsContainer"
		enemy_container.add_child(summons_container)
	
	# 清除现有召唤物UI
	for child in summons_container.get_children():
		child.queue_free()
	
	# 创建召唤物UI
	for i in range(summons.size()):
		var summon = summons[i]
		var summon_ui = HBoxContainer.new()
		summon_ui.name = "Summon" + str(i)
		
		# 召唤物名称
		var name_label = Label.new()
		name_label.text = summon["name"]
		summon_ui.add_child(name_label)
		
		# 召唤物生命值
		var health_label = Label.new()
		health_label.text = " HP:" + str(summon["health"]) + "/" + str(summon["max_health"])
		summon_ui.add_child(health_label)
		
		# 召唤物攻击
		var attack_label = Label.new()
		attack_label.text = " 攻:" + str(summon["attack"])
		summon_ui.add_child(attack_label)
		
		summons_container.add_child(summon_ui)

## 添加日志
func _add_log(message: String) -> void:
	if log_text:
		log_text.add_text(message + "\n")
		log_text.scroll_to_line(log_text.get_line_count() - 1)

## 卡牌点击事件
func _on_card_clicked(index: int) -> void:
	_play_card(index)

## 结束回合按钮事件
func _on_end_turn_pressed() -> void:
	_end_turn()

## 回合开始事件
func _on_turn_started(turn_number: int) -> void:
	print("[CardBattle] Turn ", turn_number, " started")

## 回合结束事件
func _on_turn_ended(turn_number: int) -> void:
	print("[CardBattle] Turn ", turn_number, " ended")

## 卡牌打出事件
func _on_card_played(card: CardData) -> void:
	print("[CardBattle] Card played: ", card.display_name)

## 敌人击败事件
func _on_enemy_defeated(enemy_index: int) -> void:
	print("[CardBattle] Enemy defeated: ", enemy_index)
	var enemy_name = enemies[enemy_index].get("name", "敌人")
	_add_log(enemy_name + " 被击败！")
	_show_turn_indicator(enemy_name + " 被击败！")
	
	# 击败震动
	_shake_screen(10.0)

## 战斗胜利事件
func _on_battle_won() -> void:
	current_state = BattleState.VICTORY
	_add_log("战斗胜利！")
	print("[CardBattle] Battle won!")
	_show_battle_result(true)

## 战斗失败事件
func _on_battle_lost() -> void:
	current_state = BattleState.DEFEAT
	_add_log("战斗失败...")
	print("[CardBattle] Battle lost!")
	_show_battle_result(false)

## ============ 打击感和提示系统 ============

## 创建战斗覆盖层UI
func _create_battle_overlay() -> void:
	# 创建覆盖层容器
	var overlay = Control.new()
	overlay.name = "BattleOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.z_index = 50
	$UI.add_child(overlay)
	
	# 回合指示器（顶部居中）
	var turn_indicator = Label.new()
	turn_indicator.name = "TurnIndicator"
	turn_indicator.set_anchors_preset(Control.PRESET_CENTER_TOP)
	turn_indicator.offset_left = -200
	turn_indicator.offset_top = 10
	turn_indicator.offset_right = 200
	turn_indicator.offset_bottom = 50
	turn_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	turn_indicator.add_theme_font_size_override("font_size", 20)
	turn_indicator.add_theme_color_override("font_color", Color(1, 1, 0.8))
	turn_indicator.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	turn_indicator.add_theme_constant_override("shadow_offset_x", 2)
	turn_indicator.add_theme_constant_override("shadow_offset_y", 2)
	turn_indicator.text = ""
	overlay.add_child(turn_indicator)
	
	# 操作提示面板（右上角）
	var hint_panel = PanelContainer.new()
	hint_panel.name = "HintPanel"
	hint_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	hint_panel.offset_left = -220
	hint_panel.offset_top = 20
	hint_panel.offset_right = -20
	hint_panel.offset_bottom = 170
	hint_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hint_style = StyleBoxFlat.new()
	hint_style.bg_color = Color(0, 0, 0, 0.7)
	hint_style.border_color = Color(0.4, 0.4, 0.6, 0.5)
	hint_style.set_border_width_all(1)
	hint_style.set_corner_radius_all(6)
	hint_style.set_content_margin_all(10)
	hint_panel.add_theme_stylebox_override("panel", hint_style)
	overlay.add_child(hint_panel)
	
	var hint_label = RichTextLabel.new()
	hint_label.name = "HintLabel"
	hint_label.bbcode_enabled = true
	hint_label.fit_content = true
	hint_label.scroll_active = false
	hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_label.text = "[center][b]操作提示[/b][/center]\n点击卡牌 → 使用\n结束回合按钮 → 敌人行动\n击败所有敌人 → 胜利"
	hint_panel.add_child(hint_label)

## 检查并显示战斗教程（首次战斗时）
func _check_and_show_tutorial() -> void:
	# 检查是否是第一次战斗
	var game_manager = get_node_or_null("/root/GameManager")
	var is_first_battle = true
	
	if game_manager and game_manager.has_method("get"):
		is_first_battle = game_manager.get("first_battle_completed") != true
	
	if is_first_battle:
		# 显示详细教程
		_show_battle_tutorial()
		
		# 标记第一次战斗完成
		if game_manager and game_manager.has_method("set"):
			game_manager.set("first_battle_completed", true)

## 显示战斗教程
func _show_battle_tutorial() -> void:
	# 创建教程覆盖层
	var tutorial_overlay = ColorRect.new()
	tutorial_overlay.name = "TutorialOverlay"
	tutorial_overlay.color = Color(0, 0, 0, 0.8)
	tutorial_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	tutorial_overlay.z_index = 200
	$UI.add_child(tutorial_overlay)
	
	# 教程容器
	var tutorial_container = VBoxContainer.new()
	tutorial_container.name = "TutorialContainer"
	tutorial_container.set_anchors_preset(Control.PRESET_CENTER)
	tutorial_container.offset_left = -250
	tutorial_container.offset_top = -200
	tutorial_container.offset_right = 250
	tutorial_container.offset_bottom = 200
	tutorial_overlay.add_child(tutorial_container)
	
	# 教程标题
	var title = Label.new()
	title.text = "战斗教程"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1, 0.9, 0.2))
	tutorial_container.add_child(title)
	
	# 教程内容
	var tutorial_steps = [
		{"icon": "🃏", "text": "点击手牌中的卡牌来使用它"},
		{"icon": "⚡", "text": "每张卡牌需要消耗能量（左上角显示）"},
		{"icon": "⚔️", "text": "使用卡牌攻击敌人，造成伤害"},
		{"icon": "🛡️", "text": "使用护盾卡牌增加防御力"},
		{"icon": "💚", "text": "使用治疗卡牌恢复生命值"},
		{"icon": "🔄", "text": "点击「结束回合」让敌人行动"},
		{"icon": "🏆", "text": "击败所有敌人即可获得胜利！"}
	]
	
	for step in tutorial_steps:
		var step_container = HBoxContainer.new()
		step_container.add_theme_constant_override("separation", 10)
		
		# 图标
		var icon_label = Label.new()
		icon_label.text = step["icon"]
		icon_label.add_theme_font_size_override("font_size", 24)
		step_container.add_child(icon_label)
		
		# 说明文字
		var text_label = Label.new()
		text_label.text = step["text"]
		text_label.add_theme_font_size_override("font_size", 16)
		text_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
		step_container.add_child(text_label)
		
		tutorial_container.add_child(step_container)
	
	# 添加分隔符
	var separator = HSeparator.new()
	separator.add_theme_constant_override("separation", 20)
	tutorial_container.add_child(separator)
	
	# 提示文字
	var tip_label = Label.new()
	tip_label.text = "提示：合理搭配攻击和防御卡牌是胜利的关键！"
	tip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip_label.add_theme_font_size_override("font_size", 14)
	tip_label.add_theme_color_override("font_color", Color(0.7, 0.9, 0.7))
	tutorial_container.add_child(tip_label)
	
	# 开始战斗按钮
	var start_button = Button.new()
	start_button.text = "开始战斗！"
	start_button.custom_minimum_size = Vector2(200, 50)
	start_button.add_theme_font_size_override("font_size", 18)
	start_button.pressed.connect(_on_tutorial_closed.bind(tutorial_overlay))
	tutorial_container.add_child(start_button)

## 教程关闭回调
func _on_tutorial_closed(tutorial_overlay: ColorRect) -> void:
	# 淡出动画
	var tween = create_tween()
	tween.tween_property(tutorial_overlay, "modulate:a", 0.0, 0.5)
	tween.tween_callback(tutorial_overlay.queue_free)

## 显示回合指示器（带淡入淡出动画）
func _show_turn_indicator(text: String) -> void:
	var indicator = $UI.get_node_or_null("BattleOverlay/TurnIndicator")
	if not indicator:
		return
	
	indicator.text = text
	indicator.modulate.a = 1.0
	
	# 创建淡出动画
	var tween = create_tween()
	tween.tween_property(indicator, "modulate:a", 0.0, 2.0).set_delay(1.5)

## 显示浮动伤害数字（打击感核心）
func _show_floating_damage(damage: int, enemy_index: int, is_player_damage: bool) -> void:
	var damage_label = Label.new()
	damage_label.text = "-" + str(damage)
	damage_label.add_theme_font_size_override("font_size", 28)
	damage_label.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
	damage_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	damage_label.add_theme_constant_override("shadow_offset_x", 2)
	damage_label.add_theme_constant_override("shadow_offset_y", 2)
	damage_label.z_index = 60
	
	if is_player_damage:
		# 玩家受伤 - 显示在左上角
		damage_label.position = Vector2(120, 100)
	else:
		# 敌人受伤 - 显示在敌人位置附近
		var enemy_ui = enemy_container.get_node_or_null("Enemy" + str(enemy_index))
		if enemy_ui:
			damage_label.position = enemy_ui.position + Vector2(0, -30)
		else:
			damage_label.position = Vector2(512, 200)
	
	$UI.add_child(damage_label)
	
	# 创建浮动动画：向上飘动 + 缩放 + 淡出
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(damage_label, "position:y", damage_label.position.y - 60, 1.0)
	tween.tween_property(damage_label, "modulate:a", 0.0, 1.0).set_delay(0.5)
	tween.tween_property(damage_label, "scale", Vector2(1.5, 1.5), 0.2)
	tween.chain().tween_property(damage_label, "scale", Vector2(1.0, 1.0), 0.3)
	tween.chain().tween_callback(damage_label.queue_free)

## 显示浮动治疗数字
func _show_floating_heal(heal_amount: int) -> void:
	var heal_label = Label.new()
	heal_label.text = "+" + str(heal_amount)
	heal_label.add_theme_font_size_override("font_size", 28)
	heal_label.add_theme_color_override("font_color", Color(0.2, 1, 0.3))
	heal_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	heal_label.add_theme_constant_override("shadow_offset_x", 2)
	heal_label.add_theme_constant_override("shadow_offset_y", 2)
	heal_label.z_index = 60
	heal_label.position = Vector2(120, 80)
	$UI.add_child(heal_label)
	
	# 浮动动画
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(heal_label, "position:y", heal_label.position.y - 50, 1.0)
	tween.tween_property(heal_label, "modulate:a", 0.0, 1.0).set_delay(0.5)
	tween.chain().tween_callback(heal_label.queue_free)

## 屏幕震动效果
func _shake_screen(intensity: float) -> void:
	shake_intensity = intensity

## 敌人闪白效果（打击感）
func _flash_enemy(enemy_index: int) -> void:
	var enemy_ui = enemy_container.get_node_or_null("Enemy" + str(enemy_index))
	if not enemy_ui:
		return
	
	# 找到敌人精灵
	var sprite = null
	for child in enemy_ui.get_children():
		if child is TextureRect:
			sprite = child
			break
	
	if sprite:
		# 闪白效果
		var original_modulate = sprite.modulate
		sprite.modulate = Color(3, 3, 3, 1)  # 过曝白色
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", original_modulate, 0.3)

## 屏幕闪红效果（玩家受伤）
func _flash_screen_damage() -> void:
	# 创建红色闪屏
	var flash = ColorRect.new()
	flash.name = "DamageFlash"
	flash.color = Color(1, 0, 0, 0.3)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.z_index = 55
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$UI.add_child(flash)
	
	# 淡出动画
	var tween = create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.4)
	tween.tween_callback(flash.queue_free)

## 显示战斗结果界面
func _show_battle_result(is_victory: bool) -> void:
	# 创建结果覆盖层
	var overlay = ColorRect.new()
	overlay.name = "ResultOverlay"
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 100
	$UI.add_child(overlay)
	
	# 创建结果容器
	var container = VBoxContainer.new()
	container.name = "ResultContainer"
	container.set_anchors_preset(Control.PRESET_CENTER)
	container.offset_left = -150
	container.offset_top = -100
	container.offset_right = 150
	container.offset_bottom = 100
	overlay.add_child(container)
	
	# 结果标题
	var title = Label.new()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	if is_victory:
		title.text = "战斗胜利！"
		title.add_theme_color_override("font_color", Color(1, 0.9, 0.2))
	else:
		title.text = "战斗失败"
		title.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2))
	container.add_child(title)
	
	# 奖励信息（仅胜利时显示）
	if is_victory:
		var reward_label = Label.new()
		reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		reward_label.add_theme_font_size_override("font_size", 16)
		reward_label.text = "获得奖励！"
		container.add_child(reward_label)
	
	# 返回按钮
	var return_button = Button.new()
	return_button.text = "返回探索"
	return_button.custom_minimum_size = Vector2(200, 50)
	return_button.pressed.connect(_on_return_to_world)
	container.add_child(return_button)
	
	# 禁用回合结束按钮
	if end_turn_button:
		end_turn_button.disabled = true

## 场景退出时清理资源
func _exit_tree() -> void:
	# 停止所有活跃的 Tween 动画
	var all_tweens = get_tree().get_processed_tweens()
	for tween in all_tweens:
		if tween.is_valid():
			tween.kill()
	
	print("[CardBattle] Resources cleaned up")

## 返回世界地图
func _on_return_to_world() -> void:
	# 同步最新的生命值与魔法值回 GameManager
	if GameManager:
		GameManager.player_health = player_health
		GameManager.player_mana = player_mana

	# 发送对应的信号
	if current_state == BattleState.VICTORY:
		battle_won.emit()
	elif current_state == BattleState.DEFEAT:
		battle_lost.emit()
	
	# 从场景树中移除自己
	queue_free()

## 动态创建与样式化逃跑按钮，并连接事件
func _setup_flee_button() -> void:
	if not has_node("UI"):
		return
		
	# 创建按钮并设定属性
	flee_button = Button.new()
	flee_button.name = "FleeButton"
	flee_button.text = "逃跑"
	flee_button.custom_minimum_size = Vector2(130, 40)
	$UI.add_child(flee_button)
	
	# 设定布局位置（紧贴在 EndTurnButton 下方）
	flee_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	flee_button.offset_left = -150.0
	flee_button.offset_top = -70.0
	flee_button.offset_right = -20.0
	flee_button.offset_bottom = -30.0
	
	# 样式化设计（深灰色背景与圆角，使其具有现代感）
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.25, 0.25, 0.3, 0.9)
	style_normal.set_corner_radius_all(4)
	flee_button.add_theme_stylebox_override("normal", style_normal)
	
	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.35, 0.35, 0.4, 1.0)
	style_hover.set_corner_radius_all(4)
	flee_button.add_theme_stylebox_override("hover", style_hover)
	
	var style_disabled = StyleBoxFlat.new()
	style_disabled.bg_color = Color(0.15, 0.15, 0.15, 0.6)
	style_disabled.set_corner_radius_all(4)
	flee_button.add_theme_stylebox_override("disabled", style_disabled)
	
	# 连接点击事件
	flee_button.pressed.connect(_on_flee_pressed)

## 逃跑按钮点击处理
func _on_flee_pressed() -> void:
	if current_state != BattleState.PLAYER_TURN:
		_show_turn_indicator("现在不是你的回合！")
		return
		
	_add_log("正在尝试逃离战斗...")
	_show_turn_indicator("成功逃跑！")
	
	# 禁用逃跑和结束回合按钮，避免多重触发
	flee_button.disabled = true
	if end_turn_button:
		end_turn_button.disabled = true
		
	# 延时 1 秒显示反馈后优雅返回大地图
	await get_tree().create_timer(1.0).timeout
	
	# 同步战时可能已经被消耗的 HP/MP 属性回 GameManager
	if GameManager:
		GameManager.player_health = player_health
		GameManager.player_mana = player_mana
		
	battle_fled.emit()
	queue_free()
