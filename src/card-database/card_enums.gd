# card_enums.gd
# 卡牌系统枚举定义
# 所有卡牌相关的类型枚举集中管理

class_name CardEnums
extends RefCounted

## 卡牌类型
enum CardType {
	SUMMON,        ## 召唤类 - 召唤生物到战场
	DIRECT_DAMAGE, ## 直接伤害类 - 对目标造成即时伤害
	ENVIRONMENT,   ## 环境阵地类 - 改变战场环境
	BUFF_DEBUFF    ## 增益减益类 - 给予Buff/Debuff
}

## 卡牌稀有度
enum Rarity {
	COMMON,    ## 普通 - 基础卡牌
	UNCOMMON,  ## 稀有 - 较强效果
	RARE,      ## 史诗 - 强力效果
	LEGENDARY  ## 传说 - 独特效果
}

## 元素类型
enum Element {
	NONE,      ## 无元素
	FIRE,      ## 火 - 高伤害，持续燃烧
	WATER,     ## 水 - 治疗，护盾
	EARTH,     ## 土 - 防御，生命值
	WIND,      ## 风 - 速度，闪避
	LIGHTNING  ## 雷 - 连锁，暴击
}

## 效果类型
enum EffectType {
	DAMAGE,            ## 造成伤害
	HEAL,              ## 治疗
	SUMMON,            ## 召唤单位
	BUFF,              ## 增益效果
	DEBUFF,            ## 减益效果
	ENVIRONMENT_CHANGE ## 环境改变
}

## 目标类型
enum TargetType {
	SELF,        ## 自己
	ENEMY,       ## 单个敌人
	ALL_ENEMIES, ## 所有敌人
	ALL_ALLIES,  ## 所有友方
	RANDOM       ## 随机目标
}

## 卡牌状态
enum CardState {
	UNLOCKED, ## 已解锁但未装备
	EQUIPPED, ## 在卡组中
	USED,     ## 本回合已打出
	REMOVED   ## 从卡组移除
}

## 获取稀有度倍率
static func get_rarity_multiplier(rarity: Rarity) -> float:
	match rarity:
		Rarity.COMMON:
			return 1.0
		Rarity.UNCOMMON:
			return 1.3
		Rarity.RARE:
			return 1.6
		Rarity.LEGENDARY:
			return 2.0
		_:
			return 1.0

## 获取元素克制关系
## 返回：1.5（克制）、1.0（普通）、0.75（被克制）
static func get_element_modifier(attacker_element: Element, defender_element: Element) -> float:
	# 克制关系：火→风→土→雷→水→火
	if attacker_element == Element.NONE or defender_element == Element.NONE:
		return 1.0
	
	var strong_against: Dictionary = {
		Element.FIRE: Element.WIND,
		Element.WIND: Element.EARTH,
		Element.EARTH: Element.LIGHTNING,
		Element.LIGHTNING: Element.WATER,
		Element.WATER: Element.FIRE
	}
	
	if strong_against.get(attacker_element) == defender_element:
		return 1.5  # 克制
	elif strong_against.get(defender_element) == attacker_element:
		return 0.75  # 被克制
	return 1.0  # 普通

## 获取元素颜色（用于UI显示）
static func get_element_color(element: Element) -> Color:
	match element:
		Element.FIRE:
			return Color(1.0, 0.3, 0.2)  # 红色
		Element.WATER:
			return Color(0.2, 0.5, 1.0)  # 蓝色
		Element.EARTH:
			return Color(0.6, 0.4, 0.2)  # 棕色
		Element.WIND:
			return Color(0.4, 0.9, 0.4)  # 绿色
		Element.LIGHTNING:
			return Color(1.0, 0.9, 0.2)  # 黄色
		_:
			return Color(0.7, 0.7, 0.7)  # 灰色

## 获取稀有度颜色
static func get_rarity_color(rarity: Rarity) -> Color:
	match rarity:
		Rarity.COMMON:
			return Color(0.8, 0.8, 0.8)  # 白色
		Rarity.UNCOMMON:
			return Color(0.2, 0.8, 0.2)  # 绿色
		Rarity.RARE:
			return Color(0.6, 0.2, 0.9)  # 紫色
		Rarity.LEGENDARY:
			return Color(1.0, 0.8, 0.0)  # 金色
		_:
			return Color(0.7, 0.7, 0.7)
