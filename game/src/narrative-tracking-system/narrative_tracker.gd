## 剧情追踪器
## 追踪游戏中的剧情进度、分支和解锁条件
## 管理主线剧情、支线剧情和隐藏剧情
class_name NarrativeTracker
extends Node

## 剧情进度信号
signal story_progressed(story_id: String, progress: int)
signal story_branch_unlocked(story_id: String, branch_id: String)
signal hidden_story_discovered(story_id: String)

## 剧情类型枚举
enum StoryType {
	MAIN,          ## 主线剧情
	SIDE,          ## 支线剧情
	HIDDEN,        ## 隐藏剧情
	CHAIN          ## 连环剧情
}

## 剧情状态枚举
enum StoryState {
	LOCKED,        ## 未解锁
	AVAILABLE,     ## 可进行
	IN_PROGRESS,   ## 进行中
	COMPLETED,     ## 已完成
	FAILED         ## 已失败
}

## 剧情数据结构
class StoryData extends RefCounted:
	var id: String = ""
	var type: StoryType = StoryType.MAIN
	var state: StoryState = StoryState.LOCKED
	var progress: int = 0
	var max_progress: int = 100
	var branches: Array[String] = []
	var unlocked_branches: Array[String] = []
	var prerequisites: Array[String] = []
	var rewards: Array[String] = []
	var description: String = ""

## 剧情数据库
var story_database: Dictionary = {}

## 剧情进度
var story_progress: Dictionary = {}

## 已解锁的剧情分支
var unlocked_branches: Dictionary = {}

## 已发现的隐藏剧情
var discovered_hidden_stories: Array[String] = []

## 剧情历史记录
var story_history: Array[Dictionary] = []

## 初始化剧情追踪器
func _ready() -> void:
	# 初始化剧情数据
	_initialize_story_data()

## 初始化剧情数据
func _initialize_story_data() -> void:
	# 主线剧情
	_add_story("main_awakening", StoryType.MAIN, "觉醒之旅", 100)
	_add_story("main_element_master", StoryType.MAIN, "元素掌控", 100)
	_add_story("main_fate_defiance", StoryType.MAIN, "命运抗争", 100)
	
	# 支线剧情
	_add_story("side_village_mystery", StoryType.SIDE, "村庄之谜", 50)
	_add_story("side_lost_artifact", StoryType.SIDE, "失落遗物", 30)
	_add_story("side_npc_backstory", StoryType.SIDE, "NPC往事", 40)
	
	# 连环剧情
	_add_story("chain_elemental_trials", StoryType.CHAIN, "元素试炼", 80)
	_add_story("chain_fate_tangled", StoryType.CHAIN, "命运交织", 60)
	
	# 隐藏剧情
	_add_story("hidden_true_ending", StoryType.HIDDEN, "真实结局", 100)
	_add_story("hidden_secret_character", StoryType.HIDDEN, "秘密角色", 50)

## 添加剧情
func _add_story(story_id: String, type: StoryType, description: String, max_progress: int) -> void:
	var story = StoryData.new()
	story.id = story_id
	story.type = type
	story.state = StoryState.LOCKED if type != StoryType.MAIN else StoryState.AVAILABLE
	story.max_progress = max_progress
	story.description = description
	story_database[story_id] = story

## 推进剧情进度
func progress_story(story_id: String, amount: int = 1) -> void:
	if story_id not in story_database:
		push_warning("Story not found: %s" % story_id)
		return
	
	var story = story_database[story_id]
	if story.state == StoryState.LOCKED or story.state == StoryState.COMPLETED:
		return
	
	# 更新状态
	if story.state == StoryState.AVAILABLE:
		story.state = StoryState.IN_PROGRESS
	
	# 更新进度
	story.progress = mini(story.progress + amount, story.max_progress)
	story_progress[story_id] = story.progress
	
	# 发射信号
	story_progressed.emit(story_id, story.progress)
	
	# 检查是否完成
	if story.progress >= story.max_progress:
		_complete_story(story_id)
	
	# 记录历史
	_record_story_event(story_id, "progress", amount)

