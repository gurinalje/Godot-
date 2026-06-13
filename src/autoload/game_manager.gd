## 游戏管理器
## 自动加载的全局管理器，管理所有游戏系统

extends Node

# 系统管理器引用
var systems: Dictionary = {}

# 游戏状态
var is_game_initialized: bool = false

# 玩家状态（用于存档系统）
var player_health: int = 100
var player_max_health: int = 100
var player_mana: int = 100
var player_max_mana: int = 100
var player_gold: int = 0
var player_experience: int = 0
var player_level: int = 1
var player_attack: int = 10
var player_defense: int = 5
var current_area: String = "forest"
var first_battle_completed: bool = false

# 信号
signal game_initialized()
signal game_reset()

func _ready() -> void:
	print("[GameManager] Initializing...")
	_initialize_systems()

## 初始化所有系统
func _initialize_systems() -> void:
	# 创建系统管理器
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
	_create_system("SaveSlotManager", "res://src/save-system/save_slot_manager.gd")
	_create_system("ChoiceSystem", "res://src/choice-system/choice_system.gd")
	_create_system("WorldStateManager", "res://src/world-state-system/world_state_manager.gd")
	_create_system("NPCManager", "res://src/npc-system/npc_manager.gd")
	_create_system("StoryTracker", "res://src/narrative-tracking-system/story_tracker.gd")
	_create_system("DeckBuildingManager", "res://src/deck-building-system/deck_building_manager.gd")
	_create_system("CardUpgradeManager", "res://src/card-upgrade-system/card_upgrade_manager.gd")
	_create_system("WorldExplorationManager", "res://src/world-exploration-system/world_exploration_manager.gd")
	_create_system("DeckManager", "res://src/deck-management-system/deck_manager.gd")
	_create_system("NarrativeManager", "res://src/narrative-system/narrative_manager.gd")
	_create_system("RPGGrowthManager", "res://src/rpg-growth-system/rpg_growth_manager.gd")
	_create_system("HiddenContentManager", "res://src/hidden-content-system/hidden_content_manager.gd")
	_create_system("AudioManager", "res://src/audio-system/audio_manager.gd")
	_create_system("UIManager", "res://src/ui-system/ui_manager.gd")
	_create_system("SkillTreeManager", "res://src/skill-tree-system/skill_tree_manager.gd")
	_create_system("RuleRewritingManager", "res://src/rule-rewriting-system/rule_rewriting_manager.gd")
	_create_system("StoryMarkManager", "res://src/story-mark-system/story_mark_manager.gd")
	_create_system("DialogueManager", "res://src/dialogue-system/dialogue_manager.gd")
	_create_system("QuestSystem", "res://src/systems/quest_system.gd")

	
	# 等待一帧让所有系统初始化
	await get_tree().process_frame
	
	is_game_initialized = true
	game_initialized.emit()
	print("[GameManager] All systems initialized")

## 创建系统管理器
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

## 获取系统管理器
func get_system(system_name: String) -> Node:
	return systems.get(system_name)

## 检查系统是否存在
func has_system(system_name: String) -> bool:
	return systems.has(system_name)

## 重置游戏
func reset_game() -> void:
	print("[GameManager] Resetting game...")
	
	# 重置所有系统并清理旧节点
	for system in systems.values():
		if system.has_method("reset"):
			system.reset()
		system.queue_free()
	systems.clear()
	
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
