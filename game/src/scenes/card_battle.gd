## 卡牌战斗场景（纯UI层）
## 所有战斗逻辑由 CardBattleSystem 驱动
## 本文件仅负责：UI创建、信号监听、动画效果、用户输入转发

class_name CardBattle
extends Control

## ==================== 常量 ====================

const MAX_HAND_SIZE: int = 10

## ==================== UI引用 ====================

@onready var player_health_bar: ProgressBar = $UI/PlayerHealthBar
@onready var player_mana_bar: ProgressBar = $UI/PlayerManaBar
@onready var energy_label: Label = $UI/EnergyLabel
@onready var hand_container: HBoxContainer = $UI/HandContainer
@onready var enemy_container: HBoxContainer = $UI/EnemyContainer
@onready var end_turn_button: Button = $UI/EndTurnButton
@onready var log_text: RichTextLabel = $UI/LogText

## ==================== 系统引用 ====================

var battle_system: CardBattleSystem = null

## ==================== 本地UI状态 ====================

## 逃跑按钮引用
var flee_button: Button = null

## 外部传入的敌人数据（从世界地图传入）
var enemy_data: Dictionary = {}

## 打击感 - 屏幕震动
var shake_intensity: float = 0.0
var shake_decay: float = 5.0

## ==================== 信号 ====================

signal battle_won()
signal battle_lost()
signal battle_fled()

## ==================== 初始化 ====================

func _ready() -> void:
	# 获取战斗系统
	battle_system = GameManager.get_system("CardBattleSystem")
	if not battle_system:
		push_error("[CardBattle] CardBattleSystem not found!")
		return
	
	# 连接战斗系统信号
	_connect_battle_signals()
	
	# 创建UI覆盖层
	_create_battle_overlay()
	_setup_flee_button()
	
	# 初始化战斗
	_initialize_battle()
	
	# 检查教程
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

## ==================== 信号连接 ====================

func _connect_battle_signals() -> void:
	# 战斗生命周期
	battle_system.battle_started.connect(_on_battle_started)
	battle_system.battle_ended.connect(_on_battle_ended)
	
	# 回合生命周期
	battle_system.turn_started.connect(_on_turn_started)
	battle_system.turn_ended.connect(_on_turn_ended)
	
	# 卡牌操作
	battle_system.card_played.connect(_on_card_played)
	battle_system.energy_changed.connect(_on_energy_changed)
	battle_system.hand_changed.connect(_on_hand_changed)
	
	# 伤害事件
	battle_system.enemy_damaged.connect(_on_enemy_damaged)
	battle_system.player_damaged.connect(_on_player_damaged)
	battle_system.player_healed.connect(_on_player_healed)
	
	# 死亡事件
	battle_system.enemy_defeated.connect(_on_enemy_defeated)
	battle_system.player_defeated.connect(_on_player_defeated)
	
	# Buff事件
	battle_system.buff_applied.connect(_on_buff_applied)
	battle_system.buff_expired.connect(_on_buff_expired)
	
	# 召唤物事件
	battle_system.summon_added.connect(_on_summon_added)
	battle_system.summon_removed.connect(_on_summon_removed)
	battle_system.summon_damaged.connect(_on_summon_damaged)
	battle_system.summon_defeated.connect(_on_summon_defeated)
	
	# 环境事件
	battle_system.environment_applied.connect(_on_environment_applied)
	
	# DOT事件
	battle_system.dot_applied.connect(_on_dot_applied)
	battle_system.dot_damage.connect(_on_dot_damage)
	
	# 日志和提示
	battle_system.log_message.connect(_on_log_message)
	battle_system.turn_indicator.connect(_on_turn_indicator)
	
	# UI按钮
	end_turn_button.pressed.connect(_on_end_turn_pressed)

## ==================== 战斗初始化 ====================

func _initialize_battle() -> void:
	print("[CardBattle] Initializing battle...")
	
	# 初始化卡组
	var deck = _get_deck()
	
	# 初始化敌人
	var enemies = _get_enemies()
	
	# 获取玩家状态
	var player_stats = {}
	if GameManager:
		player_stats = {
			"health": GameManager.player_health,
			"max_health": GameManager.player_max_health,
			"mana": GameManager.player_mana,
			"max_mana": GameManager.player_max_mana,
			"defense": GameManager.player_defense
		}
	
	# 创建敌人UI
	_create_enemy_ui(enemies)
	
	# 检查Boss战斗
	_check_boss_battle(enemies)
	
	# 开始战斗
	battle_system.start_battle(deck, enemies, player_stats)

