## NPC交互系统
## 处理NPC对话和商店功能
class_name NPCInteractionSystem
extends Node

# 信号
signal dialogue_started(npc_name: String)
signal dialogue_ended()
signal shop_opened(npc_name: String)
signal shop_closed()
signal item_purchased(item_name: String, cost: int)
signal item_sold(item_name: String, price: int)

# 对话数据
var current_dialogue: Array[Dictionary] = []
var current_dialogue_index: int = 0
var current_npc_name: String = ""
var current_npc_id: String = ""

# 商店数据
var shop_items: Array[Dictionary] = []

# UI引用
var dialogue_ui: Control
var shop_ui: Control

# 世界场景引用
var world_scene: Node = null

## 初始化
func _ready() -> void:
	# 延迟获取世界场景引用
	call_deferred("_setup_world_reference")

## 设置世界场景引用
func _setup_world_reference() -> void:
	world_scene = get_node_or_null("/root/WorldExploration")
	if not world_scene:
		# 尝试从父节点获取
		var parent = get_parent()
		while parent:
			if parent is WorldExploration:
				world_scene = parent
				break
			parent = parent.get_parent()

## 开始对话
func start_dialogue(npc_id: String, npc_name: String, dialogue_data: Array[Dictionary]) -> void:
	current_npc_id = npc_id
	current_npc_name = npc_name
	current_dialogue = dialogue_data
	current_dialogue_index = 0
	
	# 创建对话UI
	_create_dialogue_ui()
	
	# 显示第一句对话
	_show_current_dialogue()
	
	dialogue_started.emit(npc_name)

## 显示当前对话
func _show_current_dialogue() -> void:
	if current_dialogue_index >= current_dialogue.size():
		_end_dialogue()
		return
	
	var dialogue = current_dialogue[current_dialogue_index]
	var speaker = dialogue.get("speaker", current_npc_name)
	var text = dialogue.get("text", "")
	var choices = dialogue.get("choices", [])
	
	# 更新UI
	if dialogue_ui:
		var name_label = dialogue_ui.get_node_or_null("VBoxContainer/NameLabel")
		var text_label = dialogue_ui.get_node_or_null("VBoxContainer/TextLabel")
		var choices_container = dialogue_ui.get_node_or_null("VBoxContainer/ChoicesContainer")
		
		if name_label:
			name_label.text = speaker
		if text_label:
			text_label.text = text
		
		# 清除现有选项
		if choices_container:
			for child in choices_container.get_children():
				child.queue_free()
			
			# 添加选项按钮
			if choices.size() > 0:
				for i in range(choices.size()):
					var choice = choices[i]
					var button = Button.new()
					button.text = choice.get("text", "继续")
					button.pressed.connect(_on_choice_selected.bind(i))
					choices_container.add_child(button)
			else:
				# 没有选项，添加继续按钮
				var button = Button.new()
				button.text = "继续"
				button.pressed.connect(_on_next_dialogue)
				choices_container.add_child(button)

## 选择选项
func _on_choice_selected(choice_index: int) -> void:
	var dialogue = current_dialogue[current_dialogue_index]
	var choices = dialogue.get("choices", [])
	
	if choice_index < choices.size():
		var choice = choices[choice_index]
		var action = choice.get("action", "")
		
		# 执行选项动作
		match action:
			"continue":
				current_dialogue_index += 1
				_show_current_dialogue()
			"shop":
				_open_shop()
			"end":
				_end_dialogue()
			"accept_quest":
				_accept_quest()
			_:
				current_dialogue_index += 1
				_show_current_dialogue()

## 下一句对话
func _on_next_dialogue() -> void:
	current_dialogue_index += 1
	_show_current_dialogue()

## 接受任务
func _accept_quest() -> void:
	# 真正集成 QuestSystem 任务系统，通过 GameManager 安全查询与接取任务
	var quest_system = GameManager.get_system("QuestSystem")
	if quest_system:
		var available = quest_system.get_available_quests(current_npc_id)
		if available.size() > 0:
			var quest_to_accept = available[0] # 默认接取第一个可用任务
			quest_system.accept_quest(quest_to_accept["id"])
			print("[NPCInteraction] 成功接取任务: ", quest_to_accept["name"])
		else:
			print("[NPCInteraction] 没有针对该 NPC (" + current_npc_id + ") 的可用任务（或任务已在激活状态）")
	else:
		push_warning("[NPCInteraction] 任务系统 QuestSystem 未找到")
	
	current_dialogue_index += 1
	_show_current_dialogue()

## 结束对话
func _end_dialogue() -> void:
	if dialogue_ui:
		dialogue_ui.queue_free()
		dialogue_ui = null
	
	current_dialogue.clear()
	current_dialogue_index = 0
	
	dialogue_ended.emit()

