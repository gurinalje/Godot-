## 技能树管理器
## 管理角色技能树和技能解锁

class_name SkillTreeManager
extends Node

# 技能点
var skill_points: int = 0

# 已解锁技能
var unlocked_skills: Array[String] = []

# 技能树数据
var skill_tree: Dictionary = {}

# 信号
signal skill_unlocked(skill_id: String)
signal skill_points_changed(new_amount: int)

func _ready() -> void:
	initialize()

func initialize() -> void:
	print("[SkillTreeManager] Initialized")
	_load_skill_tree()

## 加载技能树
func _load_skill_tree() -> void:
	# TODO: 从文件加载技能树数据
	skill_tree = {
		"warrior": {
			"slash": {
				"name": "劈砍",
				"description": "基础近战攻击",
				"cost": 1,
				"requires": [],
				"effects": {"damage": 5}
			},
			"power_strike": {
				"name": "重击",
				"description": "强力一击，造成双倍伤害",
				"cost": 2,
				"requires": ["slash"],
				"effects": {"damage": 10, "cooldown": 3}
			},
			"shield_bash": {
				"name": "盾击",
				"description": "用盾牌攻击，有几率眩晕",
				"cost": 2,
				"requires": ["slash"],
				"effects": {"damage": 3, "stun_chance": 0.3}
			}
		},
		"mage": {
			"fireball": {
				"name": "火球术",
				"description": "发射一个火球",
				"cost": 1,
				"requires": [],
				"effects": {"damage": 8, "element": "fire"}
			},
			"ice_lance": {
				"name": "冰矛",
				"description": "发射冰矛，有几率冰冻",
				"cost": 2,
				"requires": ["fireball"],
				"effects": {"damage": 6, "freeze_chance": 0.2}
			},
			"lightning_storm": {
				"name": "闪电风暴",
				"description": "召唤闪电攻击所有敌人",
				"cost": 3,
				"requires": ["ice_lance"],
				"effects": {"damage": 4, "targets": "all"}
			}
		}
	}

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
	
	var skill_data = _get_skill_data(skill_id)
	if skill_data.is_empty():
		push_warning("[SkillTreeManager] Skill not found: " + skill_id)
		return false
	
	# 检查技能点
	if skill_points < skill_data.get("cost", 0):
		push_warning("[SkillTreeManager] Not enough skill points")
		return false
	
	# 检查前置技能
	var requires = skill_data.get("requires", [])
	for req in requires:
		if not is_skill_unlocked(req):
			push_warning("[SkillTreeManager] Missing requirement: " + req)
			return false
	
	# 解锁技能
	skill_points -= skill_data.get("cost", 0)
	unlocked_skills.append(skill_id)
	skill_unlocked.emit(skill_id)
	skill_points_changed.emit(skill_points)
	print("[SkillTreeManager] Unlocked skill: ", skill_id)
	return true

## 获取技能数据
func _get_skill_data(skill_id: String) -> Dictionary:
	for tree in skill_tree.values():
		if tree.has(skill_id):
			return tree[skill_id]
	return {}

## 获取技能名称
func get_skill_name(skill_id: String) -> String:
	var data = _get_skill_data(skill_id)
	return data.get("name", "")

## 获取技能描述
func get_skill_description(skill_id: String) -> String:
	var data = _get_skill_data(skill_id)
	return data.get("description", "")

## 获取技能消耗
func get_skill_cost(skill_id: String) -> int:
	var data = _get_skill_data(skill_id)
	return data.get("cost", 0)

## 获取技能前置
func get_skill_requires(skill_id: String) -> Array:
	var data = _get_skill_data(skill_id)
	return data.get("requires", [])

## 获取技能效果
func get_skill_effects(skill_id: String) -> Dictionary:
	var data = _get_skill_data(skill_id)
	return data.get("effects", {})

## 获取所有技能
func get_all_skills() -> Array[String]:
	var skills: Array[String] = []
	for tree in skill_tree.values():
		for skill_id in tree.keys():
			skills.append(skill_id)
	return skills

## 获取已解锁技能
func get_unlocked_skills() -> Array[String]:
	return unlocked_skills

## 重置技能树
func reset_skill_tree() -> void:
	var total_points = 0
	for skill_id in unlocked_skills:
		total_points += get_skill_cost(skill_id)
	
	unlocked_skills.clear()
	skill_points += total_points
	skill_points_changed.emit(skill_points)
	print("[SkillTreeManager] Skill tree reset")