## 获取卡组
func _get_deck() -> Array[CardData]:
	var deck_manager = get_node_or_null("/root/GameManager/DeckBuildingManager")
	if not deck_manager:
		deck_manager = get_node_or_null("/root/DeckBuildingManager")
	if deck_manager:
		return deck_manager.get_current_deck()
	return _create_default_deck()

## 创建默认卡组
func _create_default_deck() -> Array[CardData]:
	var default_deck: Array[CardData] = []
	var card_database = get_node_or_null("/root/GameManager/CardDatabase")
	if not card_database:
		card_database = get_node_or_null("/root/CardDatabase")
	if card_database:
		for i in range(5):
			var card = card_database.get_card("fireball")
			if card:
				default_deck.append(card)
		for i in range(3):
			var card = card_database.get_card("shield")
			if card:
				default_deck.append(card)
		for i in range(2):
			var card = card_database.get_card("holy_blessing")
			if card:
				default_deck.append(card)
		for item_id in ["item_health_potion", "item_rage_potion", "item_elixir"]:
			var card = card_database.get_card(item_id)
			if card:
				default_deck.append(card)
	return default_deck

## 获取敌人数据
func _get_enemies() -> Array[Dictionary]:
	if not enemy_data.is_empty():
		var enemies: Array[Dictionary] = []
		enemies.append(enemy_data.duplicate())
		if not enemies[0].has("max_health"):
			enemies[0]["max_health"] = enemies[0].get("health", 50)
		return enemies
	
	return [
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

## 检查Boss战斗
func _check_boss_battle(enemies: Array[Dictionary]) -> void:
	var is_boss_battle = false
	for enemy in enemies:
		if enemy.get("is_boss", false):
			is_boss_battle = true
			break
	if is_boss_battle and flee_button:
		flee_button.disabled = true
		flee_button.text = "无法逃跑"

## ==================== 敌人UI ====================

func _create_enemy_ui(enemies: Array[Dictionary]) -> void:
	for child in enemy_container.get_children():
		child.queue_free()
	
	for i in range(enemies.size()):
		var enemy = enemies[i]
		var enemy_ui = VBoxContainer.new()
		enemy_ui.name = "Enemy" + str(i)
		
		var sprite = TextureRect.new()
		sprite.texture = _create_enemy_placeholder(enemy.get("element", "none"))
		sprite.custom_minimum_size = Vector2(128, 128)
		sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		enemy_ui.add_child(sprite)
		
		var health_bar = ProgressBar.new()
		health_bar.name = "HealthBar"
		health_bar.value = enemy.get("health", 0)
		health_bar.max_value = enemy.get("max_health", 0)
		health_bar.custom_minimum_size = Vector2(128, 20)
		enemy_ui.add_child(health_bar)
		
		var name_label = Label.new()
		name_label.name = "NameLabel"
		name_label.text = enemy.get("name", "Enemy")
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		enemy_ui.add_child(name_label)
		
		enemy_container.add_child(enemy_ui)

func _create_enemy_placeholder(element: String) -> ImageTexture:
	var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	var body_color = Color(0.6, 0.4, 0.3)
	match element:
		"fire": body_color = Color(0.9, 0.3, 0.2)
		"water": body_color = Color(0.2, 0.5, 0.9)
		"earth": body_color = Color(0.5, 0.4, 0.2)
		"wind": body_color = Color(0.6, 0.9, 0.6)
		"lightning": body_color = Color(0.9, 0.9, 0.3)
	
	for x in range(8, 24):
		for y in range(8, 24):
			image.set_pixel(x, y, body_color)
	
	for x in range(10, 14):
		for y in range(12, 16):
			image.set_pixel(x, y, Color.RED)
	for x in range(18, 22):
		for y in range(12, 16):
			image.set_pixel(x, y, Color.RED)
	
	var border_color = body_color.darkened(0.3)
	for x in range(8, 24):
		image.set_pixel(x, 8, border_color)
		image.set_pixel(x, 23, border_color)
	for y in range(8, 24):
		image.set_pixel(8, y, border_color)
		image.set_pixel(23, y, border_color)
	
	return ImageTexture.create_from_image(image)

## ==================== 卡牌UI ====================

func _create_card_placeholder(card_type: CardEnums.CardType) -> ImageTexture:
	var image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	var card_color = _get_card_color(card_type)
	
	for x in range(2, 62):
		for y in range(2, 62):
			image.set_pixel(x, y, card_color)
	
	for x in range(60):
		image.set_pixel(x, 1, Color.WHITE)
		image.set_pixel(x, 62, Color.WHITE)
	for y in range(62):
		image.set_pixel(1, y, Color.WHITE)
		image.set_pixel(62, y, Color.WHITE)
	
	return ImageTexture.create_from_image(image)

func _get_card_color(card_type: CardEnums.CardType) -> Color:
	match card_type:
		CardEnums.CardType.DIRECT_DAMAGE:
			return Color(0.9, 0.2, 0.2, 0.8)
		CardEnums.CardType.SUMMON:
			return Color(0.5, 0.3, 0.8, 0.8)
		CardEnums.CardType.ENVIRONMENT:
			return Color(0.2, 0.7, 0.4, 0.8)
		CardEnums.CardType.BUFF_DEBUFF:
			return Color(0.9, 0.7, 0.1, 0.8)
		_:
			return Color(0.5, 0.5, 0.5, 0.8)

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

## ==================== UI更新 ====================

func _update_player_ui() -> void:
	if not battle_system:
		return
	
	var stats = battle_system.get_player_stats()
	
	if energy_label:
		energy_label.text = "能量: " + str(stats.energy) + "/" + str(stats.max_energy)
	if player_health_bar:
		player_health_bar.value = stats.health
		player_health_bar.max_value = stats.max_health
	if player_mana_bar:
		player_mana_bar.value = stats.mana
		player_mana_bar.max_value = stats.max_mana

func _update_hand_ui(hand: Array[CardData]) -> void:
	for child in hand_container.get_children():
		child.queue_free()
	
	var num_cards = hand.size()
	var base_separation = 20
	if num_cards > 5:
		base_separation = max(-80, 20 - (num_cards - 5) * 20)
	hand_container.add_theme_constant_override("separation", base_separation)
	
	for i in range(hand.size()):
		var card = hand[i]
		var card_ui = _create_card_ui(card, i)
		hand_container.add_child(card_ui)

func _create_card_ui(card: CardData, index: int) -> Control:
	var card_panel = PanelContainer.new()
	card_panel.name = "Card" + str(index)
	card_panel.custom_minimum_size = Vector2(140, 200)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2, 0.95)
	style.border_color = _get_card_color(card.card_type)
	style.set_border_width_all(3)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(6)
	card_panel.add_theme_stylebox_override("panel", style)
	
	var card_container = VBoxContainer.new()
	card_container.name = "CardContent"
	card_panel.add_child(card_container)
	
	var icon = TextureRect.new()
	icon.texture = _create_card_placeholder(card.card_type)
	icon.custom_minimum_size = Vector2(48, 48)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	card_container.add_child(icon)
	
	var name_label = Label.new()
	name_label.text = card.display_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", _get_card_color(card.card_type))
	card_container.add_child(name_label)
	
	var cost_label = Label.new()
	cost_label.text = "⚡ " + str(card.cost)
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_label.add_theme_font_size_override("font_size", 12)
	cost_label.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	card_container.add_child(cost_label)
	
	var effect_label = Label.new()
	effect_label.text = _get_card_effect_summary(card)
	effect_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	effect_label.add_theme_font_size_override("font_size", 10)
	effect_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	card_container.add_child(effect_label)
	
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card_container.add_child(spacer)
	
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

