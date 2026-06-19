## 世界探索场景
## 玩家在世界地图上移动，触发事件和战斗

class_name WorldExploration
extends Node2D

# 预加载依赖脚本
const NPCInteractionSystemScript = preload("res://src/npc-system/npc_interaction_system.gd")
const AreaTransitionSystemScript = preload("res://src/systems/area_transition_system.gd")
const NPCDialoguesScript = preload("res://src/npc-system/npc_dialogues.gd")
const PortalScript = preload("res://src/scenes/portal.gd")

# 游戏状态枚举
enum GameState {
	EXPLORING,
	IN_BATTLE,
	IN_DIALOGUE,
	IN_MENU
}

# 常量
const MOVEMENT_SPEED = 200.0
const INTERACTION_RANGE = 100.0

# 地图边界
const MAP_WIDTH = 2000.0
const MAP_HEIGHT = 1500.0
const MAP_MARGIN = 50.0  # 边界留白

# 节点引用
@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Player/Camera2D
@onready var tilemap: TileMap = $TileMap
@onready var ui_layer: CanvasLayer = $UILayer
@onready var hud: Control = $UILayer/HUD
@onready var minimap: Control = $UILayer/Minimap

# 系统引用
var world_state_manager = null
var npc_manager = null
var choice_system = null
var audio_manager = null
var npc_interaction_system = null
var area_transition_system = null

# 传送门
var portals: Array = []

# 当前游戏状态
var current_state: GameState = GameState.EXPLORING

# 玩家状态
var current_area: String = "forest"
var is_moving: bool = false
var can_interact: bool = true

# 玩家属性
var player_health: int = 100
var player_max_health: int = 100
var player_mana: int = 100
var player_max_mana: int = 100
var player_gold: int = 0
var player_experience: int = 0
var player_level: int = 1

# 敌人系统
var enemies_on_map: Array[CharacterBody2D] = []  # 地图上的敌人
var encounter_rate: float = 0.02  # 每步遭遇概率（2%）
var steps_since_last_encounter: int = 0
var min_steps_between_encounters: int = 10  # 最少步数间隔

# 信号
signal area_changed(new_area: String)
signal interaction_started(npc_id: String)
signal battle_triggered(enemy_id: String)

func _ready() -> void:
	# 初始化系统
	_initialize_systems()
	
	# 从GameManager加载玩家状态
	_load_player_state_from_manager()
	
	# 初始化NPC交互系统
	_setup_npc_interaction_system()
	
	# 初始化区域传送系统
	_setup_area_transition_system()
	
	# 设置玩家
	_setup_player()
	
	# 设置HUD样式
	_setup_hud_style()
	
	# 创建探索提示
	_create_exploration_hints()
	
	# 设置暂停菜单连接
	_setup_pause_menu()
	
	# 加载当前区域（内部已包含敌人生成和音乐播放）
	_load_area(current_area)

## 从GameManager加载玩家状态
func _load_player_state_from_manager() -> void:
	var game_manager = get_node_or_null("/root/GameManager")
	if not game_manager:
		return
	
	player_health = game_manager.player_health
	player_max_health = game_manager.player_max_health
	player_mana = game_manager.player_mana if "player_mana" in game_manager else 100
	player_max_mana = game_manager.player_max_mana if "player_max_mana" in game_manager else 100
	player_gold = game_manager.player_gold
	player_experience = game_manager.player_experience
	player_level = game_manager.player_level
	current_area = game_manager.current_area
	
	print("[WorldExploration] Player state loaded from GameManager")

## 同步玩家状态到GameManager
func _sync_player_state_to_manager() -> void:
	var game_manager = get_node_or_null("/root/GameManager")
	if not game_manager:
		return
	
	game_manager.player_health = player_health
	game_manager.player_max_health = player_max_health
	game_manager.player_mana = player_mana
	game_manager.player_max_mana = player_max_mana
	game_manager.player_gold = player_gold
	game_manager.player_experience = player_experience
	game_manager.player_level = player_level
	game_manager.current_area = current_area
	game_manager.first_battle_completed = true

## 场景退出时清理资源
func _exit_tree() -> void:
	# 停止所有活跃的 Tween 动画
	var all_tweens = get_tree().get_processed_tweens()
	for tween in all_tweens:
		if tween.is_valid():
			tween.kill()
	
	# 清理敌人节点
	for enemy in enemies_on_map:
		if is_instance_valid(enemy):
			enemy.queue_free()
	enemies_on_map.clear()
	
	# 清理NPC节点
	var npcs_node = get_node_or_null("NPCs")
	if npcs_node:
		for child in npcs_node.get_children():
			child.queue_free()
	
	# 清理传送门
	for portal in portals:
		if is_instance_valid(portal):
			portal.queue_free()
	portals.clear()
	
	print("[WorldExploration] Resources cleaned up")

## 初始化系统
func _initialize_systems() -> void:
	world_state_manager = get_node_or_null("/root/WorldStateManager")
	npc_manager = get_node_or_null("/root/NPCManager")
	choice_system = get_node_or_null("/root/ChoiceSystem")
	audio_manager = get_node_or_null("/root/AudioManager")
	
	# 连接 QuestSystem 信号以动态处理任务事件与 Boss 刷新机制
	var quest_system = GameManager.get_system("QuestSystem")
	if quest_system:
		if not quest_system.quest_accepted.is_connected(_on_quest_accepted):
			quest_system.quest_accepted.connect(_on_quest_accepted)
		if not quest_system.quest_completed.is_connected(_on_quest_completed):
			quest_system.quest_completed.connect(_on_quest_completed)

## 设置NPC交互系统
func _setup_npc_interaction_system() -> void:
	npc_interaction_system = NPCInteractionSystemScript.new()
	npc_interaction_system.name = "NPCInteractionSystem"
	add_child(npc_interaction_system)
	
	# 连接信号
	npc_interaction_system.dialogue_started.connect(_on_dialogue_started)
	npc_interaction_system.dialogue_ended.connect(_on_dialogue_ended)
	npc_interaction_system.shop_opened.connect(_on_shop_opened)
	npc_interaction_system.shop_closed.connect(_on_shop_closed)
	npc_interaction_system.item_purchased.connect(_on_item_purchased)
	
	print("[WorldExploration] NPC交互系统已初始化")

## 设置区域传送系统
func _setup_area_transition_system() -> void:
	area_transition_system = AreaTransitionSystemScript.new()
	area_transition_system.name = "AreaTransitionSystem"
	add_child(area_transition_system)
	
	# 连接信号
	area_transition_system.area_changed.connect(_on_area_transition_changed)
	area_transition_system.transition_completed.connect(_on_transition_completed)
	
	# 根据当前等级解锁区域
	area_transition_system.check_and_unlock_areas(player_level)
	
	print("[WorldExploration] 区域传送系统已初始化")

## 创建程序化占位符玩家精灵（我的世界风格）
func _create_placeholder_player(sprite: Sprite2D) -> void:
	# 创建一个Image用于绘制（16x16像素风格，放大显示）
	var image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	# 绘制角色身体（方块化风格）
	# 头部（8x8像素）
	for x in range(4, 12):
		for y in range(0, 8):
			image.set_pixel(x, y, Color(0.9, 0.8, 0.7, 1.0))  # 皮肤色
	
	# 头盔
	for x in range(3, 13):
		for y in range(0, 4):
			image.set_pixel(x, y, Color(0.5, 0.5, 0.6, 1.0))  # 铁灰色
	
	# 眼睛
	image.set_pixel(6, 4, Color(0.2, 0.2, 0.2, 1.0))
	image.set_pixel(9, 4, Color(0.2, 0.2, 0.2, 1.0))
	
	# 身体（6x6像素）
	for x in range(5, 11):
		for y in range(8, 14):
			image.set_pixel(x, y, Color(0.2, 0.4, 0.8, 1.0))  # 蓝色盔甲
	
	# 盔甲高光
	for x in range(6, 10):
		for y in range(9, 12):
			image.set_pixel(x, y, Color(0.3, 0.5, 0.9, 1.0))
	
	# 腿部（4x2像素）
	for x in range(5, 7):
		for y in range(14, 16):
			image.set_pixel(x, y, Color(0.3, 0.3, 0.4, 1.0))
	for x in range(9, 11):
		for y in range(14, 16):
			image.set_pixel(x, y, Color(0.3, 0.3, 0.4, 1.0))
	
	# 创建纹理
	var texture = ImageTexture.create_from_image(image)
	sprite.texture = texture
	sprite.scale = Vector2(4, 4)  # 放大4倍显示像素感

