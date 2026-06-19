## 游戏管理器
## 自动加载的全局管理器，管理所有游戏系统生命周期
extends Node

# ============================================================
# 导出属性
# ============================================================

## 玩家数据资源（可在编辑器中配置）
@export var player_data: PlayerData = PlayerData.new()

## 游戏配置资源（可在编辑器中配置）
@export var game_config: GameConfig = GameConfig.new()

# ============================================================
# 内部状态
# ============================================================

## 系统管理器引用
var systems: Dictionary = {}

## 游戏状态
var is_game_initialized: bool = false

# ============================================================
# 向后兼容属性（已弃用，请使用 player_data.xxx）
# ============================================================

## 已弃用：请使用 player_data.health
var player_health: int:
	get: return player_data.health
	set(v): player_data.health = v

## 已弃用：请使用 player_data.max_health
var player_max_health: int:
	get: return player_data.max_health
	set(v): player_data.max_health = v

## 已弃用：请使用 player_data.mana
var player_mana: int:
	get: return player_data.mana
	set(v): player_data.mana = v

## 已弃用：请使用 player_data.max_mana
var player_max_mana: int:
	get: return player_data.max_mana
	set(v): player_data.max_mana = v

## 已弃用：请使用 player_data.gold
var player_gold: int:
	get: return player_data.gold
	set(v): player_data.gold = v

## 已弃用：请使用 player_data.experience
var player_experience: int:
	get: return player_data.experience
	set(v): player_data.experience = v

## 已弃用：请使用 player_data.level
var player_level: int:
	get: return player_data.level
	set(v): player_data.level = v

## 已弃用：请使用 player_data.attack
var player_attack: int:
	get: return player_data.attack
	set(v): player_data.attack = v

## 已弃用：请使用 player_data.defense
var player_defense: int:
	get: return player_data.defense
	set(v): player_data.defense = v

## 已弃用：请使用 player_data.current_area
var current_area: String:
	get: return player_data.current_area
	set(v): player_data.current_area = v

## 已弃用：请使用 player_data.first_battle_completed
var first_battle_completed: bool:
	get: return player_data.first_battle_completed
	set(v): player_data.first_battle_completed = v

# ============================================================
# 信号
# ============================================================

signal game_initialized()
signal game_reset()

# ============================================================
# 生命周期
# ============================================================

func _ready() -> void:
	print("[GameManager] Initializing...")
	# 使用 GameConfig 初始化玩家数据
	player_data.apply_config(game_config)
	_initialize_systems()

# ============================================================
# 系统初始化
# ============================================================

## 初始化所有系统（拆分为更小的方法）
func _initialize_systems() -> void:
	_create_systems()
	await _wait_for_initialization()
	is_game_initialized = true
	game_initialized.emit()
	print("[GameManager] All systems initialized")