func _update_enemy_ui() -> void:
	if not battle_system:
		return
	
	for i in range(battle_system.get_enemy_count()):
		var enemy = battle_system.get_enemy(i)
		var enemy_ui = enemy_container.get_node_or_null("Enemy" + str(i))
		if not enemy_ui:
			continue
		
		var health_bar = enemy_ui.get_node_or_null("HealthBar")
		if health_bar:
			health_bar.value = enemy.get("health", 0)
			health_bar.max_value = enemy.get("max_health", 0)

func _update_summons_ui() -> void:
	if not battle_system:
		return
	
	var summons_container = enemy_container.get_node_or_null("SummonsContainer")
	if not summons_container:
		summons_container = VBoxContainer.new()
		summons_container.name = "SummonsContainer"
		enemy_container.add_child(summons_container)
	
	for child in summons_container.get_children():
		child.queue_free()
	
	var summons = battle_system.get_summons()
	for i in range(summons.size()):
		var summon = summons[i]
		var summon_ui = HBoxContainer.new()
		summon_ui.name = "Summon" + str(i)
		
		var name_label = Label.new()
		name_label.text = summon["name"]
		summon_ui.add_child(name_label)
		
		var health_label = Label.new()
		health_label.text = " HP:" + str(summon["health"]) + "/" + str(summon["max_health"])
		summon_ui.add_child(health_label)
		
		var attack_label = Label.new()
		attack_label.text = " 攻:" + str(summon["attack"])
		summon_ui.add_child(attack_label)
		
		summons_container.add_child(summon_ui)

