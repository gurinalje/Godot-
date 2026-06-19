## 技能树管理器
## 管理角色技能树和技能解锁
class_name SkillTreeManager
extends Node

## 技能点
var skill_points: int = 0

## 已解锁技能
var unlocked_skills: Array[String] = []

## 技能树数据库引用（通过GameManager获取）
var _skill_tree_database: SkillTreeDatabase = null

# 信号
## 技能解锁时发出
signal skill_unlocked(skill_id: String)
## 技能点变化时发出
signal skill_points_changed(new_amount: int)

func _ready() -> void:
	initialize()

func initialize() -> void:
	# 通过GameManager获取系统引用
	_skill_tree_database = _get_skill_tree_database()
	if _skill_tree_database == null:
		push_warning("[SkillTreeManager] SkillTreeDatabase not found, creating local instance")
		_skill_tree_database = SkillTreeDatabase.new()
		_skill_tree_database._ready()

	print("[SkillTreeManager] Initialized")

## 获取技能点
func get_skill_points() -> int:
	return skill_points

## 增加技能点
func add_skill_points(amount: int) -> void:
	skill_points += amount
	skill_points_changed.emit(skill_points)
	print("[SkillTreeManager] Added ", amount, " skill points")

## 检查技能是否解锁
func is_skill_unlocked(skill_id: String) -> bool:
	return skill_id in unlocked_skills

## 解锁技能
func unlock_skill(skill_id: String) -> bool:
	if is_skill_unlocked(skill_id):
		push_warning("[SkillTreeManager] Skill already unlocked: " + skill_id)
		return false

	var skill_data: SkillData = _get_skill_data(skill_id)
	if skill_data == null:
		push_warning("[SkillTreeManager] Skill not found: " + skill_id)
		return false

	# 检查技能点
	if skill_points < skill_data.cost:
		push_warning("[SkillTreeManager] Not enough skill points")
		return false

	# 检查前置技能
	if not _check_prerequisites(skill_data):
		return false

	# 解锁技能
	skill_points -= skill_data.cost
	unlocked_skills.append(skill_id)
	skill_unlocked.emit(skill_id)
	skill_points_changed.emit(skill_points)
	print("[SkillTreeManager] Unlocked skill: ", skill_id)
	return true

## 检查前置技能是否满足
func _check_prerequisites(skill_data: SkillData) -> bool:
	for prereq: String in skill_data.prerequisites:
		if not is_skill_unlocked(prereq):
			push_warning("[SkillTreeManager] Missing requirement: " + prereq)
			return false
	return true

## 获取技能数据
func _get_skill_data(skill_id: String) -> SkillData:
	if _skill_tree_database == null:
		return null
	return _skill_tree_database.get_skill_definition(skill_id)

## 获取技能名称
func get_skill_name(skill_id: String) -> String:
	var data: SkillData = _get_skill_data(skill_id)
	if data == null:
		return ""
	return data.skill_name

## 获取技能描述
func get_skill_description(skill_id: String) -> String:
	var data: SkillData = _get_skill_data(skill_id)
	if data == null:
		return ""
	return data.description

## 获取技能消耗
func get_skill_cost(skill_id: String) -> int:
	var data: SkillData = _get_skill_data(skill_id)
	if data == null:
		return 0
	return data.cost

## 获取技能前置
func get_skill_requires(skill_id: String) -> Array[String]:
	var data: SkillData = _get_skill_data(skill_id)
	if data == null:
		return []
	return data.prerequisites

## 获取技能效果
func get_skill_effects(skill_id: String) -> Dictionary:
	var data: SkillData = _get_skill_data(skill_id)
	if data == null:
		return {}
	return data.effects

## 获取所有技能
func get_all_skills() -> Array[String]:
	if _skill_tree_database == null:
		return []
	var skills: Array[String] = []
	var definitions: Dictionary = _skill_tree_database.get_all_definitions()
	for skill_id: String in definitions:
		skills.append(skill_id)
	return skills

## 获取指定类别的技能
func get_skills_in_category(category: String) -> Array[String]:
	if _skill_tree_database == null:
		return []
	return _skill_tree_database.get_skills_in_category(category)

## 获取所有类别
func get_categories() -> Array[String]:
	if _skill_tree_database == null:
		return []
	return _skill_tree_database.get_categories()

## 获取已解锁技能
func get_unlocked_skills() -> Array[String]:
	return unlocked_skills

## 重置技能树
func reset_skill_tree() -> void:
	var total_points: int = 0
	for skill_id: String in unlocked_skills:
		total_points += get_skill_cost(skill_id)

	unlocked_skills.clear()
	skill_points += total_points
	skill_points_changed.emit(skill_points)
	print("[SkillTreeManager] Skill tree reset")

#region 系统引用获取（通过GameManager依赖注入）

## 获取SkillTreeDatabase引用
func _get_skill_tree_database() -> SkillTreeDatabase:
	var game_manager: Node = _get_game_manager()
	if game_manager:
		var db: Node = game_manager.get_node_or_null("SkillTreeDatabase")
		if db is SkillTreeDatabase:
			return db as SkillTreeDatabase
	# 回退：检查自动加载
	return get_node_or_null("/root/SkillTreeDatabase") as SkillTreeDatabase

## 获取GameManager引用
func _get_game_manager() -> Node:
	return get_node_or_null("/root/GameManager")

#endregion
