## RPG成长管理器
## 管理角色升级和成长系统

class_name RPGGrowthManager
extends Node

# 经验值和等级
var current_level: int = 1
var current_exp: int = 0
var exp_to_next_level: int = 100

# 属性点
var available_points: int = 0

# 属性值
var stats: Dictionary = {
	"strength": 10,
	"dexterity": 10,
	"intelligence": 10,
	"constitution": 10,
	"luck": 10
}

# 信号
signal level_up(new_level: int)
signal exp_gained(amount: int)
signal stat_increased(stat_name: String, new_value: int)
signal points_allocated(stat_name: String)

func _ready() -> void:
	initialize()

func initialize() -> void:
	print("[RPGGrowthManager] Initialized")

## 获取当前等级
func get_current_level() -> int:
	return current_level

## 获取当前经验值
func get_current_exp() -> int:
	return current_exp

## 获取升级所需经验
func get_exp_to_next_level() -> int:
	return exp_to_next_level

## 增加经验值
func add_exp(amount: int) -> void:
	current_exp += amount
	exp_gained.emit(amount)
	print("[RPGGrowthManager] Gained ", amount, " exp")
	
	# 检查是否升级
	while current_exp >= exp_to_next_level:
		_level_up()

## 升级
func _level_up() -> void:
	current_exp -= exp_to_next_level
	current_level += 1
	available_points += 3
	
	# 计算下一级所需经验
	exp_to_next_level = _calculate_exp_for_level(current_level + 1)
	
	level_up.emit(current_level)
	print("[RPGGrowthManager] Level up! Now level ", current_level)

## 计算等级所需经验
func _calculate_exp_for_level(level: int) -> int:
	return int(100 * pow(level, 1.5))

## 获取属性值
func get_stat(stat_name: String) -> int:
	return stats.get(stat_name, 0)

## 增加属性
func increase_stat(stat_name: String) -> bool:
	if available_points <= 0:
		push_warning("[RPGGrowthManager] No available points")
		return false
	
	if not stats.has(stat_name):
		push_warning("[RPGGrowthManager] Invalid stat: " + stat_name)
		return false
	
	stats[stat_name] += 1
	available_points -= 1
	stat_increased.emit(stat_name, stats[stat_name])
	points_allocated.emit(stat_name)
	print("[RPGGrowthManager] Increased ", stat_name, " to ", stats[stat_name])
	return true

## 获取可用属性点
func get_available_points() -> int:
	return available_points

## 获取所有属性
func get_all_stats() -> Dictionary:
	return stats.duplicate()

## 设置属性
func set_stat(stat_name: String, value: int) -> void:
	if stats.has(stat_name):
		stats[stat_name] = value

## 重置属性
func reset_stats() -> void:
	var total_points = 0
	for stat in stats.values():
		total_points += stat - 10
	
	stats = {
		"strength": 10,
		"dexterity": 10,
		"intelligence": 10,
		"constitution": 10,
		"luck": 10
	}
	
	available_points = total_points
	print("[RPGGrowthManager] Stats reset")

## 获取属性名称
func get_stat_name(stat_name: String) -> String:
	match stat_name:
		"strength":
			return "Strength"
		"dexterity":
			return "Dexterity"
		"intelligence":
			return "Intelligence"
		"constitution":
			return "Constitution"
		"luck":
			return "Luck"
		_:
			return stat_name

## 获取属性描述
func get_stat_description(stat_name: String) -> String:
	match stat_name:
		"strength":
			return "Increases physical attack power"
		"dexterity":
			return "Increases critical rate and evasion"
		"intelligence":
			return "Increases magic attack and mana"
		"constitution":
			return "Increases health and defense"
		"luck":
			return "Increases drop rate and critical damage"
		_:
			return ""
