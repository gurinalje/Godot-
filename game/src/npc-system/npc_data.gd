## NPC数据定义
## 存储NPC的基本信息、对话树和关系状态
class_name NPCData
extends Resource

## NPC唯一标识
@export var id: String = ""

## NPC名称
@export var name: String = ""

## NPC描述
@export var description: String = ""

## NPC头像
@export var avatar: Texture2D = null

## NPC立绘
@export var portrait: Texture2D = null

## NPC类型
@export var type: NPCType = NPCType.VILLAGER

## NPC位置（区域ID）
@export var location: String = ""

## NPC对话树ID
@export var dialogue_tree_id: String = ""

## NPC任务ID
@export var quest_id: String = ""

## NPC商店物品
@export var shop_items: Array[String] = []

## NPC类型枚举
enum NPCType {
	VILLAGER,      ## 村民
	MERCHANT,      ## 商人
	QUEST_GIVER,   ## 任务给予者
	TRAINER,       ## 训练师
	ENEMY,         ## 敌人
	BOSS           ## BOSS
}

## NPC关系等级
enum RelationLevel {
	HOSTILE,       ## 敌对
	UNFRIENDLY,    ## 不友好
	NEUTRAL,       ## 中立
	FRIENDLY,      ## 友好
	ALLIED         ## 结盟
}

## 克隆NPC数据
func clone() -> NPCData:
	var clone_data = NPCData.new()
	clone_data.id = id
	clone_data.name = name
	clone_data.description = description
	clone_data.avatar = avatar
	clone_data.portrait = portrait
	clone_data.type = type
	clone_data.location = location
	clone_data.dialogue_tree_id = dialogue_tree_id
	clone_data.quest_id = quest_id
	clone_data.shop_items = shop_items.duplicate()
	return clone_data
