## 技能树数据库
## 管理所有技能定义的外部数据源
class_name SkillTreeDatabase
extends Node

## 技能定义资源文件路径
const SKILL_DATA_DIR: String = "res://data/skills/"

## 所有技能定义（skill_id -> SkillData）
var skill_definitions: Dictionary = {}

## 技能类别映射（category -> Array[skill_id]）
var skill_categories: Dictionary = {}

## 默认技能数据（内联定义，作为Resource文件不可用时的回退）
const DEFAULT_SKILL_DEFINITIONS: Dictionary = {
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

func _ready() -> void:
	_load_skill_definitions()

## 加载技能定义（优先从Resource文件加载，否则使用默认数据）
func _load_skill_definitions() -> void:
	# 尝试从Resource目录加载
	var loaded_count: int = _load_from_resource_dir()

	# 如果没有从Resource加载到数据，使用默认数据
	if loaded_count == 0:
		_load_default_definitions()

## 从Resource目录加载技能定义
func _load_from_resource_dir() -> int:
	var count: int = 0
	var dir: DirAccess = DirAccess.open(SKILL_DATA_DIR)
	if dir == null:
		return 0

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres") or file_name.ends_with(".res"):
			var skill_data: SkillData = load(SKILL_DATA_DIR + file_name) as SkillData
			if skill_data and not skill_data.skill_id.is_empty():
				skill_definitions[skill_data.skill_id] = skill_data
				_add_to_category(skill_data.category, skill_data.skill_id)
				count += 1
		file_name = dir.get_next()
	dir.list_dir_end()

	return count

## 从默认字典加载技能定义
func _load_default_definitions() -> void:
	for category: String in DEFAULT_SKILL_DEFINITIONS:
		var skills: Dictionary = DEFAULT_SKILL_DEFINITIONS[category]
		for skill_id: String in skills:
			var data: Dictionary = skills[skill_id]
			var skill_data: SkillData = SkillData.from_dict(skill_id, category, data)
			skill_definitions[skill_id] = skill_data
			_add_to_category(category, skill_id)

## 添加技能到类别
func _add_to_category(category: String, skill_id: String) -> void:
	if not skill_categories.has(category):
		skill_categories[category] = []
	if not skill_categories[category].has(skill_id):
		skill_categories[category].append(skill_id)

## 获取技能定义
func get_skill_definition(skill_id: String) -> SkillData:
	return skill_definitions.get(skill_id, null)

## 获取所有技能定义
func get_all_definitions() -> Dictionary:
	return skill_definitions

## 获取指定类别的技能ID列表
func get_skills_in_category(category: String) -> Array[String]:
	return skill_categories.get(category, [])

## 获取所有类别
func get_categories() -> Array[String]:
	var categories: Array[String] = []
	for category: String in skill_categories:
		categories.append(category)
	return categories

## 检查技能是否存在
func has_skill(skill_id: String) -> bool:
	return skill_definitions.has(skill_id)
