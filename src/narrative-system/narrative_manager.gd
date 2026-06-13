## 叙事管理器
## 管理游戏剧情和故事分支

class_name NarrativeManager
extends Node

# 当前剧情状态
var current_chapter: int = 1
var current_scene: String = "intro"

# 剧情数据
var story_data: Dictionary = {}

# 选择历史
var choice_history: Array[Dictionary] = []

# 信号
signal chapter_changed(new_chapter: int)
signal scene_changed(new_scene: String)
signal choice_made(choice_id: String, option: String)

func _ready() -> void:
	initialize()

func initialize() -> void:
	print("[NarrativeManager] Initialized")
	_load_story_data()

## 加载剧情数据
func _load_story_data() -> void:
	# TODO: 从文件加载剧情数据
	story_data = {
		"chapter_1": {
			"title": "命运的开始",
			"scenes": ["intro", "forest_entrance", "first_battle"]
		},
		"chapter_2": {
			"title": "城堡的秘密",
			"scenes": ["castle_gate", "throne_room", "boss_battle"]
		}
	}

## 获取当前章节
func get_current_chapter() -> int:
	return current_chapter

## 设置当前章节
func set_current_chapter(chapter: int) -> void:
	current_chapter = chapter
	chapter_changed.emit(chapter)
	print("[NarrativeManager] Changed to chapter: ", chapter)

## 获取当前场景
func get_current_scene() -> String:
	return current_scene

## 设置当前场景
func set_current_scene(scene: String) -> void:
	current_scene = scene
	scene_changed.emit(scene)
	print("[NarrativeManager] Changed to scene: ", scene)

## 获取章节数据
func get_chapter_data(chapter: int) -> Dictionary:
	var key = "chapter_" + str(chapter)
	return story_data.get(key, {})

## 获取章节标题
func get_chapter_title(chapter: int) -> String:
	var data = get_chapter_data(chapter)
	return data.get("title", "未知章节")

## 记录选择
func record_choice(choice_id: String, option: String) -> void:
	var choice = {
		"choice_id": choice_id,
		"option": option,
		"chapter": current_chapter,
		"scene": current_scene,
		"timestamp": Time.get_unix_time_from_system()
	}
	choice_history.append(choice)
	choice_made.emit(choice_id, option)
	print("[NarrativeManager] Choice recorded: ", choice_id, " -> ", option)

## 获取选择历史
func get_choice_history() -> Array[Dictionary]:
	return choice_history

## 检查是否做过选择
func has_made_choice(choice_id: String) -> bool:
	for choice in choice_history:
		if choice.get("choice_id") == choice_id:
			return true
	return false

## 获取选择的选项
func get_choice_option(choice_id: String) -> String:
	for choice in choice_history:
		if choice.get("choice_id") == choice_id:
			return choice.get("option", "")
	return ""

## 推进剧情
func advance_story() -> void:
	var chapter_data = get_chapter_data(current_chapter)
	var scenes = chapter_data.get("scenes", [])
	
	var current_index = scenes.find(current_scene)
	if current_index < scenes.size() - 1:
		set_current_scene(scenes[current_index + 1])
	else:
		# 进入下一章
		set_current_chapter(current_chapter + 1)
		var next_chapter_data = get_chapter_data(current_chapter)
		var next_scenes = next_chapter_data.get("scenes", [])
		if not next_scenes.is_empty():
			set_current_scene(next_scenes[0])

## 重置剧情
func reset_story() -> void:
	current_chapter = 1
	current_scene = "intro"
	choice_history.clear()
	print("[NarrativeManager] Story reset")
