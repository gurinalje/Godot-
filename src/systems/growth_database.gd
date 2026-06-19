## 成长属性数据库
## 管理所有属性定义的外部数据源
class_name GrowthDatabase
extends Node

## 属性定义资源文件路径
const GROWTH_DATA_DIR: String = "res://data/growth/"

## 所有属性定义（stat_id -> GrowthConfig）
var stat_definitions: Dictionary = {}

## 默认属性数据（内联定义，作为Resource文件不可用时的回退）
const DEFAULT_STAT_DEFINITIONS: Dictionary = {
	"strength": {
		"display_name": "力量",
		"description": "增加物理攻击力",
		"default_value": 10,
		"stat_color": Color(1.0, 0.3, 0.3)
	},
	"dexterity": {
		"display_name": "敏捷",
		"description": "增加暴击率和闪避率",
		"default_value": 10,
		"stat_color": Color(0.3, 1.0, 0.3)
	},
	"intelligence": {
		"display_name": "智力",
		"description": "增加魔法攻击力和法力值",
		"default_value": 10,
		"stat_color": Color(0.3, 0.3, 1.0)
	},
	"constitution": {
		"display_name": "体质",
		"description": "增加生命值和防御力",
		"default_value": 10,
		"stat_color": Color(1.0, 0.8, 0.2)
	},
	"luck": {
		"display_name": "幸运",
		"description": "增加掉落率和暴击伤害",
		"default_value": 10,
		"stat_color": Color(0.8, 0.3, 1.0)
	}
}

func _ready() -> void:
	_load_stat_definitions()

## 加载属性定义（优先从Resource文件加载，否则使用默认数据）
func _load_stat_definitions() -> void:
	# 尝试从Resource目录加载
	var dir: DirAccess = DirAccess.open(GROWTH_DATA_DIR)
	if dir:
		dir.list_dir_begin()
		var file_name: String = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres") or file_name.ends_with(".res"):
				var config: GrowthConfig = load(GROWTH_DATA_DIR + file_name) as GrowthConfig
				if config and not config.stat_id.is_empty():
					stat_definitions[config.stat_id] = config
			file_name = dir.get_next()
		dir.list_dir_end()

	# 如果没有从Resource加载到数据，使用默认数据
	if stat_definitions.is_empty():
		_load_default_definitions()

## 从默认字典加载属性定义
func _load_default_definitions() -> void:
	for stat_id: String in DEFAULT_STAT_DEFINITIONS:
		var data: Dictionary = DEFAULT_STAT_DEFINITIONS[stat_id]
		stat_definitions[stat_id] = GrowthConfig.from_dict(stat_id, data)

## 获取属性定义
func get_stat_definition(stat_id: String) -> GrowthConfig:
	return stat_definitions.get(stat_id, null)

## 获取所有属性定义
func get_all_definitions() -> Dictionary:
	return stat_definitions

## 检查属性是否存在
func has_stat(stat_id: String) -> bool:
	return stat_definitions.has(stat_id)

## 获取属性显示名称
func get_stat_display_name(stat_id: String) -> String:
	var config: GrowthConfig = get_stat_definition(stat_id)
	if config:
		return config.display_name
	return stat_id

## 获取属性描述
func get_stat_description(stat_id: String) -> String:
	var config: GrowthConfig = get_stat_definition(stat_id)
	if config:
		return config.description
	return ""

## 获取属性默认值
func get_stat_default_value(stat_id: String) -> int:
	var config: GrowthConfig = get_stat_definition(stat_id)
	if config:
		return config.default_value
	return 10

## 获取所有属性ID列表
func get_all_stat_ids() -> Array[String]:
	var ids: Array[String] = []
	for stat_id: String in stat_definitions:
		ids.append(stat_id)
	return ids

## 获取所有属性的默认值映射
func get_all_default_values() -> Dictionary:
	var defaults: Dictionary = {}
	for stat_id: String in stat_definitions:
		defaults[stat_id] = get_stat_default_value(stat_id)
	return defaults