## 设置玩家
func _setup_player() -> void:
	# 设置玩家位置
	player.position = Vector2(512, 384)
	
	# 设置相机
	camera.make_current()
	
	# 预加载纹理
	idle_texture = load("res://assets/sprites/characters/players/char_players_vampire_mage_idle.png")
	walk_texture = load("res://assets/sprites/characters/players/char_players_vampire_mage_walk.png")
	
	# 加载玩家精灵（world_exploration.tscn 中 Player 子节点是 Sprite2D）
	var sprite = player.get_node_or_null("Sprite2D")
	if sprite:
		if idle_texture:
			sprite.texture = idle_texture
			sprite.region_enabled = true
			sprite.region_rect = Rect2(0, 0, IDLE_FRAME_WIDTH, FRAME_HEIGHT)
			sprite.hframes = IDLE_FRAME_COUNT
			sprite.vframes = 1
			sprite.scale = Vector2(2, 2)  # 放大2倍显示
			print("[WorldExploration] Loaded vampire mage player sprite")
		else:
			_create_placeholder_player(sprite)
			print("[WorldExploration] Using placeholder player sprite - idle_texture failed to load")
	else:
		print("[WorldExploration] WARNING: No Sprite2D node found on Player")

## 设置HUD样式
func _setup_hud_style() -> void:
	if not hud:
		return
	
	# 给TopPanel添加半透明深色背景
	var top_panel = hud.get_node_or_null("TopPanel")
	if top_panel:
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.05, 0.05, 0.1, 0.85)
		style.border_color = Color(0.3, 0.3, 0.5, 0.6)
		style.set_border_width_all(1)
		style.set_corner_radius_all(0)
		style.set_content_margin_all(0)
		top_panel.add_theme_stylebox_override("panel", style)

## 创建探索提示面板
func _create_exploration_hints() -> void:
	if not hud:
		return
	
	# 创建提示面板（左下角）
	var hint_panel = PanelContainer.new()
	hint_panel.name = "HintPanel"
	hint_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	hint_panel.offset_left = 10
	hint_panel.offset_top = -120
	hint_panel.offset_right = 230
	hint_panel.offset_bottom = -10
	var hint_style = StyleBoxFlat.new()
	hint_style.bg_color = Color(0, 0, 0, 0.7)
	hint_style.border_color = Color(0.4, 0.4, 0.6, 0.5)
	hint_style.set_border_width_all(1)
	hint_style.set_corner_radius_all(6)
	hint_style.set_content_margin_all(8)
	hint_panel.add_theme_stylebox_override("panel", hint_style)
	hud.add_child(hint_panel)
	
	var hint_label = RichTextLabel.new()
	hint_label.bbcode_enabled = true
	hint_label.fit_content = true
	hint_label.scroll_active = false
	hint_label.text = "[center][b]操作提示[/b][/center]\nWASD - 移动\nE - 与NPC交互\nESC - 暂停菜单\n靠近敌人自动触发战斗"
	hint_panel.add_child(hint_label)
	
	# 创建战斗日志面板（右下角）
	var log_panel = PanelContainer.new()
	log_panel.name = "LogPanel"
	log_panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	log_panel.offset_left = -250
	log_panel.offset_top = -100
	log_panel.offset_right = -10
	log_panel.offset_bottom = -10
	var log_style = StyleBoxFlat.new()
	log_style.bg_color = Color(0, 0, 0, 0.6)
	log_style.border_color = Color(0.3, 0.3, 0.5, 0.4)
	log_style.set_border_width_all(1)
	log_style.set_corner_radius_all(4)
	log_style.set_content_margin_all(6)
	log_panel.add_theme_stylebox_override("panel", log_style)
	hud.add_child(log_panel)
	
	var log_label = RichTextLabel.new()
	log_label.name = "LogLabel"
	log_label.bbcode_enabled = true
	log_label.fit_content = true
	log_label.scroll_active = true
	log_label.text = "[color=gray]欢迎来到命运卡牌局！[/color]"
	log_panel.add_child(log_label)

## 添加探索日志（显示在右下角）
func _add_exploration_log(message: String) -> void:
	var log_label = hud.get_node_or_null("LogPanel/LogLabel")
	if log_label:
		log_label.text += "\n" + message
		# 限制行数
		var lines = log_label.text.split("\n")
		if lines.size() > 5:
			log_label.text = "\n".join(lines.slice(lines.size() - 5))

## 加载区域
func _load_area(area_id: String) -> void:
	print("[WorldExploration] Loading area: ", area_id)
	current_area = area_id
	
	# 更新世界状态
	if world_state_manager:
		world_state_manager.set_current_area(area_id)
	
	# 加载地图背景
	_load_map_background(area_id)
	
	# 加载NPC
	_load_npcs(area_id)
	
	# 生成敌人
	_spawn_enemies()
	
	# 生成传送门
	_spawn_portals()
	
	# 播放背景音乐
	_play_area_music()
	
	# 同步状态到GameManager
	_sync_player_state_to_manager()
	
	# 自动保存
	_auto_save()
	
	# 更新UI
	_update_hud()
	
	# 发送区域变更信号
	area_changed.emit(area_id)

## 自动保存游戏
func _auto_save() -> void:
	var game_manager = get_node_or_null("/root/GameManager")
	if not game_manager:
		return
	
	var save_manager = game_manager.get_system("SaveSlotManager")
	if save_manager and save_manager.has_method("save_game"):
		save_manager.save_game()
		print("[WorldExploration] Auto-saved game")

## 加载地图背景
func _load_map_background(area_id: String) -> void:
	# 获取背景节点
	var background = $Background
	if not background:
		return
	
	# 清除现有装饰物
	_clear_decorations()
	
	# 根据区域设置背景颜色和装饰物
	match area_id:
		"forest":
			background.color = Color(0.08, 0.25, 0.08, 1)  # 深绿色森林
			_spawn_forest_decorations()
		"castle":
			background.color = Color(0.15, 0.15, 0.25, 1)  # 深蓝色城堡
			_spawn_castle_decorations()
		"ruins":
			background.color = Color(0.25, 0.2, 0.15, 1)  # 棕色废墟
			_spawn_ruins_decorations()
		"void":
			background.color = Color(0.08, 0.04, 0.12, 1)  # 深紫色虚空
			_spawn_void_decorations()
		_:
			background.color = Color(0.08, 0.08, 0.12, 1)  # 默认深色

## 清除装饰物
func _clear_decorations() -> void:
	var decorations = $Decorations if has_node("Decorations") else null
	if decorations:
		for child in decorations.get_children():
			child.queue_free()

## 生成森林装饰物
func _spawn_forest_decorations() -> void:
	var decorations = _get_or_create_decorations_node()
	
	# 生成树木（带碰撞）
	for i in range(30):
		_create_tree_with_collision(decorations, Vector2(
			randf_range(50, MAP_WIDTH - 50),
			randf_range(50, MAP_HEIGHT - 50)
		))
	
	# 生成草地（无碰撞，装饰用）
	for i in range(50):
		var grass = Sprite2D.new()
		var texture = _create_placeholder_texture("grass")
		grass.texture = texture
		grass.position = Vector2(
			randf_range(0, MAP_WIDTH),
			randf_range(0, MAP_HEIGHT)
		)
		grass.scale = Vector2(2, 2)
		decorations.add_child(grass)
	
	# 生成石头（带碰撞）
	for i in range(15):
		_create_stone_with_collision(decorations, Vector2(
			randf_range(50, MAP_WIDTH - 50),
			randf_range(50, MAP_HEIGHT - 50)
		))

