## 选择数据定义
## 定义玩家在对话、剧情中面临的选择
## 每个选择包含文本、影响和后果
class_name ChoiceData
extends Resource

## 选择类型枚举
enum ChoiceType {
	DIALOGUE,      ## 对话选择
	STORY,         ## 剧情选择
	MORAL,         ## 道德选择
	STRATEGIC      ## 策略选择
}

## 影响类型枚举
enum ImpactType {
	NONE,          ## 无影响
	STORY_MARK,    ## 故事印记
	RULE_REWRITE,  ## 规则改写
	ELEMENT,       ## 元素改变
	NPC_RELATION,  ## NPC关系
	WORLD_STATE    ## 世界状态
}

## 选择唯一标识
@export var id: String = ""

## 选择显示文本
@export var text: String = ""

## 选择类型
@export var type: ChoiceType = ChoiceType.DIALOGUE

## 是否是关键选择（影响剧情走向）
@export var is_critical: bool = false

## 选择的直接影响
@export var immediate_impact: ImpactType = ImpactType.NONE

## 影响值（根据影响类型不同含义不同）
@export var impact_value: int = 0

## 影响的目标ID（如NPC ID、元素类型等）
@export var impact_target: String = ""

## 后续选择ID（触发后续选择）
@export var next_choice_id: String = ""

## 选择的前置条件
@export var prerequisites: Array[String] = []

## 选择的锁定条件
@export var lock_conditions: Array[String] = []

## 选择的描述（详细说明选择的含义）
@export var description: String = ""

## 选择的图标（可选）
@export var icon: Texture2D = null

## 检查选择是否可用
func is_available(player_marks: Array[String], player_choices: Array[String]) -> bool:
	# 检查锁定条件
	for condition in lock_conditions:
		if condition in player_marks or condition in player_choices:
			return false
	
	# 检查前置条件
	for prereq in prerequisites:
		if prereq not in player_marks and prereq not in player_choices:
			return false
	
	return true

## 获取选择的影响描述
func get_impact_description() -> String:
	match immediate_impact:
		ImpactType.STORY_MARK:
			return "获得故事印记: %s" % impact_target
		ImpactType.RULE_REWRITE:
			return "触发规则改写: %s" % impact_target
		ImpactType.ELEMENT:
			return "改变元素: %s" % impact_target
		ImpactType.NPC_RELATION:
			return "影响NPC关系: %s" % impact_target
		ImpactType.WORLD_STATE:
			return "改变世界状态: %s" % impact_target
		_:
			return "无直接影响"

## 克隆选择数据
func clone() -> ChoiceData:
	var clone_data = ChoiceData.new()
	clone_data.id = id
	clone_data.text = text
	clone_data.type = type
	clone_data.is_critical = is_critical
	clone_data.immediate_impact = immediate_impact
	clone_data.impact_value = impact_value
	clone_data.impact_target = impact_target
	clone_data.next_choice_id = next_choice_id
	clone_data.prerequisites = prerequisites.duplicate()
	clone_data.lock_conditions = lock_conditions.duplicate()
	clone_data.description = description
	clone_data.icon = icon
	return clone_data