## ==================== 战斗系统信号处理 ====================

func _on_battle_started() -> void:
	print("[CardBattle] Battle started")

func _on_battle_ended(victory: bool) -> void:
	_show_battle_result(victory)
	if victory:
		battle_won.emit()
	else:
		battle_lost.emit()

func _on_turn_started(turn_number: int) -> void:
	_update_player_ui()
	_update_hand_ui(battle_system.get_hand())
	print("[CardBattle] Turn ", turn_number, " started")

func _on_turn_ended(turn_number: int) -> void:
	print("[CardBattle] Turn ", turn_number, " ended")

func _on_card_played(card: CardData, card_index: int) -> void:
	_update_player_ui()
	_update_hand_ui(battle_system.get_hand())
	_update_enemy_ui()
	_shake_screen(5.0)
	print("[CardBattle] Card played: ", card.display_name)

func _on_energy_changed(current: int, max_value: int) -> void:
	if energy_label:
		energy_label.text = "能量: " + str(current) + "/" + str(max_value)

func _on_hand_changed(hand: Array[CardData]) -> void:
	_update_hand_ui(hand)

func _on_enemy_damaged(enemy_index: int, damage: int, is_critical: bool) -> void:
	_show_floating_damage(damage, enemy_index, false)
	_flash_enemy(enemy_index)
	_shake_screen(8.0 if not is_critical else 15.0)
	_update_enemy_ui()

func _on_player_damaged(damage: int, is_critical: bool) -> void:
	_show_floating_damage(damage, -1, true)
	_shake_screen(12.0)
	_flash_screen_damage()
	_update_player_ui()

func _on_player_healed(amount: int) -> void:
	_show_floating_heal(amount)
	_update_player_ui()

func _on_enemy_defeated(enemy_index: int, enemy_name: String) -> void:
	_add_log(enemy_name + " 被击败！")
	_show_turn_indicator(enemy_name + " 被击败！")
	_shake_screen(10.0)
	_update_enemy_ui()

func _on_player_defeated() -> void:
	_add_log("你被击败了...")

func _on_buff_applied(target: String, buff_type: String, value: int, duration: int) -> void:
	match buff_type:
		"attack_boost":
			_show_turn_indicator("攻击力 +" + str(value))
		"defense_boost":
			_show_turn_indicator("防御力 +" + str(value))

func _on_buff_expired(target: String, buff_type: String) -> void:
	pass

func _on_summon_added(summon: Dictionary) -> void:
	_update_summons_ui()

func _on_summon_removed(summon: Dictionary, index: int) -> void:
	_update_summons_ui()

func _on_summon_damaged(index: int, damage: int) -> void:
	_shake_screen(5.0)
	_update_summons_ui()

func _on_summon_defeated(index: int, summon_name: String) -> void:
	_add_log(summon_name + " 被击败！")
	_show_turn_indicator(summon_name + " 被击败！")
	_update_summons_ui()

func _on_environment_applied(env_name: String, duration: int) -> void:
	_add_log("施放环境效果：" + env_name + "，持续 " + str(duration) + " 回合")

func _on_dot_applied(target: String, damage: int, duration: int) -> void:
	pass

func _on_dot_damage(target: String, damage: int) -> void:
	pass