## 生成城堡装饰物
func _spawn_castle_decorations() -> void:
	var decorations = _get_or_create_decorations_node()
	
	# 生成石头（城堡废墟，带碰撞）
	for i in range(40):
		_create_stone_with_collision(decorations, Vector2(
			randf_range(50, MAP_WIDTH - 50),
			randf_range(50, MAP_HEIGHT - 50)
		), Vector2(3, 3))

## 生成废墟装饰物
func _spawn_ruins_decorations() -> void:
	var decorations = _get_or_create_decorations_node()
	
	# 生成石头（带碰撞）
	for i in range(25):
		_create_stone_with_collision(decorations, Vector2(
			randf_range(50, MAP_WIDTH - 50),
			randf_range(50, MAP_HEIGHT - 50)
		), Vector2(2.5, 2.5))
	
	# 生成草地（无碰撞）
	for i in range(30):
		var grass = Sprite2D.new()
		var texture = _create_placeholder_texture("grass")
		grass.texture = texture
		grass.position = Vector2(
			randf_range(0, MAP_WIDTH),
			randf_range(0, MAP_HEIGHT)
		)
		grass.scale = Vector2(2, 2)
		decorations.add_child(grass)

## 生成虚空装饰物
func _spawn_void_decorations() -> void:
	var decorations = _get_or_create_decorations_node()
	
	# 生成少量石头（虚空比较空旷，带碰撞）
	for i in range(10):
		_create_stone_with_collision(decorations, Vector2(
			randf_range(100, MAP_WIDTH - 100),
			randf_range(100, MAP_HEIGHT - 100)
		), Vector2(4, 4))

## 创建带碰撞的树木
func _create_tree_with_collision(parent: Node2D, pos: Vector2) -> void:
	# 创建静态刚体用于碰撞
	var static_body = StaticBody2D.new()
	static_body.position = pos
	static_body.name = "Tree"
	
	# 添加精灵
	var sprite = Sprite2D.new()
	var texture = _create_placeholder_texture("tree")
	sprite.texture = texture
	sprite.scale = Vector2(3, 3)
	static_body.add_child(sprite)
	
	# 添加碰撞形状（树干部分）
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(24, 48)  # 树干碰撞体积
	collision.shape = shape
	collision.position = Vector2(0, 24)  # 偏移到树干位置
	static_body.add_child(collision)
	
	parent.add_child(static_body)

## 创建带碰撞的石头
func _create_stone_with_collision(parent: Node2D, pos: Vector2, scale: Vector2 = Vector2(2, 2)) -> void:
	# 创建静态刚体用于碰撞
	var static_body = StaticBody2D.new()
	static_body.position = pos
	static_body.name = "Stone"
	
	# 添加精灵
	var sprite = Sprite2D.new()
	var texture = _create_placeholder_texture("stone")
	sprite.texture = texture
	sprite.scale = scale
	static_body.add_child(sprite)
	
	# 添加碰撞形状
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(32, 24) * scale  # 根据缩放调整碰撞体积
	collision.shape = shape
	static_body.add_child(collision)
	
	parent.add_child(static_body)

## 创建程序化占位符纹理
func _create_placeholder_texture(type: String) -> Texture2D:
	var image: Image
	
	match type:
		"tree":
			image = _generate_tree_image()
		"grass":
			image = _generate_grass_image()
		"stone":
			image = _generate_stone_image()
		_:
			image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
			image.fill(Color(0.5, 0.5, 0.5, 1.0))
	
	return ImageTexture.create_from_image(image)

## 生成树木图像（我的世界风格）
func _generate_tree_image() -> Image:
	var image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	# 树干（方块化，2x6像素）
	for x in range(6, 8):
		for y in range(8, 14):
			image.set_pixel(x, y, Color(0.5, 0.3, 0.15, 1.0))  # 棕色树干
	
	# 树干纹理
	for x in range(6, 8):
		for y in range(9, 13):
			if y % 2 == 0:
				image.set_pixel(x, y, Color(0.45, 0.25, 0.12, 1.0))
	
	# 树冠（方块化，8x6像素）
	for x in range(2, 14):
		for y in range(2, 8):
			# 创建不规则树冠形状
			var dist_from_center = abs(x - 7)
			if dist_from_center < (8 - y):
				var green = randf_range(0.3, 0.5)
				image.set_pixel(x, y, Color(0.1, green, 0.1, 1.0))
	
	# 树冠高光（左侧）
	for x in range(3, 8):
		for y in range(3, 6):
			if randf() > 0.6:
				image.set_pixel(x, y, Color(0.15, 0.6, 0.15, 1.0))
	
	# 树冠阴影（右侧）
	for x in range(8, 13):
		for y in range(4, 7):
			if randf() > 0.6:
				image.set_pixel(x, y, Color(0.08, 0.25, 0.08, 1.0))
	
	return image

