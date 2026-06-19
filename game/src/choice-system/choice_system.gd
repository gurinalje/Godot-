## 选择系统
## 管理玩家选择和选择影响

class_name ChoiceSystem
extends Node

# 选择类型
enum ChoiceType {
	DIALOGUE,      # 对话选择
	STORY,         # 剧情选择
	MORAL,         # 道德选择
	STRATEGIC      # 策略选择
}

# 选择历史
var choice_history: Array[Dictionary] = []

# 当前选择
var current_choice: Dictionary = {}

# 信号
signal choice_presented(choice_id: String, options: Array)
signal choice_made(choice_id: String, option: String)
signal choice_consequence(choice_id: String, consequence: String)

func _ready() -> void:
	initialize()

func initialize() -> void:
	print("[ChoiceSystem] Initialized")

## 呈现选择
func present_choice(choice_id: String, options: Array, choice_type: ChoiceType = ChoiceType.DIALOGUE) -> void:
	current_choice = {
		"id": choice_id,
		"options": options,
		"type": choice_type,
		"timestamp": Time.get_unix_time_from_system()
	}
	choice_presented.emit(choice_id, options)
	print("[ChoiceSystem] Presented choice: ", choice_id)

## 做出选择
func make_choice(option: String) -> void:
	if current_choice.is_empty():
		push_warning("[ChoiceSystem] No current choice")
		return
	
	var choice_id = current_choice.get("id", "")
	
	# 记录选择
	var choice_record = {
		"id": choice_id,
		"option": option,
		"type": current_choice.get("type", ChoiceType.DIALOGUE),
		"timestamp": Time.get_unix_time_from_system()
	}
	choice_history.append(choice_record)
	
	# 处理选择后果
	_process_choice_consequences(choice_id, option)
	
	choice_made.emit(choice_id, option)
	current_choice.clear()
	print("[ChoiceSystem] Choice made: ", choice_id, " -> ", option)

## 处理选择后果
func _process_choice_consequences(choice_id: String, option: String) -> void:
	# 根据选择类型处理后果
	match choice_id:
		"moral_choice":
			_handle_moral_choice(option)
		"story_choice":
			_handle_story_choice(option)
		_:
			pass

## 处理道德选择
func _handle_moral_choice(option: String) -> void:
	var story_mark_manager = GameManager.get_system("StoryMarkManager")
	if not story_mark_manager:
		return
	
	match option:
		"kind":
			story_mark_manager.add_mark(StoryMarkManager.MarkType.KINDNESS)
			choice_consequence.emit("moral_choice", "Kindness mark +1")
		"evil":
			story_mark_manager.add_mark(StoryMarkManager.MarkType.EVIL)
			choice_consequence.emit("moral_choice", "Evil mark +1")
		"neutral":
			story_mark_manager.add_mark(StoryMarkManager.MarkType.NEUTRAL)
			choice_consequence.emit("moral_choice", "Neutral mark +1")

## 处理剧情选择
func _handle_story_choice(option: String) -> void:
	var narrative_manager = GameManager.get_system("NarrativeManager")
	if narrative_manager:
		narrative_manager.record_choice("story_choice", option)

## 获取选择历史
func get_choice_history() -> Array[Dictionary]:
	return choice_history

## 检查是否做过选择
func has_made_choice(choice_id: String) -> bool:
	for choice in choice_history:
		if choice.get("id") == choice_id:
			return true
	return false

## 获取选择的选项
func get_choice_option(choice_id: String) -> String:
	for choice in choice_history:
		if choice.get("id") == choice_id:
			return choice.get("option", "")
	return ""

## 获取当前选择
func get_current_choice() -> Dictionary:
	return current_choice

## 检查是否有待做选择
func has_pending_choice() -> bool:
	return not current_choice.is_empty()

## 重置选择系统
func reset_choices() -> void:
	choice_history.clear()
	current_choice.clear()
	print("[ChoiceSystem] Choices reset")