func _on_log_message(message: String) -> void:
	_add_log(message)

func _on_turn_indicator(text: String) -> void:
	_show_turn_indicator(text)

## ==================== 用户输入 ====================

func _on_card_clicked(index: int) -> void:
	if battle_system:
		battle_system.play_card_by_index(index)

func _on_end_turn_pressed() -> void:
	if battle_system:
		battle_system.end_player_turn()

## ==================== 日志和提示 ====================

func _add_log(message: String) -> void:
	if log_text:
		log_text.add_text(message + "\n")
		log_text.scroll_to_line(log_text.get_line_count() - 1)

## ==================== 打击感和动画 ====================

func _create_battle_overlay() -> void:
	var overlay = Control.new()
	overlay.name = "BattleOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.z_index = 50
	$UI.add_child(overlay)
	
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

func _check_and_show_tutorial() -> void:
	var game_manager = get_node_or_null("/root/GameManager")
	var is_first_battle = true
	
	if game_manager and game_manager.has_method("get"):
		is_first_battle = game_manager.get("first_battle_completed") != true
	
	if is_first_battle:
		_show_battle_tutorial()
		if game_manager and game_manager.has_method("set"):
			game_manager.set("first_battle_completed", true)

func _show_battle_tutorial() -> void:
	var tutorial_overlay = ColorRect.new()
	tutorial_overlay.name = "TutorialOverlay"
	tutorial_overlay.color = Color(0, 0, 0, 0.8)
	tutorial_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	tutorial_overlay.z_index = 200
	$UI.add_child(tutorial_overlay)
	
	var tutorial_container = VBoxContainer.new()
	tutorial_container.name = "TutorialContainer"
	tutorial_container.set_anchors_preset(Control.PRESET_CENTER)
	tutorial_container.offset_left = -250
	tutorial_container.offset_top = -200
	tutorial_container.offset_right = 250
	tutorial_container.offset_bottom = 200
	tutorial_overlay.add_child(tutorial_container)
	
	var title = Label.new()
	title.text = "战斗教程"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1, 0.9, 0.2))
	tutorial_container.add_child(title)
	
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
		
		var icon_label = Label.new()
		icon_label.text = step["icon"]
		icon_label.add_theme_font_size_override("font_size", 24)
		step_container.add_child(icon_label)
		
		var text_label = Label.new()
		text_label.text = step["text"]
		text_label.add_theme_font_size_override("font_size", 16)
		text_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
		step_container.add_child(text_label)
		
		tutorial_container.add_child(step_container)
	
	var separator = HSeparator.new()
	separator.add_theme_constant_override("separation", 20)
	tutorial_container.add_child(separator)
	
	var tip_label = Label.new()
	tip_label.text = "提示：合理搭配攻击和防御卡牌是胜利的关键！"
	tip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip_label.add_theme_font_size_override("font_size", 14)
	tip_label.add_theme_color_override("font_color", Color(0.7, 0.9, 0.7))
	tutorial_container.add_child(tip_label)
	
	var start_button = Button.new()
	start_button.text = "开始战斗！"
	start_button.custom_minimum_size = Vector2(200, 50)
	start_button.add_theme_font_size_override("font_size", 18)
	start_button.pressed.connect(_on_tutorial_closed.bind(tutorial_overlay))
	tutorial_container.add_child(start_button)

func _on_tutorial_closed(tutorial_overlay: ColorRect) -> void:
	var tween = create_tween()
	tween.tween_property(tutorial_overlay, "modulate:a", 0.0, 0.5)
	tween.tween_callback(tutorial_overlay.queue_free)