## 生成草地图像（我的世界风格）
func _generate_grass_image() -> Image:
	var image = Image.create(8, 8, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	# 草地方块（底部绿色）
	for x in range(0, 8):
		for y in range(6, 8):
			var green = randf_range(0.3, 0.5)
			image.set_pixel(x, y, Color(0.1, green, 0.1, 1.0))
	
	# 草叶（顶部）
	for x in range(0, 8):
		for y in range(3, 6):
			if randf() > 0.4:
				var green = randf_range(0.35, 0.55)
				image.set_pixel(x, y, Color(0.12, green, 0.12, 1.0))
	
	return image

## 生成石头图像（我的世界风格）
func _generate_stone_image() -> Image:
	var image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	# 石头主体（方块化）
	for x in range(2, 14):
		for y in range(4, 14):
			var gray = randf_range(0.4, 0.55)
			image.set_pixel(x, y, Color(gray, gray, gray, 1.0))
	
	# 石头纹理（裂缝）
	for x in range(4, 12):
		for y in range(6, 12):
			if randf() > 0.85:
				var gray = randf_range(0.3, 0.4)
				image.set_pixel(x, y, Color(gray, gray, gray, 1.0))
	
	# 石头高光（左上）
	for x in range(3, 8):
		for y in range(5, 8):
			if randf() > 0.6:
				var gray = randf_range(0.55, 0.65)
				image.set_pixel(x, y, Color(gray, gray, gray, 1.0))
	
	# 石头阴影（右下）
	for x in range(8, 13):
		for y in range(10, 13):
			if randf() > 0.6:
				var gray = randf_range(0.25, 0.35)
				image.set_pixel(x, y, Color(gray, gray, gray, 1.0))
	
	return image

## 获取或创建装饰物节点
func _get_or_create_decorations_node() -> Node2D:
	var decorations = $Decorations if has_node("Decorations") else null
	if not decorations:
		decorations = Node2D.new()
		decorations.name = "Decorations"
		add_child(decorations)
		move_child(decorations, 1)  # 放在背景之后
	return decorations

## 加载NPC
func _load_npcs(area_id: String) -> void:
	# 清除现有NPC
	for child in $NPCs.get_children():
		child.queue_free()
	
	# 获取区域NPC列表
	var npcs: Array = []
	if npc_manager:
		npcs = npc_manager.get_npcs_in_area(area_id)
	else:
		# 使用默认NPC数据
		npcs = _get_default_npcs(area_id)
	
	# 创建NPC实例
	for npc_data in npcs:
		_create_npc(npc_data)

## 获取默认NPC数据
func _get_default_npcs(area_id: String) -> Array:
	var npcs: Array = []
	
	match area_id:
		"forest":
			npcs.append({
				"id": "merchant_forest",
				"type": "merchant",
				"position": Vector2(300, 300),
				"dialogue_id": "merchant_forest_intro"
			})
			npcs.append({
				"id": "quest_giver_forest",
				"type": "quest_giver",
				"position": Vector2(700, 400),
				"dialogue_id": "quest_forest_start"
			})
		"castle":
			npcs.append({
				"id": "blacksmith_castle",
				"type": "blacksmith",
				"position": Vector2(400, 350),
				"dialogue_id": "blacksmith_castle_intro"
			})
			npcs.append({
				"id": "merchant_castle",
				"type": "merchant",
				"position": Vector2(600, 300),
				"dialogue_id": "merchant_castle_intro"
			})
		"ruins":
			npcs.append({
				"id": "quest_giver_ruins",
				"type": "quest_giver",
				"position": Vector2(500, 400),
				"dialogue_id": "quest_ruins_start"
			})
		"void":
			npcs.append({
				"id": "merchant_void",
				"type": "merchant",
				"position": Vector2(512, 384),
				"dialogue_id": "merchant_void_intro"
			})
	
	return npcs

## 创建NPC
func _create_npc(npc_data: Dictionary) -> void:
	# 创建NPC节点
	var npc = CharacterBody2D.new()
	npc.name = npc_data.get("id", "npc")
	npc.position = npc_data.get("position", Vector2.ZERO)
	
	# 设置NPC元数据
	npc.set_meta("npc_id", npc_data.get("id", ""))
	npc.set_meta("npc_name", NPCDialoguesScript.get_npc_display_name(npc_data.get("id", "")))
	npc.set_meta("npc_type", npc_data.get("type", "merchant"))
	
	# 添加精灵
	var sprite = Sprite2D.new()
	var npc_type = npc_data.get("type", "merchant")
	
	# 直接生成程序化占位符NPC
	_create_placeholder_npc(sprite, npc_type)
	
	npc.add_child(sprite)
	
	# 添加碰撞体
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 30.0
	collision.shape = shape
	npc.add_child(collision)
	
	# 添加交互区域
	var interaction_area = Area2D.new()
	interaction_area.name = "InteractionArea"
	var interaction_collision = CollisionShape2D.new()
	var interaction_shape = CircleShape2D.new()
	interaction_shape.radius = INTERACTION_RANGE
	interaction_collision.shape = interaction_shape
	interaction_area.add_child(interaction_collision)
	npc.add_child(interaction_area)
	
	# 添加到场景
	$NPCs.add_child(npc)

## 创建程序化占位符NPC（我的世界风格）
func _create_placeholder_npc(sprite: Sprite2D, npc_type: String) -> void:
	var image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	match npc_type:
		"merchant":
			# 商人 - 棕色长袍，友善表情
			# 头部
			for x in range(4, 12):
				for y in range(0, 6):
					image.set_pixel(x, y, Color(0.9, 0.8, 0.7, 1.0))
			# 帽子
			for x in range(3, 13):
				for y in range(0, 3):
					image.set_pixel(x, y, Color(0.5, 0.3, 0.15, 1.0))
			# 眼睛
			image.set_pixel(6, 3, Color(0.2, 0.2, 0.2, 1.0))
			image.set_pixel(9, 3, Color(0.2, 0.2, 0.2, 1.0))
			# 身体（棕色长袍）
			for x in range(5, 11):
				for y in range(6, 14):
					image.set_pixel(x, y, Color(0.6, 0.4, 0.2, 1.0))
			# 腿部
			for x in range(5, 7):
				for y in range(14, 16):
					image.set_pixel(x, y, Color(0.4, 0.3, 0.15, 1.0))
			for x in range(9, 11):
				for y in range(14, 16):
					image.set_pixel(x, y, Color(0.4, 0.3, 0.15, 1.0))
		
		"blacksmith":
			# 铁匠 - 皮革围裙，强壮身材
			# 头部
			for x in range(4, 12):
				for y in range(0, 6):
					image.set_pixel(x, y, Color(0.8, 0.7, 0.6, 1.0))
			# 眼睛
			image.set_pixel(6, 3, Color(0.2, 0.2, 0.2, 1.0))
			image.set_pixel(9, 3, Color(0.2, 0.2, 0.2, 1.0))
			# 身体（皮革围裙）
			for x in range(4, 12):
				for y in range(6, 14):
					image.set_pixel(x, y, Color(0.4, 0.3, 0.2, 1.0))
			# 围裙
			for x in range(5, 11):
				for y in range(8, 13):
					image.set_pixel(x, y, Color(0.3, 0.2, 0.1, 1.0))
			# 腿部
			for x in range(5, 7):
				for y in range(14, 16):
					image.set_pixel(x, y, Color(0.3, 0.2, 0.15, 1.0))
			for x in range(9, 11):
				for y in range(14, 16):
					image.set_pixel(x, y, Color(0.3, 0.2, 0.15, 1.0))
		
		"quest_giver":
			# 任务给予者 - 蓝色长袍，智慧老者
			# 头部
			for x in range(4, 12):
				for y in range(0, 6):
					image.set_pixel(x, y, Color(0.9, 0.85, 0.8, 1.0))
			# 胡子
			for x in range(5, 11):
				for y in range(5, 8):
					image.set_pixel(x, y, Color(0.9, 0.9, 0.9, 1.0))
			# 王冠
			for x in range(3, 13):
				for y in range(0, 2):
					image.set_pixel(x, y, Color(0.9, 0.8, 0.2, 1.0))
			# 王冠宝石
			image.set_pixel(7, 1, Color(0.0, 0.8, 1.0, 1.0))
			# 身体（蓝色长袍）
			for x in range(5, 11):
				for y in range(6, 14):
					image.set_pixel(x, y, Color(0.2, 0.3, 0.6, 1.0))
			# 腿部
			for x in range(5, 7):
				for y in range(14, 16):
					image.set_pixel(x, y, Color(0.15, 0.2, 0.4, 1.0))
			for x in range(9, 11):
				for y in range(14, 16):
					image.set_pixel(x, y, Color(0.15, 0.2, 0.4, 1.0))
	
	var texture = ImageTexture.create_from_image(image)
	sprite.texture = texture
	sprite.scale = Vector2(4, 4)  # 放大4倍显示像素感

## 更新HUD
func _update_hud() -> void:
	if not hud:
		return
	
	# 更新区域名称
	var area_label = hud.get_node_or_null("TopPanel/MarginContainer/VBox/AreaLabel")
	if area_label:
		area_label.text = _get_area_name(current_area)
	
	# 更新玩家状态
	_update_player_stats()
	
	# 更新金币显示
	var gold_label = hud.get_node_or_null("TopPanel/MarginContainer/VBox/HBox/InfoVBox/GoldLabel")
	if gold_label:
		gold_label.text = "金币: " + str(player_gold)
	
	# 更新等级显示
	var level_label = hud.get_node_or_null("TopPanel/MarginContainer/VBox/HBox/InfoVBox/LevelLabel")
	if level_label:
		level_label.text = "等级: " + str(player_level)
	
	# 更新经验显示
	var exp_label = hud.get_node_or_null("TopPanel/MarginContainer/VBox/HBox/InfoVBox/ExpLabel")
	if exp_label:
		var exp_required = player_level * 100
		exp_label.text = "经验: " + str(player_experience) + "/" + str(exp_required)

## 更新玩家状态
func _update_player_stats() -> void:
	# 更新生命值条
	var health_bar = hud.get_node_or_null("TopPanel/MarginContainer/VBox/HBox/StatsVBox/HealthHBox/HealthBar")
	if health_bar:
		health_bar.value = player_health
		health_bar.max_value = player_max_health
	
	# 更新生命值数值
	var health_value = hud.get_node_or_null("TopPanel/MarginContainer/VBox/HBox/StatsVBox/HealthHBox/HealthValue")
	if health_value:
		health_value.text = str(player_health) + "/" + str(player_max_health)

	# 更新魔法值条
	var mana_bar = hud.get_node_or_null("TopPanel/MarginContainer/VBox/HBox/StatsVBox/ManaHBox/ManaBar")
	if mana_bar:
		mana_bar.value = player_mana
		mana_bar.max_value = player_max_mana
	
	# 更新魔法值数值
	var mana_value = hud.get_node_or_null("TopPanel/MarginContainer/VBox/HBox/StatsVBox/ManaHBox/ManaValue")
	if mana_value:
		mana_value.text = str(player_mana) + "/" + str(player_max_mana)

## 播放区域音乐
func _play_area_music() -> void:
	if not audio_manager:
		return
	
	var bgm_id = current_area + "_exploration"
	audio_manager.play_bgm(bgm_id)

## 获取区域名称
func _get_area_name(area_id: String) -> String:
	match area_id:
		"forest":
			return "幽暗森林"
		"castle":
			return "废弃城堡"
		"ruins":
			return "古老废墟"
		"void":
			return "虚空领域"
		_:
			return "未知区域"

## 处理输入
func _input(event: InputEvent) -> void:
	# 探索和战斗状态下均支持按下 ESC 打开暂停菜单
	if current_state == GameState.EXPLORING or current_state == GameState.IN_BATTLE:
		if event.is_action_pressed("menu"):
			_open_menu()
		elif event.is_action_pressed("interact") and current_state == GameState.EXPLORING:
			_try_interact()

## 尝试交互
func _try_interact() -> void:
	if not can_interact:
		return
	
	# 检查是否有活跃的NPC交互UI
	if npc_interaction_system and npc_interaction_system.has_active_ui():
		return
	
	# 检查附近的NPC
	var nearby_npc = _find_nearby_npc()
	if nearby_npc:
		_start_interaction(nearby_npc)
	else:
		# 检查是否有其他交互对象
		_check_environment_interaction()

## 查找附近NPC
func _find_nearby_npc() -> Node2D:
	var nearest_npc = null
	var nearest_distance = INTERACTION_RANGE
	
	for npc in $NPCs.get_children():
		var distance = player.position.distance_to(npc.position)
		if distance < nearest_distance:
			nearest_npc = npc
			nearest_distance = distance
	
	return nearest_npc

## 开始交互
func _start_interaction(npc: Node2D) -> void:
	can_interact = false
	current_state = GameState.IN_DIALOGUE
	
	# 获取NPC数据
	var npc_id = npc.name
	var npc_name = npc.get_meta("npc_name", npc_id)
	
	# 发送交互信号
	interaction_started.emit(npc_id)
	
	# 使用NPC交互系统开始对话
	var dialogue = NPCDialoguesScript.get_dialogue(npc_id)
	var shop_items = NPCDialoguesScript.get_shop_items(npc_id)
	
	npc_interaction_system.set_shop_items(shop_items)
	npc_interaction_system.start_dialogue(npc_id, npc_name, dialogue)

## 开始对话
func _start_dialogue(npc_data: Dictionary) -> void:
	var dialogue_manager = get_node_or_null("/root/DialogueSystem")
	if not dialogue_manager:
		return
	
	# 获取对话树
	var dialogue_id = npc_data.get("dialogue_id", "")
	if dialogue_id.is_empty():
		return
	
	# 开始对话
	dialogue_manager.start_dialogue(dialogue_id)

## NPC交互系统回调函数
func _on_dialogue_started(npc_name: String) -> void:
	print("[WorldExploration] 对话开始: ", npc_name)

func _on_dialogue_ended() -> void:
	current_state = GameState.EXPLORING
	can_interact = true
	print("[WorldExploration] 对话结束")

func _on_shop_opened(npc_name: String) -> void:
	print("[WorldExploration] 商店打开: ", npc_name)

func _on_shop_closed() -> void:
	current_state = GameState.EXPLORING
	can_interact = true
	print("[WorldExploration] 商店关闭")

func _on_item_purchased(item_name: String, cost: int) -> void:
	print("[WorldExploration] 购买物品: ", item_name, " 花费: ", cost)
	_update_hud()

## 检查环境交互
func _check_environment_interaction() -> void:
	# 检查传送门
	_check_portal()
	
	# 检查宝箱
	_check_treasure()
	
	# 检查陷阱
	_check_trap()

## 检查传送门
func _check_portal() -> void:
	if not area_transition_system:
		return
	
	# 查找附近的传送门
	for portal in portals:
		if not is_instance_valid(portal):
			continue
		
		var distance = player.position.distance_to(portal.position)
		if distance < INTERACTION_RANGE:
			# 显示传送门信息
			var target_area = portal.target_area
			var area_info = area_transition_system.get_area_info(target_area)
			var area_name = area_info.display_name
			
			# 检查是否可以传送
			var check = area_transition_system.can_transition_to(target_area)
			if check["allowed"]:
				_add_log("按 E 传送到 " + area_name)
				# 执行传送
				area_transition_system.transition_to(target_area)
			else:
				_add_log("传送门: " + area_name + " - " + check["reason"])
			break

## 检查宝箱
func _check_treasure() -> void:
	# 查找附近的宝箱（通过Decorations节点中的宝箱标记）
	var decorations = $Decorations if has_node("Decorations") else null
	if not decorations:
		return
	
	for child in decorations.get_children():
		if not child.has_meta("is_treasure"):
			continue
		
		var distance = player.position.distance_to(child.position)
		if distance < INTERACTION_RANGE:
			# 打开宝箱
			_open_treasure(child)
			break

## 打开宝箱
func _open_treasure(treasure_node: Node2D) -> void:
	if treasure_node.has_meta("opened"):
		_add_log("这个宝箱已经打开了")
		return
	
	# 标记为已打开
	treasure_node.set_meta("opened", true)
	
	# 随机奖励
	var reward_type = randi() % 3
	match reward_type:
		0:
			# 金币奖励
			var gold_amount = randi_range(20, 50) * player_level
			player_gold += gold_amount
			_add_log("打开宝箱获得 " + str(gold_amount) + " 金币！")
		1:
			# 经验奖励
			var exp_amount = randi_range(30, 80) * player_level
			player_experience += exp_amount
			_add_log("打开宝箱获得 " + str(exp_amount) + " 经验！")
		2:
			# 恢复生命值
			var heal_amount = randi_range(20, 50)
			player_health = min(player_health + heal_amount, player_max_health)
			_add_log("打开宝箱恢复 " + str(heal_amount) + " 生命值！")
	
	# 同步状态到GameManager
	_sync_player_state_to_manager()
	
	# 更新HUD
	_update_hud()
	
	# 改变宝箱外观（表示已打开）
	var sprite = treasure_node.get_node_or_null("Sprite2D")
	if sprite:
		sprite.modulate = Color(0.5, 0.5, 0.5, 0.5)

## 检查陷阱
func _check_trap() -> void:
	# 查找附近的陷阱（通过Decorations节点中的陷阱标记）
	var decorations = $Decorations if has_node("Decorations") else null
	if not decorations:
		return
	
	for child in decorations.get_children():
		if not child.has_meta("is_trap"):
			continue
		
		var distance = player.position.distance_to(child.position)
		if distance < INTERACTION_RANGE * 0.5:  # 陷阱检测范围较小
			# 触发陷阱
			_trigger_trap(child)
			break

## 触发陷阱
func _trigger_trap(trap_node: Node2D) -> void:
	if trap_node.has_meta("triggered"):
		return  # 已触发的陷阱不再生效
	
	# 标记为已触发
	trap_node.set_meta("triggered", true)
	
	# 随机陷阱效果
	var trap_type = randi() % 3
	match trap_type:
		0:
			# 伤害陷阱
			var damage = randi_range(10, 30) + player_level * 2
			player_health = max(1, player_health - damage)
			_add_log("触发陷阱！受到 " + str(damage) + " 点伤害！")
			_shake_screen(8.0)
		1:
			# 减速陷阱（暂时降低移动速度）
			_add_log("触发陷阱！移动速度暂时降低！")
			# 这里可以添加减速效果的实现
		2:
			# 金币陷阱（损失金币）
			var gold_loss = randi_range(5, 20)
			player_gold = max(0, player_gold - gold_loss)
			_add_log("触发陷阱！损失 " + str(gold_loss) + " 金币！")
	
	# 同步状态到GameManager
	_sync_player_state_to_manager()
	
	# 更新HUD
	_update_hud()
	
	# 改变陷阱外观（表示已触发）
	var sprite = trap_node.get_node_or_null("Sprite2D")
	if sprite:
		sprite.modulate = Color(0.3, 0.3, 0.3, 0.3)

## 打开菜单
func _open_menu() -> void:
	# 暂停游戏
	get_tree().paused = true
	
	# 打开暂停菜单
	var pause_menu = $UILayer/PauseMenu
	if pause_menu:
		# 如果是在战斗中，由于 UILayer 之前被隐藏了，需要临时显示它，并隐藏大地图的 HUD 和 Minimap 避免遮挡战斗
		if current_state == GameState.IN_BATTLE:
			if ui_layer:
				ui_layer.show()
			if hud:
				hud.hide()
			if minimap:
				minimap.hide()
		pause_menu.show()

## 处理物理更新
func _physics_process(delta: float) -> void:
	if current_state != GameState.EXPLORING:
		return
	
	# 获取输入方向
	var direction = Vector2.ZERO
	direction.x = Input.get_axis("move_left", "move_right")
	direction.y = Input.get_axis("move_up", "move_down")
	
	# 移动玩家
	if direction != Vector2.ZERO:
		player.velocity = direction.normalized() * MOVEMENT_SPEED
		is_moving = true
	else:
		player.velocity = Vector2.ZERO
		is_moving = false
	
	# 更新玩家动画
	_update_player_animation(direction)
	
	# 移动玩家
	player.move_and_slide()
	
	# 限制玩家在地图边界内
	_clamp_player_position()
	
	# 检查随机遭遇
	if is_moving:
		_check_random_encounter()

## 限制玩家位置在地图边界内
func _clamp_player_position() -> void:
	player.position.x = clamp(player.position.x, MAP_MARGIN, MAP_WIDTH - MAP_MARGIN)
	player.position.y = clamp(player.position.y, MAP_MARGIN, MAP_HEIGHT - MAP_MARGIN)

## 动画帧计数器
var animation_timer: float = 0.0
var current_frame: int = 0
const IDLE_FRAME_COUNT = 4
const WALK_FRAME_COUNT = 6
const IDLE_FRAME_WIDTH = 128  # 512px / 4帧
const WALK_FRAME_WIDTH = 192  # 1152px / 6帧
const FRAME_HEIGHT = 48
const IDLE_ANIM_SPEED = 4.0  # 4 FPS
const WALK_ANIM_SPEED = 10.0  # 10 FPS

## 预加载的纹理
var idle_texture: Texture2D = null
var walk_texture: Texture2D = null

## 上一帧的移动状态（用于检测状态切换）
var was_moving: bool = false
var last_facing_left: bool = false

## 更新玩家动画
func _update_player_animation(direction: Vector2) -> void:
	var sprite = player.get_node_or_null("Sprite2D")
	if not sprite:
		return
	
	# 更新动画计时器
	animation_timer += get_physics_process_delta_time()
	
	# 检测状态切换，重置帧计数器
	var state_changed = is_moving != was_moving
	if state_changed:
		current_frame = 0
		animation_timer = 0.0
		was_moving = is_moving
	
	if is_moving:
		# 仅在方向变化时设置朝向（避免每帧翻转导致闪烁）
		var facing_left = direction.x < 0
		if facing_left != last_facing_left:
			last_facing_left = facing_left
			sprite.flip_h = facing_left
		
		# 使用预加载的walk纹理（切换时立即设置帧）
		if walk_texture and sprite.texture != walk_texture:
			sprite.texture = walk_texture
			sprite.region_enabled = true
			sprite.region_rect = Rect2(0, 0, WALK_FRAME_WIDTH, FRAME_HEIGHT)
			sprite.hframes = WALK_FRAME_COUNT
			sprite.frame = current_frame
		
		# 播放行走动画
		if animation_timer >= 1.0 / WALK_ANIM_SPEED:
			animation_timer = 0.0
			current_frame = (current_frame + 1) % WALK_FRAME_COUNT
			sprite.region_rect = Rect2(current_frame * WALK_FRAME_WIDTH, 0, WALK_FRAME_WIDTH, FRAME_HEIGHT)
	else:
		# 使用预加载的idle纹理（切换时立即设置帧）
		if idle_texture and sprite.texture != idle_texture:
			sprite.texture = idle_texture
			sprite.region_enabled = true
			sprite.region_rect = Rect2(0, 0, IDLE_FRAME_WIDTH, FRAME_HEIGHT)
			sprite.hframes = IDLE_FRAME_COUNT
			sprite.frame = current_frame
		
		# 播放待机动画
		if animation_timer >= 1.0 / IDLE_ANIM_SPEED:
			animation_timer = 0.0
			current_frame = (current_frame + 1) % IDLE_FRAME_COUNT
			sprite.region_rect = Rect2(current_frame * IDLE_FRAME_WIDTH, 0, IDLE_FRAME_WIDTH, FRAME_HEIGHT)

## 触发战斗（通过敌人ID）
func _trigger_battle(enemy_data: Dictionary) -> void:
	current_state = GameState.IN_BATTLE
	var enemy_name = enemy_data.get("name", "未知敌人")
	_add_log("遭遇 " + enemy_name + "！")
	
	# 隐藏 UILayer 避免拦截鼠标事件并遮挡战斗界面
	if ui_layer:
		ui_layer.hide()
	
	# 切换到战斗场景，将战斗场景包裹在独立的 CanvasLayer 中
	# 解决直接挂载在 root 下导致 Control 尺寸变为 (0, 0) 引起的分辨率歪斜和鼠标点击丢失问题
	var battle_canvas = CanvasLayer.new()
	battle_canvas.name = "BattleCanvas"
	battle_canvas.layer = 5 # 确保图层在主世界之上，但在必要提示之下
	
	var battle_scene = preload("res://src/scenes/card_battle.tscn").instantiate()
	battle_scene.set("enemy_data", enemy_data)
	
	battle_canvas.add_child(battle_scene)
	get_tree().root.add_child(battle_canvas)
	
	# 显式确保战斗 Control 节点铺满视口以正确进行 UI 相对锚定（全屏与窗口自适应适配）
	battle_scene.set_anchors_preset(Control.PRESET_FULL_RECT)
	battle_scene.offset_left = 0
	battle_scene.offset_right = 0
	battle_scene.offset_top = 0
	battle_scene.offset_bottom = 0
	
	battle_scene.battle_won.connect(_on_battle_won.bind(enemy_data))
	battle_scene.battle_lost.connect(_on_battle_lost)
	battle_scene.battle_fled.connect(_on_battle_fled)
	
	# 隐藏当前场景
	hide()
	set_process(false)

## 添加日志
func _add_log(message: String) -> void:
	print("[WorldExploration] ", message)
	_add_exploration_log(message)

## 生成地图敌人
func _spawn_enemies() -> void:
	# 清除现有敌人
	for enemy in enemies_on_map:
		if is_instance_valid(enemy):
			enemy.queue_free()
	enemies_on_map.clear()
	
	var enemy_data = _get_enemies_for_area(current_area)
	
	for data in enemy_data:
		var enemy = _create_map_enemy(data)
		enemies_on_map.append(enemy)
		add_child(enemy)

## 获取当前区域的敌人数据
func _get_enemies_for_area(area: String) -> Array:
	var enemy_list: Array = []
	
	match area:
		"forest":
			enemy_list = [
				{"name": "野狼", "health": 30, "attack": 6, "defense": 2, "element": "earth", "color": Color(0.5, 0.4, 0.3)},
				{"name": "哥布林", "health": 25, "attack": 5, "defense": 1, "element": "earth", "color": Color(0.3, 0.6, 0.3)},
				{"name": "毒蜘蛛", "health": 20, "attack": 7, "defense": 1, "element": "wind", "color": Color(0.3, 0.2, 0.3)}
			]
		"castle":
			enemy_list = [
				{"name": "骷髅士兵", "health": 40, "attack": 8, "defense": 3, "element": "earth", "color": Color(0.8, 0.8, 0.7)},
				{"name": "暗影骑士", "health": 50, "attack": 10, "defense": 5, "element": "fire", "color": Color(0.2, 0.2, 0.3)},
				{"name": "死灵法师", "health": 35, "attack": 12, "defense": 2, "element": "wind", "color": Color(0.4, 0.2, 0.5)}
			]
		"ruins":
			enemy_list = [
				{"name": "石像鬼", "health": 60, "attack": 9, "defense": 6, "element": "earth", "color": Color(0.5, 0.5, 0.5)},
				{"name": "元素精灵", "health": 45, "attack": 11, "defense": 3, "element": "water", "color": Color(0.3, 0.6, 0.9)},
				{"name": "远古守卫", "health": 70, "attack": 8, "defense": 7, "element": "earth", "color": Color(0.6, 0.5, 0.4)}
			]
		"void":
			enemy_list = [
				{"name": "虚空行者", "health": 80, "attack": 15, "defense": 5, "element": "fire", "color": Color(0.5, 0.2, 0.7)},
				{"name": "混沌使者", "health": 90, "attack": 12, "defense": 8, "element": "lightning", "color": Color(0.7, 0.2, 0.2)},
				{"name": "末日守卫", "health": 100, "attack": 18, "defense": 10, "element": "fire", "color": Color(0.8, 0.3, 0.1)}
			]
	
	return enemy_list

## 创建地图敌人实体
func _create_map_enemy(enemy_data: Dictionary) -> CharacterBody2D:
	var enemy = CharacterBody2D.new()
	enemy.name = "Enemy_" + enemy_data["name"]
	
	# 如果指定了固定生成坐标，直接使用；否则走随机位置算法
	if enemy_data.has("position"):
		enemy.position = enemy_data["position"]
	else:
		# 设置随机位置（避开玩家和NPC）- 添加最大尝试次数防止无限循环
		var valid_position = false
		var pos = Vector2.ZERO
		var max_attempts = 100
		var attempts = 0
		
		while not valid_position and attempts < max_attempts:
			pos = Vector2(
				randf_range(MAP_MARGIN, MAP_WIDTH - MAP_MARGIN),
				randf_range(MAP_MARGIN, MAP_HEIGHT - MAP_MARGIN)
			)
			
			# 检查与玩家的距离
			if pos.distance_to(player.position) > 200:
				valid_position = true
			
			# 检查与其他敌人的距离（避免重叠）
			if valid_position:
				for existing_enemy in enemies_on_map:
					if is_instance_valid(existing_enemy) and pos.distance_to(existing_enemy.position) < 100:
						valid_position = false
						break
			
			attempts += 1
		
		# 如果找不到合适位置，使用默认位置
		if not valid_position:
			pos = Vector2(MAP_WIDTH / 2 + randf_range(-200, 200), MAP_HEIGHT / 2 + randf_range(-200, 200))
			push_warning("[WorldExploration] Could not find ideal enemy position after " + str(max_attempts) + " attempts")
		
		enemy.position = pos
	
	# 创建精灵
	var sprite = Sprite2D.new()
	var texture = _create_enemy_map_sprite(enemy_data["color"])
	sprite.texture = texture
	
	# 如果是 Boss，体积设为原版大体积（7.0, 7.0），并配置金红色调色板发光显眼提示
	if enemy_data.get("is_boss", false):
		sprite.scale = Vector2(7.0, 7.0)
		sprite.modulate = Color(2.0, 1.3, 0.4, 1.0) # 高亮发光
	else:
		sprite.scale = Vector2(4, 4)
	enemy.add_child(sprite)
	
	# 创建碰撞形状
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	if enemy_data.get("is_boss", false):
		shape.radius = 28 # Boss 的碰撞半径更大
	else:
		shape.radius = 16
	collision.shape = shape
	enemy.add_child(collision)
	
	# 如果是 Boss，在头顶动态挂载明显的文字 Label 标签提示
	if enemy_data.get("is_boss", false):
		var label = Label.new()
		label.name = "BossLabel"
		label.text = "【BOSS】" + enemy_data["name"]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.1)) # 金黄色字体
		label.add_theme_color_override("font_shadow_color", Color.BLACK)
		label.add_theme_font_size_override("font_size", 14)
		label.position = Vector2(-80, -45) # 偏移到大体积实体头顶
		label.size = Vector2(160, 20)
		enemy.add_child(label)
	
	# 存储敌人数据
	enemy.set_meta("enemy_data", enemy_data)
	
	# 添加交互检测区域
	var detection_area = Area2D.new()
	detection_area.name = "DetectionArea"
	var detection_shape = CollisionShape2D.new()
	var detection_circle = CircleShape2D.new()
	if enemy_data.get("is_boss", false):
		detection_circle.radius = 64 # Boss 检测半径稍大
	else:
		detection_circle.radius = 48
	detection_shape.shape = detection_circle
	detection_area.add_child(detection_shape)
	enemy.add_child(detection_area)
	
	# 连接信号
	detection_area.body_entered.connect(_on_enemy_detection.bind(enemy))
	
	return enemy