## 打开商店
func _open_shop() -> void:
	# 结束对话
	if dialogue_ui:
		dialogue_ui.queue_free()
		dialogue_ui = null
	
	# 创建商店UI
	_create_shop_ui()
	
	shop_opened.emit(current_npc_name)

## 创建对话UI
func _create_dialogue_ui() -> void:
	# 清除现有UI
	if dialogue_ui:
		dialogue_ui.queue_free()
	
	# 创建对话UI容器
	dialogue_ui = PanelContainer.new()
	dialogue_ui.name = "DialogueUI"
	dialogue_ui.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	# 显式重设偏移，防止在 CanvasLayer 包裹下其尺寸计算变为 0 导致被挤压或隐藏（窗口与全屏拉伸适配）
	dialogue_ui.offset_left = 20
	dialogue_ui.offset_right = -20
	dialogue_ui.offset_top = -220
	dialogue_ui.offset_bottom = -20
	dialogue_ui.custom_minimum_size = Vector2(0, 200)
	
	# 设置样式
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.1, 0.1, 0.15, 0.9)
	style_box.border_color = Color(0.4, 0.4, 0.5, 1.0)
	style_box.set_border_width_all(2)
	style_box.set_corner_radius_all(8)
	style_box.set_content_margin_all(16)
	dialogue_ui.add_theme_stylebox_override("panel", style_box)
	
	# 添加到场景树
	var canvas_layer = CanvasLayer.new()
	canvas_layer.name = "DialogueLayer"
	canvas_layer.layer = 10
	# 允许在暂停时处理对话输入，防止暂停状态下对话UI死锁
	canvas_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	canvas_layer.add_child(dialogue_ui)
	get_tree().root.add_child(canvas_layer)
	
	# 创建内容容器
	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	vbox.add_theme_constant_override("separation", 8)
	dialogue_ui.add_child(vbox)
	
	# 名称标签
	var name_label = Label.new()
	name_label.name = "NameLabel"
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.3))
	vbox.add_child(name_label)
	
	# 文本标签
	var text_label = RichTextLabel.new()
	text_label.name = "TextLabel"
	text_label.bbcode_enabled = true
	text_label.fit_content = true
	text_label.custom_minimum_size = Vector2(0, 60)
	text_label.add_theme_font_size_override("normal_font_size", 16)
	vbox.add_child(text_label)
	
	# 选项容器
	var choices_container = HBoxContainer.new()
	choices_container.name = "ChoicesContainer"
	choices_container.add_theme_constant_override("separation", 8)
	choices_container.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(choices_container)

## 创建商店UI
func _create_shop_ui() -> void:
	# 清除现有UI
	if shop_ui:
		shop_ui.queue_free()
	
	# 创建商店UI容器
	shop_ui = PanelContainer.new()
	shop_ui.name = "ShopUI"
	shop_ui.set_anchors_preset(Control.PRESET_CENTER)
	# 显式设置偏移，确保商店 UI 在不同尺寸的视口（小窗口和全屏）下均能完美居中对齐
	shop_ui.offset_left = -200
	shop_ui.offset_right = 200
	shop_ui.offset_top = -250
	shop_ui.offset_bottom = 250
	shop_ui.custom_minimum_size = Vector2(400, 500)
	
	# 设置样式
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.12, 0.1, 0.08, 0.95)
	style_box.border_color = Color(0.6, 0.5, 0.3, 1.0)
	style_box.set_border_width_all(3)
	style_box.set_corner_radius_all(10)
	style_box.set_content_margin_all(16)
	shop_ui.add_theme_stylebox_override("panel", style_box)
	
	# 添加到场景树
	var canvas_layer = CanvasLayer.new()
	canvas_layer.name = "ShopLayer"
	canvas_layer.layer = 10
	# 允许在暂停时处理商店输入
	canvas_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	canvas_layer.add_child(shop_ui)
	get_tree().root.add_child(canvas_layer)
	
	# 创建内容容器
	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	vbox.add_theme_constant_override("separation", 10)
	shop_ui.add_child(vbox)
	
	# 标题
	var title = Label.new()
	title.name = "TitleLabel"
	title.text = current_npc_name + " 的商店"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.9, 0.8, 0.3))
	vbox.add_child(title)
	
	# 分隔线
	var separator = HSeparator.new()
	vbox.add_child(separator)
	
	# 金币显示
	var gold_label = Label.new()
	gold_label.name = "GoldLabel"
	gold_label.text = "金币: " + str(_get_player_gold())
	gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gold_label.add_theme_font_size_override("font_size", 18)
	gold_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
	vbox.add_child(gold_label)
	
	# 物品列表（带滚动）
	var scroll_container = ScrollContainer.new()
	scroll_container.name = "ScrollContainer"
	scroll_container.custom_minimum_size = Vector2(0, 300)
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll_container)
	
	var items_container = VBoxContainer.new()
	items_container.name = "ItemsContainer"
	items_container.add_theme_constant_override("separation", 6)
	items_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_container.add_child(items_container)
	
	# 添加商店物品
	for item in shop_items:
		var item_ui = _create_shop_item_ui(item)
		items_container.add_child(item_ui)
	
	# 分隔线
	var separator2 = HSeparator.new()
	vbox.add_child(separator2)
	
	# 关闭按钮
	var close_button = Button.new()
	close_button.text = "关闭商店"
	close_button.custom_minimum_size = Vector2(120, 40)
	close_button.pressed.connect(_close_shop)
	vbox.add_child(close_button)

