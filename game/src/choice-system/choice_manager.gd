## 选择管理器
## 管理玩家的选择历史、当前选择和选择后果
## 是游戏选择系统的核心，连接对话系统、故事印记系统和规则改写系统
class_name ChoiceManager
extends Node

## 选择历史信号
signal choice_made(choice_id: String, choice_data: ChoiceData)
signal choice_history_changed()

## 当前可用选择信号
signal available_choices_changed(choices: Array[ChoiceData])

## 玩家选择历史（按时间顺序）
var choice_history: Array[String] = []

## 玩家获得的故事印记
var story_marks: Array[String] = []

## 当前可用的选择
var available_choices: Array[ChoiceData] = []

## 选择数据存储
var choice_database: Dictionary = {}

## 选择结果缓存
var choice_results: Dictionary = {}

## 初始化选择管理器
func _ready() -> void:
	# 加载选择数据
	_load_choice_data()

## 加载选择数据
func _load_choice_data() -> void:
	# 从文件系统加载所有选择数据
	var choice_dir = "res://data/choices/"
	var dir = DirAccess.open(choice_dir)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var choice = load(choice_dir + file_name) as ChoiceData
				if choice:
					choice_database[choice.id] = choice
			file_name = dir.get_next()

## 设置可用选择
func set_available_choices(choices: Array[ChoiceData]) -> void:
	available_choices.clear()
	for choice in choices:
		if choice.is_available(story_marks, choice_history):
			available_choices.append(choice)
	available_choices_changed.emit(available_choices)

## 做出选择
func make_choice(choice_id: String) -> bool:
	# 检查选择是否可用
	var choice_data = _find_choice(choice_id)
	if not choice_data:
		push_warning("Choice not found: %s" % choice_id)
		return false
	
	# 检查选择是否在可用列表中
	if choice_data not in available_choices:
		push_warning("Choice not available: %s" % choice_id)
		return false
	
	# 记录选择
	choice_history.append(choice_id)
	
	# 处理选择后果
	_process_choice_consequences(choice_data)
	
	# 发射信号
	choice_made.emit(choice_id, choice_data)
	choice_history_changed.emit()
	
	# 触发后续选择
	if choice_data.next_choice_id != "":
		var next_choice = _find_choice(choice_data.next_choice_id)
		if next_choice:
			set_available_choices([next_choice])
	
	return true

## 处理选择后果
func _process_choice_consequences(choice: ChoiceData) -> void:
	match choice.immediate_impact:
		ChoiceData.ImpactType.STORY_MARK:
			_add_story_mark(choice.impact_target)
		ChoiceData.ImpactType.RULE_REWRITE:
			# 触发规则改写系统
			_trigger_rule_rewrite(choice.impact_target, choice.impact_value)
		ChoiceData.ImpactType.ELEMENT:
			# 触发元素系统
			_trigger_element_change(choice.impact_target)
		ChoiceData.ImpactType.NPC_RELATION:
			# 触发NPC关系变化
			_trigger_npc_relation_change(choice.impact_target, choice.impact_value)
		ChoiceData.ImpactType.WORLD_STATE:
			# 触发世界状态变化
			_trigger_world_state_change(choice.impact_target, choice.impact_value)

## 添加故事印记
func _add_story_mark(mark_id: String) -> void:
	if mark_id not in story_marks:
		story_marks.append(mark_id)
		# 发射故事印记系统信号
		var story_mark_system = GameManager.get_system("StoryMarkManager")
		if story_mark_system:
			story_mark_system.add_mark(mark_id)

## 触发规则改写
func _trigger_rule_rewrite(rule_id: String, value: int) -> void:
	# 规则改写系统将在后续实现
	pass

## 触发元素变化
func _trigger_element_change(element: String) -> void:
	# 元素系统已实现，可以调用
	pass

## 触发NPC关系变化
func _trigger_npc_relation_change(npc_id: String, value: int) -> void:
	# NPC系统将在后续实现
	pass

## 触发世界状态变化
func _trigger_world_state_change(state_id: String, value: int) -> void:
	# 世界状态系统将在后续实现
	pass

## 查找选择数据
func _find_choice(choice_id: String) -> ChoiceData:
	return choice_database.get(choice_id, null)

## 检查是否做过某个选择
func has_made_choice(choice_id: String) -> bool:
	return choice_id in choice_history

## 检查是否有某个故事印记
func has_story_mark(mark_id: String) -> bool:
	return mark_id in story_marks

## 获取选择历史
func get_choice_history() -> Array[String]:
	return choice_history.duplicate()

## 获取故事印记
func get_story_marks() -> Array[String]:
	return story_marks.duplicate()

## 获取选择统计
func get_choice_stats() -> Dictionary:
	return {
		"total_choices": choice_history.size(),
		"story_marks": story_marks.size(),
		"critical_choices": _count_critical_choices()
	}

## 统计关键选择数量
func _count_critical_choices() -> int:
	var count = 0
	for choice_id in choice_history:
		var choice = _find_choice(choice_id)
		if choice and choice.is_critical:
			count += 1
	return count

## 保存选择数据
func save_data() -> Dictionary:
	return {
		"choice_history": choice_history,
		"story_marks": story_marks,
		"choice_results": choice_results
	}

## 加载选择数据
func load_data(data: Dictionary) -> void:
	choice_history = data.get("choice_history", [])
	story_marks = data.get("story_marks", [])
	choice_results = data.get("choice_results", {})
	choice_history_changed.emit()

## 重置选择系统
func reset() -> void:
	choice_history.clear()
	story_marks.clear()
	available_choices.clear()
	choice_results.clear()
	choice_history_changed.emit()
