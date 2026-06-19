## 玩家数据资源类
##
## 封装所有玩家状态为独立的 Resource，实现单一职责原则。
## 支持序列化/反序列化，用于存档系统。
class_name PlayerData
extends Resource

# ============================================================
# 玩家属性
# ============================================================

## 当前生命值
@export var health: int = 100

## 最大生命值
@export var max_health: int = 100

## 当前法力值
@export var mana: int = 100

## 最大法力值
@export var max_mana: int = 100

## 金币
@export var gold: int = 0

## 经验值
@export var experience: int = 0

## 等级
@export var level: int = 1

## 攻击力
@export var attack: int = 10

## 防御力
@export var defense: int = 5

## 当前区域
@export var current_area: String = "forest"

## 是否完成首次战斗
@export var first_battle_completed: bool = false

# ============================================================
# 初始化
# ============================================================

## 使用 GameConfig 的默认值初始化
func _init(config: GameConfig = null) -> void:
	if config:
		_apply_config(config)

## 应用 GameConfig 配置
func apply_config(config: GameConfig) -> void:
	_apply_config(config)

func _apply_config(config: GameConfig) -> void:
	health = config.default_health
	max_health = config.default_max_health
	mana = config.default_mana
	max_mana = config.default_max_mana
	gold = config.default_gold
	experience = config.default_experience
	level = config.default_level
	attack = config.default_attack
	defense = config.default_defense

# ============================================================
# 状态操作
# ============================================================

## 重置为默认值
func reset(config: GameConfig = null) -> void:
	if config:
		_apply_config(config)
	else:
		health = 100
		max_health = 100
		mana = 100
		max_mana = 100
		gold = 0
		experience = 0
		level = 1
		attack = 10
		defense = 5
		current_area = "forest"
		first_battle_completed = false

## 序列化为字典
func to_dict() -> Dictionary:
	return {
		"health": health,
		"max_health": max_health,
		"mana": mana,
		"max_mana": max_mana,
		"gold": gold,
		"experience": experience,
		"level": level,
		"attack": attack,
		"defense": defense,
		"current_area": current_area,
		"first_battle_completed": first_battle_completed
	}

## 从字典反序列化
func from_dict(data: Dictionary) -> void:
	health = data.get("health", 100)
	max_health = data.get("max_health", 100)
	mana = data.get("mana", 100)
	max_mana = data.get("max_mana", 100)
	gold = data.get("gold", 0)
	experience = data.get("experience", 0)
	level = data.get("level", 1)
	attack = data.get("attack", 10)
	defense = data.get("defense", 5)
	current_area = data.get("current_area", "forest")
	first_battle_completed = data.get("first_battle_completed", false)

# ============================================================
# 便捷方法
# ============================================================

## 治疗
func heal(amount: int) -> int:
	var old_health := health
	health = mini(health + amount, max_health)
	return health - old_health  # 返回实际治疗量

## 受到伤害
func take_damage(amount: int) -> int:
	var old_health := health
	health = maxi(health - amount, 0)
	return old_health - health  # 返回实际伤害量

## 是否存活
func is_alive() -> bool:
	return health > 0

## 消耗法力
func spend_mana(amount: int) -> bool:
	if mana < amount:
		return false
	mana -= amount
	return true

## 恢复法力
func restore_mana(amount: int) -> int:
	var old_mana := mana
	mana = mini(mana + amount, max_mana)
	return mana - old_mana

## 增加金币
func add_gold(amount: int) -> void:
	gold = maxi(gold + amount, 0)

## 消耗金币
func spend_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	return true

## 增加经验值
func add_experience(amount: int) -> bool:
	experience += amount
	# TODO: 检查是否升级，需要升级配置
	return false

## 获取显示用的属性摘要
func get_summary() -> String:
	return "Lv.%d HP:%d/%d MP:%d/%d Gold:%d" % [level, health, max_health, mana, max_mana, gold]