## 创建敌人地图精灵
func _create_enemy_map_sprite(color: Color) -> ImageTexture:
	var image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	# 敌人身体（比玩家稍小的方块）
	for x in range(4, 12):
		for y in range(4, 12):
			image.set_pixel(x, y, color)
	
	# 红色眼睛（表示敌意）
	image.set_pixel(5, 5, Color.RED)
	image.set_pixel(6, 5, Color.RED)
	image.set_pixel(9, 5, Color.RED)
	image.set_pixel(10, 5, Color.RED)
	
	# 暗边框
	var border_color = color.darkened(0.4)
	for x in range(4, 12):
		image.set_pixel(x, 4, border_color)
		image.set_pixel(x, 11, border_color)
	for y in range(4, 12):
		image.set_pixel(4, y, border_color)
		image.set_pixel(11, y, border_color)
	
	var texture = ImageTexture.create_from_image(image)
	return texture

## 敌人检测回调
func _on_enemy_detection(body: Node2D, enemy: CharacterBody2D) -> void:
	if body == player and current_state != GameState.IN_BATTLE:
		var enemy_data = enemy.get_meta("enemy_data")
		if enemy_data:
			# 触发战斗
			_trigger_battle(enemy_data)
			# 移除敌人（击败后不再出现）
			enemy.queue_free()
			enemies_on_map.erase(enemy)