func _show_turn_indicator(text: String) -> void:
	var indicator = $UI.get_node_or_null("BattleOverlay/TurnIndicator")
	if not indicator:
		return
	
	indicator.text = text
	indicator.modulate.a = 1.0
	
	var tween = create_tween()
	tween.tween_property(indicator, "modulate:a", 0.0, 2.0).set_delay(1.5)

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
		damage_label.position = Vector2(120, 100)
	else:
		var enemy_ui = enemy_container.get_node_or_null("Enemy" + str(enemy_index))
		if enemy_ui:
			damage_label.position = enemy_ui.position + Vector2(0, -30)
		else:
			damage_label.position = Vector2(512, 200)
	
	$UI.add_child(damage_label)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(damage_label, "position:y", damage_label.position.y - 60, 1.0)
	tween.tween_property(damage_label, "modulate:a", 0.0, 1.0).set_delay(0.5)
	tween.tween_property(damage_label, "scale", Vector2(1.5, 1.5), 0.2)
	tween.chain().tween_property(damage_label, "scale", Vector2(1.0, 1.0), 0.3)
	tween.chain().tween_callback(damage_label.queue_free)

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
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(heal_label, "position:y", heal_label.position.y - 50, 1.0)
	tween.tween_property(heal_label, "modulate:a", 0.0, 1.0).set_delay(0.5)
	tween.chain().tween_callback(heal_label.queue_free)

func _shake_screen(intensity: float) -> void:
	shake_intensity = intensity

func _flash_enemy(enemy_index: int) -> void:
	var enemy_ui = enemy_container.get_node_or_null("Enemy" + str(enemy_index))
	if not enemy_ui:
		return
	
	var sprite = null
	for child in enemy_ui.get_children():
		if child is TextureRect:
			sprite = child
			break
	
	if sprite:
		var original_modulate = sprite.modulate
		sprite.modulate = Color(3, 3, 3, 1)
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", original_modulate, 0.3)

func _flash_screen_damage() -> void:
	var flash = ColorRect.new()
	flash.name = "DamageFlash"
	flash.color = Color(1, 0, 0, 0.3)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.z_index = 55
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$UI.add_child(flash)
	
	var tween = create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.4)
	tween.tween_callback(flash.queue_free)

func _show_battle_result(is_victory: bool) -> void:
	var overlay = ColorRect.new()
	overlay.name = "ResultOverlay"
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 100
	$UI.add_child(overlay)
	
	var container = VBoxContainer.new()
	container.name = "ResultContainer"
	container.set_anchors_preset(Control.PRESET_CENTER)
	container.offset_left = -150
	container.offset_top = -100
	container.offset_right = 150
	container.offset_bottom = 100
	overlay.add_child(container)
	
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
	
	if is_victory:
		var reward_label = Label.new()
		reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		reward_label.add_theme_font_size_override("font_size", 16)
		reward_label.text = "获得奖励！"
		container.add_child(reward_label)
	
	var return_button = Button.new()
	return_button.text = "返回探索"
	return_button.custom_minimum_size = Vector2(200, 50)
	return_button.pressed.connect(_on_return_to_world)
	container.add_child(return_button)
	
	if end_turn_button:
		end_turn_button.disabled = true

## ==================== 逃跑按钮 ====================

func _setup_flee_button() -> void:
	if not has_node("UI"):
		return
	
	flee_button = Button.new()
	flee_button.name = "FleeButton"
	flee_button.text = "逃跑"
	flee_button.custom_minimum_size = Vector2(130, 40)
	$UI.add_child(flee_button)
	
	flee_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	flee_button.offset_left = -150.0
	flee_button.offset_top = -70.0
	flee_button.offset_right = -20.0
	flee_button.offset_bottom = -30.0
	
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
	
	flee_button.pressed.connect(_on_flee_pressed)

func _on_flee_pressed() -> void:
	if not battle_system or battle_system.battle_state != CardBattleSystem.BattleState.PLAYER_TURN:
		_show_turn_indicator("现在不是你的回合！")
		return
	
	_add_log("正在尝试逃离战斗...")
	_show_turn_indicator("成功逃跑！")
	
	flee_button.disabled = true
	if end_turn_button:
		end_turn_button.disabled = true
	
	await get_tree().create_timer(1.0).timeout
	
	# 同步状态回GameManager
	if GameManager and battle_system:
		GameManager.player_health = battle_system.player_health
		GameManager.player_mana = battle_system.player_mana
	
	battle_fled.emit()
	queue_free()

## ==================== 场景退出 ====================

func _exit_tree() -> void:
	var all_tweens = get_tree().get_processed_tweens()
	for tween in all_tweens:
		if tween.is_valid():
			tween.kill()
	print("[CardBattle] Resources cleaned up")

func _on_return_to_world() -> void:
	if GameManager and battle_system:
		GameManager.player_health = battle_system.player_health
		GameManager.player_mana = battle_system.player_mana
	queue_free()
