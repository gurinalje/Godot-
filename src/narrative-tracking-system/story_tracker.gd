## 剧情追踪管理器
## 管理游戏中的剧情进度和追踪

class_name StoryTracker
extends Node

# 剧情进度
var story_progress: Dictionary = {}

# 当前章节
var current_chapter: int = 1

# 当前任务
var active_quests: Array[Dictionary] = []

# 已完成任务
var completed_quests: Array[String] = []

# 信号
signal quest_started(quest_id: String)
signal quest_completed(quest_id: String)
signal chapter_changed(chapter: int)

func _ready() -> void:
	initialize()

func initialize() -> void:
	print("[StoryTracker] Initialized")
	_load_story_progress()

## 加载剧情进度
func _load_story_progress() -> void:
	# TODO: 从文件加载剧情进度
	story_progress = {
		"chapter_1": {
			"title": "命运的开始",
			"completed": false,
			"quests": ["first_battle", "meet_merchant"]
		},
		"chapter_2": {
			"title": "城堡的秘密",
			"completed": false,
			"quests": ["explore_castle", "defeat_boss"]
		}
	}

## 获取当前章节
func get_current_chapter() -> int:
	return current_chapter

## 设置当前章节
func set_current_chapter(chapter: int) -> void:
	current_chapter = chapter
	chapter_changed.emit(chapter)
	print("[StoryTracker] Changed to chapter: ", chapter)

## 获取章节数据
func get_chapter_data(chapter: int) -> Dictionary:
	var key = "chapter_" + str(chapter)
	return story_progress.get(key, {})

## 获取章节标题
func get_chapter_title(chapter: int) -> String:
	var data = get_chapter_data(chapter)
	return data.get("title", "")

## 检查章节是否完成
func is_chapter_completed(chapter: int) -> bool:
	var data = get_chapter_data(chapter)
	return data.get("completed", false)

## 完成章节
func complete_chapter(chapter: int) -> void:
	var key = "chapter_" + str(chapter)
	if story_progress.has(key):
		story_progress[key]["completed"] = true
		print("[StoryTracker] Completed chapter: ", chapter)

## 开始任务
func start_quest(quest_id: String, quest_data: Dictionary) -> void:
	quest_data["id"] = quest_id
	quest_data["started_at"] = Time.get_unix_time_from_system()
	active_quests.append(quest_data)
	quest_started.emit(quest_id)
	print("[StoryTracker] Started quest: ", quest_id)

## 完成任务
func complete_quest(quest_id: String) -> void:
	for i in range(active_quests.size()):
		if active_quests[i].get("id") == quest_id:
			active_quests.remove_at(i)
			completed_quests.append(quest_id)
			quest_completed.emit(quest_id)
			print("[StoryTracker] Completed quest: ", quest_id)
			return

## 检查任务是否激活
func is_quest_active(quest_id: String) -> bool:
	for quest in active_quests:
		if quest.get("id") == quest_id:
			return true
	return false

## 检查任务是否完成
func is_quest_completed(quest_id: String) -> bool:
	return quest_id in completed_quests

## 获取激活的任务
func get_active_quests() -> Array[Dictionary]:
	return active_quests

## 获取已完成的任务
func get_completed_quests() -> Array[String]:
	return completed_quests

## 获取任务数据
func get_quest_data(quest_id: String) -> Dictionary:
	for quest in active_quests:
		if quest.get("id") == quest_id:
			return quest
	return {}

## 更新任务进度
func update_quest_progress(quest_id: String, progress: Dictionary) -> void:
	for i in range(active_quests.size()):
		if active_quests[i].get("id") == quest_id:
			active_quests[i]["progress"] = progress
			print("[StoryTracker] Updated quest progress: ", quest_id)
			return

## 重置剧情追踪
func reset_story_tracking() -> void:
	story_progress.clear()
	active_quests.clear()
	completed_quests.clear()
	current_chapter = 1
	print("[StoryTracker] Story tracking reset")