## 创建所有系统节点
func _create_systems() -> void:
	# 战斗相关系统
	_create_system("CardDatabase", "res://src/card-database/card_database.gd")
	_create_system("CharacterAttributesManager", "res://src/character-attributes/character_attributes_manager.gd")
	_create_system("InputManager", "res://src/input-system/input_manager.gd")
	_create_system("DamageCalculator", "res://src/damage-calculation/damage_calculator.gd")
	_create_system("StatusEffectManager", "res://src/status-effect-system/status_effect_manager.gd")
	_create_system("ComboChainManager", "res://src/combo-chain-system/combo_chain_manager.gd")
	_create_system("ElementSystem", "res://src/element-system/element_system.gd")
	_create_system("SummonManager", "res://src/summon-system/summon_manager.gd")
	_create_system("EnvironmentManager", "res://src/environment-system/environment_manager.gd")
	_create_system("CardBattleSystem", "res://src/card-battle-system/card_battle_system.gd")
	
	# 存档系统
	_create_system("SaveSlotManager", "res://src/save-system/save_slot_manager.gd")
	
	# 探索和叙事系统
	_create_system("ChoiceSystem", "res://src/choice-system/choice_system.gd")
	_create_system("WorldStateManager", "res://src/world-state-system/world_state_manager.gd")
	_create_system("NPCManager", "res://src/npc-system/npc_manager.gd")
	_create_system("StoryTracker", "res://src/narrative-tracking-system/story_tracker.gd")
	_create_system("DeckBuildingManager", "res://src/deck-building-system/deck_building_manager.gd")
	_create_system("CardUpgradeManager", "res://src/card-upgrade-system/card_upgrade_manager.gd")
	_create_system("WorldExplorationManager", "res://src/world-exploration-system/world_exploration_manager.gd")
	_create_system("DeckManager", "res://src/deck-management-system/deck_manager.gd")
	_create_system("NarrativeManager", "res://src/narrative-system/narrative_manager.gd")
	
	# RPG 成长系统
	_create_system("GrowthDatabase", "res://src/systems/growth_database.gd")
	_create_system("RPGGrowthManager", "res://src/rpg-growth-system/rpg_growth_manager.gd")
	_create_system("HiddenContentManager", "res://src/hidden-content-system/hidden_content_manager.gd")
	
	# UI 和音频系统
	_create_system("AudioManager", "res://src/audio-system/audio_manager.gd")
	_create_system("UIManager", "res://src/ui-system/ui_manager.gd")
	
	# 技能树系统
	_create_system("SkillTreeDatabase", "res://src/skill-tree-system/skill_tree_database.gd")
	_create_system("SkillTreeManager", "res://src/skill-tree-system/skill_tree_manager.gd")
	
	# 其他系统
	_create_system("RuleRewritingManager", "res://src/rule-rewriting-system/rule_rewriting_manager.gd")
	_create_system("StoryMarkManager", "res://src/story-mark-system/story_mark_manager.gd")
	_create_system("DialogueManager", "res://src/dialogue-system/dialogue_manager.gd")
	_create_system("QuestDatabase", "res://src/systems/quest_database.gd")
	_create_system("QuestSystem", "res://src/systems/quest_system.gd")

## 等待所有系统初始化完成
func _wait_for_initialization() -> void:
	await get_tree().process_frame

## 创建单个系统节点
func _create_system(system_name: String, script_path: String) -> void:
	if not ResourceLoader.exists(script_path):
		push_warning("[GameManager] Script not found: " + script_path)
		return
	
	var script = load(script_path)
	if not script:
		push_warning("[GameManager] Failed to load script: " + script_path)
		return
	
	var system = Node.new()
	system.name = system_name
	system.set_script(script)
	add_child(system)
	
	systems[system_name] = system
	print("[GameManager] Created system: ", system_name)

# ============================================================
# 系统访问
# ============================================================

## 获取系统管理器
func get_system(system_name: String) -> Node:
	return systems.get(system_name)

## 检查系统是否存在
func has_system(system_name: String) -> bool:
	return systems.has(system_name)

# ============================================================
# 游戏操作
# ============================================================

## 重置游戏
func reset_game() -> void:
	print("[GameManager] Resetting game...")
	
	# 重置所有系统并清理旧节点
	for system in systems.values():
		# 使用 SystemBase 契约检查，而非 has_method
		if system is SystemBase:
			system.reset()
		system.queue_free()
	systems.clear()
	
	# 重置玩家数据
	player_data.reset(game_config)
	
	is_game_initialized = false
	game_reset.emit()
	
	# 重新初始化
	_initialize_systems()

## 保存游戏
func save_game() -> bool:
	var save_manager = get_system("SaveSlotManager")
	if save_manager and save_manager.has_method("save_game"):
		return save_manager.save_game()
	return false

## 加载游戏
func load_game() -> bool:
	var save_manager = get_system("SaveSlotManager")
	if save_manager and save_manager.has_method("load_game"):
		return save_manager.load_game()
	return false

## 获取游戏版本
func get_game_version() -> String:
	return "0.1.0"

## 检查游戏是否初始化
func is_initialized() -> bool:
	return is_game_initialized

## 检查是否有存档数据
func has_save_data() -> bool:
	var save_manager = get_system("SaveSlotManager")
	if save_manager:
		return not save_manager.is_slot_empty(0)  # 检查自动存档槽
	return false

# ============================================================
# 便捷方法（委托给 PlayerData）
# ============================================================

## 治疗玩家
func heal_player(amount: int) -> int:
	return player_data.heal(amount)

## 玩家受到伤害
func damage_player(amount: int) -> int:
	return player_data.take_damage(amount)

## 检查玩家是否存活
func is_player_alive() -> bool:
	return player_data.is_alive()