## 创建商店物品UI
func _create_shop_item_ui(item: Dictionary) -> Control:
	var item_container = HBoxContainer.new()
	item_container.add_theme_constant_override("separation", 10)
	
	# 物品名称
	var name_label = Label.new()
	name_label.text = item.get("name", "物品")
	name_label.custom_minimum_size = Vector2(120, 0)
	name_label.add_theme_font_size_override("font_size", 16)
	item_container.add_child(name_label)
	
	# 物品类型
	var type_label = Label.new()
	type_label.text = _get_item_type_name(item.get("type", ""))
	type_label.custom_minimum_size = Vector2(60, 0)
	type_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	item_container.add_child(type_label)
	
	# 物品价格
	var price_label = Label.new()
	price_label.text = str(item.get("cost", 0)) + " 金币"
	price_label.custom_minimum_size = Vector2(80, 0)
	price_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
	item_container.add_child(price_label)
	
	# 购买按钮
	var buy_button = Button.new()
	buy_button.text = "购买"
	buy_button.custom_minimum_size = Vector2(60, 30)
	buy_button.pressed.connect(_on_buy_item.bind(item))
	item_container.add_child(buy_button)
	
	return item_container

## 获取物品类型名称
func _get_item_type_name(type: String) -> String:
	match type:
		"consumable":
			return "消耗品"
		"card":
			return "卡牌"
		"equipment":
			return "装备"
		"material":
			return "材料"
		_:
			return "其他"

## 购买物品
func _on_buy_item(item: Dictionary) -> void:
	var cost = item.get("cost", 0)
	var player_gold = _get_player_gold()
	
	if player_gold >= cost:
		# 扣除金币
		_set_player_gold(player_gold - cost)
		
		# 添加物品到玩家背包
		_add_item_to_inventory(item)
		
		# 更新UI
		_update_shop_gold_display()
		
		# 显示购买成功通知
		_show_notification("购买成功: " + item.get("name", "物品"))
		
		item_purchased.emit(item.get("name", "物品"), cost)
	else:
		# 金币不足提示
		_show_notification("金币不足！需要 " + str(cost) + " 金币")

## 关闭商店
func _close_shop() -> void:
	if shop_ui:
		shop_ui.queue_free()
		shop_ui = null
	
	shop_items.clear()
	shop_closed.emit()

## 设置商店物品
func set_shop_items(items: Array[Dictionary]) -> void:
	shop_items = items

## 获取玩家金币
func _get_player_gold() -> int:
	if world_scene and world_scene.has_method("get"):
		return world_scene.get("player_gold")
	return 0

## 设置玩家金币
func _set_player_gold(amount: int) -> void:
	if world_scene and world_scene.has_method("set"):
		world_scene.set("player_gold", amount)

## 添加物品到背包
func _add_item_to_inventory(item: Dictionary) -> void:
	# TODO: 实现背包系统集成
	print("[NPCInteraction] 添加物品到背包: ", item.get("name", ""))
	
	# 根据物品类型处理
	var item_type = item.get("type", "")
	match item_type:
		"consumable":
			# 消耗品效果
			var effect = item.get("effect", "")
			var value = item.get("value", 0)
			_apply_consumable_effect(effect, value)
		"card":
			# 添加卡牌到卡组
			var card_id = item.get("card_id", "")
			_add_card_to_deck(card_id)
		"equipment":
			# 装备物品
			_equip_item(item)

## 应用消耗品效果
func _apply_consumable_effect(effect: String, value: int) -> void:
	match effect:
		"heal":
			# 恢复生命值
			if world_scene:
				var current_health = world_scene.get("player_health")
				var max_health = world_scene.get("player_max_health")
				world_scene.set("player_health", min(current_health + value, max_health))
				_show_notification("恢复了 " + str(value) + " 点生命值")
		"energy":
			# 恢复能量
			_show_notification("恢复了 " + str(value) + " 点能量")