## 战斗胜利回调
func _on_battle_won(enemy_data: Dictionary = {}) -> void:
	current_state = GameState.EXPLORING
	can_interact = true
	
	# 从 GameManager 重新加载战斗后的最新状态
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		player_health = game_manager.player_health
		player_mana = game_manager.player_mana
	
	# 计算奖励
	var gold_reward = 10
	var exp_reward = 15
	if not enemy_data.is_empty():
		if enemy_data.get("is_boss", false):
			# Boss 给予特大经验和金币奖励（击杀大量经验奖励）
			gold_reward = 200
			exp_reward = 300
		else:
			gold_reward = enemy_data.get("health", 50) / 5
			exp_reward = enemy_data.get("attack", 5) * 3
	
	# 测试阶段：怪物掉落奖励 * 10
	gold_reward *= 10
	exp_reward *= 10
	
	# 应用奖励
	player_gold += gold_reward
	player_experience += exp_reward
	
	_add_log("战斗胜利！获得 " + str(gold_reward) + " 金币，" + str(exp_reward) + " 经验")
	
	# 触发任务系统的击杀统计，上报击杀结果以更新任务进度
	var quest_system = GameManager.get_system("QuestSystem")
	if quest_system and not enemy_data.is_empty():
		quest_system.on_enemy_killed(enemy_data.get("name", ""))
	
	# 清理战斗场景
	_cleanup_battle_scene()
	
	# 显示当前场景与 UILayer
	show()
	if ui_layer:
		ui_layer.show()
	set_process(true)
	
	# 检查升级
	_check_level_up()
	
	# 同步状态到GameManager
	_sync_player_state_to_manager()
	
	# 更新HUD
	_update_hud()

