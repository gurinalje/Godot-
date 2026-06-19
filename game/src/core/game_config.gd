## 游戏配置资源类
##
## 集中管理所有游戏配置值，避免硬编码。
## 使用 @export 以便在 Godot 编辑器中配置。
class_name GameConfig
extends Resource

# ============================================================
# 玩家默认值
# ============================================================

## 默认生命值
@export_group("玩家默认值")
@export var default_health: int = 100

## 默认最大生命值
@export var default_max_health: int = 100

## 默认法力值
@export var default_mana: int = 100

## 默认最大法力值
@export var default_max_mana: int = 100

## 默认金币
@export var default_gold: int = 0

## 默认攻击力
@export var default_attack: int = 10

## 默认防御力
@export var default_defense: int = 5

## 默认经验值
@export var default_experience: int = 0

## 默认等级
@export var default_level: int = 1

# ============================================================
# 战斗配置
# ============================================================

## 战斗相关配置
@export_group("战斗配置")
@export var default_max_energy: int = 10

## 每回合默认抽牌数
@export var default_draw_count: int = 5

## 默认暴击率 (0.0 ~ 1.0)
@export_range(0.0, 1.0) var default_crit_rate: float = 0.05

## 默认暴击伤害倍率
@export var default_crit_damage: float = 1.5

# ============================================================
# 元素克制倍率
# ============================================================

## 元素克制关系配置
## 结构: { 攻击元素: { 防御元素: 倍率 } }
## 元素类型: fire, water, earth, wind, lightning
@export_group("元素系统")
@export var element_multipliers: Dictionary = {
	"fire": {
		"fire": 1.0,
		"water": 0.5,
		"earth": 2.0,
		"wind": 1.5,
		"lightning": 1.0,
	},
	"water": {
		"fire": 2.0,
		"water": 1.0,
		"earth": 0.5,
		"wind": 1.0,
		"lightning": 0.75,
	},
	"earth": {
		"fire": 0.5,
		"water": 2.0,
		"earth": 1.0,
		"wind": 0.75,
		"lightning": 1.5,
	},
	"wind": {
		"fire": 0.75,
		"water": 1.0,
		"earth": 1.5,
		"wind": 1.0,
		"lightning": 0.5,
	},
	"lightning": {
		"fire": 1.0,
		"water": 1.5,
		"earth": 0.75,
		"wind": 2.0,
		"lightning": 1.0,
	},
}

# ============================================================
# 防御公式
# ============================================================

## 防御计算常量 (伤害 = 攻击 * 100 / (100 + 防御))
@export_group("防御公式")
@export var defense_constant: float = 100.0

# ============================================================
# 存档配置
# ============================================================

## 存档系统配置
@export_group("存档配置")
@export var save_version: String = "1.0.0"

## 自动存档间隔 (秒)
@export var auto_save_interval: float = 300.0

## 自动存档防抖时间 (秒)
@export var auto_save_debounce: float = 2.0

## 手动存档槽位列表
@export var manual_save_slots: Array[int] = [1, 2, 3, 4, 5]

# ============================================================
# UI 配置
# ============================================================

## UI 层级名称 (从低到高)
@export_group("UI配置")
@export var ui_layers: Array[String] = ["base", "popup", "tooltip"]

# ============================================================
# 音频配置
# ============================================================

## 音频系统配置
@export_group("音频配置")
@export var audio_path: String = "res://assets/audio/"

## 默认背景音乐音量 (0.0 ~ 1.0)
@export_range(0.0, 1.0) var default_bgm_volume: float = 0.8

## 默认音效音量 (0.0 ~ 1.0)
@export_range(0.0, 1.0) var default_sfx_volume: float = 1.0


# ============================================================
# 公共方法
# ============================================================

## 获取元素克制倍率
## [param attack_element] 攻击元素类型
## [param defense_element] 防御元素类型
## [return] 克制倍率，若配置不存在则返回 1.0
func get_element_multiplier(attack_element: String, defense_element: String) -> float:
	if element_multipliers.has(attack_element):
		var attack_table: Dictionary = element_multipliers[attack_element]
		if attack_table.has(defense_element):
			return attack_table[defense_element]
	return 1.0


## 计算防御减免后的伤害
## [param raw_damage] 原始伤害值
## [param defense] 防御力
## [return] 减免后的伤害值
func calculate_damage_after_defense(raw_damage: int, defense: int) -> int:
	return int(raw_damage * defense_constant / (defense_constant + defense))
