## 故事印记管理器
## 管理玩家选择留下的印记，影响卡牌效果和战斗规则

class_name StoryMarkManager
extends Node

# 印记类型
enum MarkType {
	KINDNESS,    # 善良
	EVIL,        # 邪恶
	NEUTRAL,     # 中立
	HIDDEN       # 隐藏
}

# 印记数据
var marks: Dictionary = {
	MarkType.KINDNESS: 0,
	MarkType.EVIL: 0,
	MarkType.NEUTRAL: 0,
	MarkType.HIDDEN: 0
}

# 印记上限
const MAX_MARKS_PER_TYPE = 10
const MAX_TOTAL_MARKS = 30

# 信号
signal mark_added(mark_type: MarkType, amount: int)
signal mark_removed(mark_type: MarkType, amount: int)
signal mark_effect_triggered(mark_type: MarkType, effect: String)

func _ready() -> void:
	initialize()

func initialize() -> void:
	print("[StoryMarkManager] Initialized")

## 添加印记
func add_mark(mark_type: MarkType, amount: int = 1) -> bool:
	if get_total_marks() >= MAX_TOTAL_MARKS:
		push_warning("[StoryMarkManager] Max total marks reached")
		return false
	
	if marks[mark_type] >= MAX_MARKS_PER_TYPE:
		push_warning("[StoryMarkManager] Max marks for type reached")
		return false
	
	marks[mark_type] += amount
	mark_added.emit(mark_type, amount)
	print("[StoryMarkManager] Added ", amount, " mark of type ", mark_type)
	
	# 检查印记效果
	_check_mark_effects(mark_type)
	
	return true

## 移除印记
func remove_mark(mark_type: MarkType, amount: int = 1) -> bool:
	if marks[mark_type] < amount:
		push_warning("[StoryMarkManager] Not enough marks to remove")
		return false
	
	marks[mark_type] -= amount
	mark_removed.emit(mark_type, amount)
	print("[StoryMarkManager] Removed ", amount, " mark of type ", mark_type)
	return true

## 获取印记数量
func get_mark_count(mark_type: MarkType) -> int:
	return marks.get(mark_type, 0)

## 获取总印记数量
func get_total_marks() -> int:
	var total = 0
	for count in marks.values():
		total += count
	return total

## 获取主要印记类型
func get_dominant_mark_type() -> MarkType:
	var max_type = MarkType.NEUTRAL
	var max_count = 0
	
	for mark_type in marks:
		if marks[mark_type] > max_count:
			max_count = marks[mark_type]
			max_type = mark_type
	
	return max_type

## 检查印记效果
func _check_mark_effects(mark_type: MarkType) -> void:
	var count = marks[mark_type]
	
	# 根据印记数量触发效果
	match mark_type:
		MarkType.KINDNESS:
			if count >= 5:
				mark_effect_triggered.emit(mark_type, "heal_bonus")
			if count >= 10:
				mark_effect_triggered.emit(mark_type, "card_draw_bonus")
		MarkType.EVIL:
			if count >= 5:
				mark_effect_triggered.emit(mark_type, "damage_bonus")
			if count >= 10:
				mark_effect_triggered.emit(mark_type, "critical_bonus")
		MarkType.NEUTRAL:
			if count >= 5:
				mark_effect_triggered.emit(mark_type, "defense_bonus")
			if count >= 10:
				mark_effect_triggered.emit(mark_type, "energy_bonus")
		MarkType.HIDDEN:
			if count >= 3:
				mark_effect_triggered.emit(mark_type, "unlock_hidden_content")

## 获取印记效果
func get_mark_effect(mark_type: MarkType) -> Dictionary:
	var count = marks[mark_type]
	var effect = {
		"type": mark_type,
		"count": count,
		"bonuses": []
	}
	
	match mark_type:
		MarkType.KINDNESS:
			if count >= 5:
				effect["bonuses"].append({"type": "heal", "value": 0.2})
			if count >= 10:
				effect["bonuses"].append({"type": "draw", "value": 1})
		MarkType.EVIL:
			if count >= 5:
				effect["bonuses"].append({"type": "damage", "value": 0.15})
			if count >= 10:
				effect["bonuses"].append({"type": "critical", "value": 0.1})
		MarkType.NEUTRAL:
			if count >= 5:
				effect["bonuses"].append({"type": "defense", "value": 0.1})
			if count >= 10:
				effect["bonuses"].append({"type": "energy", "value": 1})
		MarkType.HIDDEN:
			if count >= 3:
				effect["bonuses"].append({"type": "hidden_content", "value": 1})
	
	return effect

## 获取印记名称
func get_mark_name(mark_type: MarkType) -> String:
	match mark_type:
		MarkType.KINDNESS:
			return "Kindness"
		MarkType.EVIL:
			return "Evil"
		MarkType.NEUTRAL:
			return "Neutral"
		MarkType.HIDDEN:
			return "Hidden"
		_:
			return "Unknown"

## 获取印记描述
func get_mark_description(mark_type: MarkType) -> String:
	match mark_type:
		MarkType.KINDNESS:
			return "Obtained through kind choices, increases healing effects"
		MarkType.EVIL:
			return "Obtained through evil choices, increases damage output"
		MarkType.NEUTRAL:
			return "Obtained through neutral choices, increases defense ability"
		MarkType.HIDDEN:
			return "Obtained through special choices, unlocks hidden content"
		_:
			return ""

## 重置印记
func reset_marks() -> void:
	marks = {
		MarkType.KINDNESS: 0,
		MarkType.EVIL: 0,
		MarkType.NEUTRAL: 0,
		MarkType.HIDDEN: 0
	}
	print("[StoryMarkManager] Marks reset")