## 战斗失败回调
func _on_battle_lost() -> void:
	current_state = GameState.EXPLORING
	can_interact = true
	
	# 恢复部分生命值和魔法值
	player_health = player_max_health / 2
	player_mana = player_max_mana / 2
	
	_add_log("战斗失败...恢复部分生命值与魔法值")
	
	# 清理战斗场景
	_cleanup_battle_scene()
	
	# 显示当前场景与 UILayer
	show()
	if ui_layer:
		ui_layer.show()
	set_process(true)
	
	# 同步状态到GameManager
	_sync_player_state_to_manager()
	
	# 更新HUD
	_update_hud()

## 清理战斗场景
func _cleanup_battle_scene() -> void:
	# 查找并移除包裹了战斗场景的 CanvasLayer 或是独立的战斗场景节点
	for child in get_tree().root.get_children():
		if child.name == "BattleCanvas" or child is CardBattle:
			child.queue_free()
			break

## 检查升级
func _check_level_up() -> void:
	var exp_required = player_level * 100  # 简单升级公式
	if player_experience >= exp_required:
		player_level += 1
		player_experience -= exp_required
		player_max_health += 10
		player_health = player_max_health
		_add_log("升级！当前等级：" + str(player_level))
		
		# 升级时检查区域解锁
		if area_transition_system:
			area_transition_system.check_and_unlock_areas(player_level)
		
		# 同步状态到GameManager
		_sync_player_state_to_manager()