## 添加卡牌到卡组
func _add_card_to_deck(card_id: String) -> void:
	print("[NPCInteraction] 添加卡牌: ", card_id)
	
	# 获取卡牌数据库
	var card_database = GameManager.get_system("CardDatabase")
	if not card_database:
		push_warning("[NPCInteraction] CardDatabase not found")
		_show_notification("卡牌添加失败：系统未就绪")
		return
	
	# 获取卡牌数据
	var card_data = card_database.get_card(card_id)
	if not card_data:
		push_warning("[NPCInteraction] Card not found: " + card_id)
		_show_notification("卡牌添加失败：卡牌不存在")
		return
	
	# 尝试添加到DeckBuildingManager
	var deck_manager = GameManager.get_system("DeckBuildingManager")
	if deck_manager and deck_manager.has_method("add_card_to_collection"):
		deck_manager.add_card_to_collection(card_data)
		_show_notification("获得卡牌: " + card_data.name)
	else:
		# 回退：直接通知玩家
		_show_notification("获得卡牌: " + card_data.name + " (已加入收藏)")
	
	# 发送信号
	item_purchased.emit(card_data.name, 0)

## 装备物品
func _equip_item(item: Dictionary) -> void:
	var item_name = item.get("name", "未知物品")
	print("[NPCInteraction] 装备物品: ", item_name)
	
	# 获取物品类型和效果
	var item_type = item.get("equipment_type", "")
	var bonus_attack = item.get("bonus_attack", 0)
	var bonus_defense = item.get("bonus_defense", 0)
	var bonus_health = item.get("bonus_health", 0)
	
	# 应用装备效果到世界场景
	if world_scene:
		# 增加攻击力
		if bonus_attack > 0:
			var current_attack = world_scene.get("player_attack") if world_scene.get("player_attack") != null else 0
			world_scene.set("player_attack", current_attack + bonus_attack)
		
		# 增加防御力
		if bonus_defense > 0:
			var current_defense = world_scene.get("player_defense") if world_scene.get("player_defense") != null else 0
			world_scene.set("player_defense", current_defense + bonus_defense)
		
		# 增加生命值上限
		if bonus_health > 0:
			var current_max_health = world_scene.get("player_max_health")
			if current_max_health:
				world_scene.set("player_max_health", current_max_health + bonus_health)
				# 同时恢复生命值
				var current_health = world_scene.get("player_health")
				world_scene.set("player_health", min(current_health + bonus_health, current_max_health + bonus_health))
		
		# 更新HUD
		if world_scene.has_method("_update_hud"):
			world_scene._update_hud()
	
	# 显示装备通知
	var bonus_text = ""
	if bonus_attack > 0:
		bonus_text += " 攻击+" + str(bonus_attack)
	if bonus_defense > 0:
		bonus_text += " 防御+" + str(bonus_defense)
	if bonus_health > 0:
		bonus_text += " 生命+" + str(bonus_health)
	
	_show_notification("装备: " + item_name + bonus_text)
	
	# 发送信号
	item_purchased.emit(item_name, 0)

## 更新商店金币显示
func _update_shop_gold_display() -> void:
	if shop_ui:
		var gold_label = shop_ui.get_node_or_null("VBoxContainer/GoldLabel")
		if gold_label:
			gold_label.text = "金币: " + str(_get_player_gold())

## 显示通知
func _show_notification(message: String) -> void:
	var notification = Label.new()
	notification.text = message
	notification.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notification.set_anchors_preset(Control.PRESET_CENTER)
	
	# 设置样式
	notification.add_theme_font_size_override("font_size", 18)
	notification.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	notification.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	notification.add_theme_constant_override("shadow_offset_x", 2)
	notification.add_theme_constant_override("shadow_offset_y", 2)
	
	var canvas_layer = CanvasLayer.new()
	canvas_layer.name = "NotificationLayer"
	canvas_layer.layer = 15
	canvas_layer.add_child(notification)
	get_tree().root.add_child(canvas_layer)
	
	# 2秒后消失
	await get_tree().create_timer(2.0).timeout
	if is_instance_valid(notification):
		notification.queue_free()
	if is_instance_valid(canvas_layer):
		canvas_layer.queue_free()

## 检查是否有活跃的UI
func has_active_ui() -> bool:
	return dialogue_ui != null or shop_ui != null

## 获取当前NPC ID
func get_current_npc_id() -> String:
	return current_npc_id

## 获取当前NPC名称
func get_current_npc_name() -> String:
	return current_npc_name