## 完成剧情
func _complete_story(story_id: String) -> void:
	var story = story_database[story_id]
	story.state = StoryState.COMPLETED
	
	# 解锁后续剧情
	_unlock_dependent_stories(story_id)
	
	# 记录历史
	_record_story_event(story_id, "completed", 0)

## 解锁依赖的剧情
func _unlock_dependent_stories(completed_story_id: String) -> void:
	for story_id in story_database:
		var story = story_database[story_id]
		if completed_story_id in story.prerequisites:
			if story.state == StoryState.LOCKED:
				story.state = StoryState.AVAILABLE
				# 如果是隐藏剧情，发射发现信号
				if story.type == StoryType.HIDDEN:
					discovered_hidden_stories.append(story_id)
					hidden_story_discovered.emit(story_id)

## 解锁剧情分支
func unlock_branch(story_id: String, branch_id: String) -> void:
	if story_id not in story_database:
		return
	
	var story = story_database[story_id]
	if branch_id not in story.unlocked_branches:
		story.unlocked_branches.append(branch_id)
		if story_id not in unlocked_branches:
			unlocked_branches[story_id] = []
		unlocked_branches[story_id].append(branch_id)
		story_branch_unlocked.emit(story_id, branch_id)

## 获取剧情状态
func get_story_state(story_id: String) -> StoryState:
	if story_id in story_database:
		return story_database[story_id].state
	return StoryState.LOCKED

## 获取剧情进度
func get_story_progress(story_id: String) -> int:
	return story_progress.get(story_id, 0)

## 获取剧情进度百分比
func get_story_progress_percent(story_id: String) -> float:
	if story_id not in story_database:
		return 0.0
	var story = story_database[story_id]
	if story.max_progress == 0:
		return 100.0
	return (float(story.progress) / float(story.max_progress)) * 100.0

## 检查剧情是否完成
func is_story_completed(story_id: String) -> bool:
	return get_story_state(story_id) == StoryState.COMPLETED

## 获取所有可用剧情
func get_available_stories() -> Array[String]:
	var available: Array[String] = []
	for story_id in story_database:
		var story = story_database[story_id]
		if story.state == StoryState.AVAILABLE or story.state == StoryState.IN_PROGRESS:
			available.append(story_id)
	return available

## 获取已完成剧情
func get_completed_stories() -> Array[String]:
	var completed: Array[String] = []
	for story_id in story_database:
		if is_story_completed(story_id):
			completed.append(story_id)
	return completed

## 获取已发现的隐藏剧情
func get_discovered_hidden_stories() -> Array[String]:
	return discovered_hidden_stories.duplicate()

## 记录剧情事件
func _record_story_event(story_id: String, event_type: String, value: int) -> void:
	var event = {
		"story_id": story_id,
		"event_type": event_type,
		"value": value,
		"timestamp": Time.get_unix_time_from_system()
	}
	story_history.append(event)

## 获取剧情历史
func get_story_history() -> Array[Dictionary]:
	return story_history.duplicate()

## 保存剧情数据
func save_data() -> Dictionary:
	var stories_data = {}
	for story_id in story_database:
		var story = story_database[story_id]
		stories_data[story_id] = {
			"state": story.state,
			"progress": story.progress,
			"unlocked_branches": story.unlocked_branches
		}
	
	return {
		"stories": stories_data,
		"unlocked_branches": unlocked_branches,
		"discovered_hidden_stories": discovered_hidden_stories,
		"story_history": story_history
	}

## 加载剧情数据
func load_data(data: Dictionary) -> void:
	var stories_data = data.get("stories", {})
	for story_id in stories_data:
		if story_id in story_database:
			var story = story_database[story_id]
			var story_data = stories_data[story_id]
			story.state = story_data.get("state", StoryState.LOCKED)
			story.progress = story_data.get("progress", 0)
			story.unlocked_branches = story_data.get("unlocked_branches", [])
	
	unlocked_branches = data.get("unlocked_branches", {})
	discovered_hidden_stories = data.get("discovered_hidden_stories", [])
	story_history = data.get("story_history", [])

## 重置剧情系统
func reset() -> void:
	story_progress.clear()
	unlocked_branches.clear()
	discovered_hidden_stories.clear()
	story_history.clear()
	_initialize_story_data()