## 检查随机遭遇
func _check_random_encounter() -> void:
	steps_since_last_encounter += 1
	
	if steps_since_last_encounter < min_steps_between_encounters:
		return
	
	if randf() < encounter_rate:
		# 生成一个随机敌人
		var enemy_data = _get_random_enemy_for_area(current_area)
		if not enemy_data.is_empty():
			_trigger_battle(enemy_data)
			steps_since_last_encounter = 0

## 获取随机敌人
func _get_random_enemy_for_area(area: String) -> Dictionary:
	var enemies = _get_enemies_for_area(area)
	if enemies.is_empty():
		return {}
	return enemies[randi() % enemies.size()]

## 区域变更时调用
func _on_area_changed(new_area: String) -> void:
	# 加载新区域（内部已包含敌人生成和音乐播放）
	_load_area(new_area)

## 传送完成回调
func _on_transition_completed() -> void:
	print("[WorldExploration] 区域传送完成")

## 生成传送门
func _spawn_portals() -> void:
	# 清除现有传送门
	for portal in portals:
		if is_instance_valid(portal):
			portal.queue_free()
	portals.clear()
	
	if not area_transition_system:
		return
	
	# 获取当前区域配置
	var area_info = area_transition_system.get_area_info(current_area)
	var connections = area_info.connections
	
	# 为每个连接创建传送门
	for i in range(connections.size()):
		var target_area_id = connections[i]
		var portal = PortalScript.new()
		portal.name = "Portal_" + target_area_id
		portal.target_area = target_area_id
		portal.portal_name = "前往 " + area_transition_system.get_area_info(target_area_id).display_name
		
		# 设置位置（在地图边缘）
		var angle = (i * TAU) / connections.size()
		var distance = 400.0
		portal.position = Vector2(
			MAP_WIDTH / 2 + cos(angle) * distance,
			MAP_HEIGHT / 2 + sin(angle) * distance
		)
		
		# 连接信号
		portal.portal_entered.connect(_on_portal_entered)
		
		add_child(portal)
		portals.append(portal)

## 传送门进入回调
func _on_portal_entered(target_area_id: String) -> void:
	if not area_transition_system:
		return
	
	var check = area_transition_system.can_transition_to(target_area_id)
	if check["allowed"]:
		# 执行传送
		area_transition_system.transition_to(target_area_id)
	else:
		_add_log(check["reason"])

## 区域传送完成回调
func _on_area_transition_changed(old_area: String, new_area: String) -> void:
	current_area = new_area
	
	# 重新加载区域
	_load_area(new_area)
	
	# 更新UI显示
	_update_area_display()

## 更新区域显示
func _update_area_display() -> void:
	if not area_transition_system:
		return
	
	var area_label = hud.get_node_or_null("TopPanel/MarginContainer/VBox/AreaLabel") if hud else null
	if area_label:
		var area_info = area_transition_system.get_area_info(current_area)
		area_label.text = area_info.display_name

## 屏幕震动效果
func _shake_screen(intensity: float) -> void:
	if not camera:
		return
	
	var original_position = camera.position
	var tween = create_tween()
	
	# 震动效果
	for i in range(5):
		var offset = Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		)
		tween.tween_property(camera, "position", original_position + offset, 0.05)
	
	# 回到原位
	tween.tween_property(camera, "position", original_position, 0.1)

## 设置暂停菜单
func _setup_pause_menu() -> void:
	# 确保父级 CanvasLayer 在暂停时仍然处理输入，避免被场景树暂停挂起
	if ui_layer:
		ui_layer.process_mode = Node.PROCESS_MODE_ALWAYS
		
	var pause_menu = get_node_or_null("UILayer/PauseMenu")
	if pause_menu:
		# 设置暂停时也处理输入，防止卡死
		pause_menu.process_mode = Node.PROCESS_MODE_ALWAYS
		
		var resume_btn = pause_menu.get_node_or_null("VBoxContainer/ResumeButton")
		if resume_btn:
			resume_btn.pressed.connect(_on_resume_pressed)
			
			# 为继续游戏按钮绑定 ESC (menu) 快捷键
			# 确保游戏被暂停且场景树挂起时，依然能通过键盘 ESC 键触发并关闭菜单
			var shortcut = Shortcut.new()
			var event = InputEventAction.new()
			event.action = "menu"
			shortcut.events.append(event)
			resume_btn.shortcut = shortcut
		
		var settings_btn = pause_menu.get_node_or_null("VBoxContainer/SettingsButton")
		if settings_btn:
			settings_btn.pressed.connect(func(): print("[WorldExploration] Settings clicked (stub)"))
		
		var main_menu_btn = pause_menu.get_node_or_null("VBoxContainer/MainMenuButton")
		if main_menu_btn:
			main_menu_btn.pressed.connect(_on_main_menu_pressed)

func _on_resume_pressed() -> void:
	var pause_menu = get_node_or_null("UILayer/PauseMenu")
	if pause_menu:
		pause_menu.hide()
	get_tree().paused = false
	
	# 如果是在战斗中，恢复游戏后需要重新隐藏 UILayer 并还原 HUD 和 Minimap 的显示状态
	if current_state == GameState.IN_BATTLE:
		if ui_layer:
			ui_layer.hide()
		if hud:
			hud.show()
		if minimap:
			minimap.show()

func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://src/scenes/main_menu.tscn")

## 处理接取任务信号，实现特定任务 Boss 降临大地图
func _on_quest_accepted(quest_id: String) -> void:
	if quest_id == "forest_boss_quest":
		# 在大地图中上方区域安全刷出 Boss 森林巨魔，避开玩家出生点 (512, 384)
		var boss_data = {
			"name": "森林巨魔",
			"health": 120,
			"max_health": 120,
			"attack": 18,
			"defense": 8,
			"element": "earth",
			"color": Color(0.85, 0.2, 0.2), # 明显的深红血色
			"is_boss": true,
			"position": Vector2(1000, 500)
		}
		
		var boss_node = _create_map_enemy(boss_data)
		enemies_on_map.append(boss_node)
		add_child(boss_node)
		
		# 明显的全图视觉与日志警告提示
		_add_log("[color=red][b]⚠️【警告】狂暴的 BOSS「森林巨魔」在地图中上方 (1000, 500) 降临了！击败它可以获得巨额经验！⚠️[/b][/color]")
		_shake_screen(15.0) # 屏幕强烈震动，增强 Boss 登场仪式感

## 处理任务完成信号，同步奖励、刷新 HUD 并检测升级
func _on_quest_completed(quest_id: String) -> void:
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		player_gold = game_manager.player_gold
		player_experience = game_manager.player_experience
		player_level = game_manager.player_level
		player_health = game_manager.player_health
		player_max_health = game_manager.player_max_health
		player_mana = game_manager.player_mana
		player_max_mana = game_manager.player_max_mana
		
	_update_hud()
	_check_level_up()

## 战斗逃跑回调处理，清理战斗场景并同步 HP/MP 状态返回大探索
func _on_battle_fled() -> void:
	current_state = GameState.EXPLORING
	can_interact = true
	
	_add_log("成功逃离了战斗...")
	
	# 逃跑时可能已被扣减 HP/MP，重新从 GameManager 中拉取同步最新的数值
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		player_health = game_manager.player_health
		player_mana = game_manager.player_mana
		
	# 清理战斗界面
	_cleanup_battle_scene()
	
	# 显示当前探索场景并拉起大地图 UI
	show()
	if ui_layer:
		ui_layer.show()
	set_process(true)
	_update_hud()
