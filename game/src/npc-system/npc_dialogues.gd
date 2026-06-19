## NPC对话数据
## 存储所有NPC的对话内容和商店物品
class_name NPCDialogues
extends RefCounted

## 获取NPC对话
static func get_dialogue(npc_id: String) -> Array[Dictionary]:
	match npc_id:
		"merchant", "merchant_forest", "merchant_castle", "merchant_void":
			return _get_merchant_dialogue()
		"blacksmith", "blacksmith_castle":
			return _get_blacksmith_dialogue()
		"quest_giver", "quest_giver_forest", "quest_giver_ruins":
			return _get_quest_giver_dialogue()
		_:
			return _get_default_dialogue(npc_id)

## 获取商人对话
static func _get_merchant_dialogue() -> Array[Dictionary]:
	return [
		{
			"speaker": "商人",
			"text": "欢迎光临！我这里有许多好东西，看看有没有你需要的？",
			"choices": [
				{"text": "看看商品", "action": "shop"},
				{"text": "有什么消息吗？", "action": "continue"},
				{"text": "告辞", "action": "end"}
			]
		},
		{
			"speaker": "商人",
			"text": "最近森林里出现了一些奇怪的生物，冒险者们要小心啊。听说深处有一只强大的怪物...",
			"choices": [
				{"text": "看看商品", "action": "shop"},
				{"text": "我知道了", "action": "end"}
			]
		}
	]

## 获取铁匠对话
static func _get_blacksmith_dialogue() -> Array[Dictionary]:
	return [
		{
			"speaker": "铁匠",
			"text": "嘿！需要打造装备吗？我这里应有尽有！从武器到防具，保证质量！",
			"choices": [
				{"text": "看看装备", "action": "shop"},
				{"text": "能介绍一下吗？", "action": "continue"},
				{"text": "告辞", "action": "end"}
			]
		},
		{
			"speaker": "铁匠",
			"text": "我打造的装备都是用最好的材料，保证让你在战斗中如虎添翼！",
			"choices": [
				{"text": "看看装备", "action": "shop"},
				{"text": "告辞", "action": "end"}
			]
		}
	]

## 获取任务给予者对话
static func _get_quest_giver_dialogue() -> Array[Dictionary]:
	return [
		{
			"speaker": "任务给予者",
			"text": "勇敢的冒险者，我有一个重要的任务需要你的帮助...",
			"choices": [
				{"text": "继续", "action": "continue"},
				{"text": "没兴趣", "action": "end"}
			]
		},
		{
			"speaker": "任务给予者",
			"text": "森林深处有一只强大的怪物，它已经威胁到了村民们的安全。你能帮我消灭它吗？",
			"choices": [
				{"text": "接受任务", "action": "accept_quest"},
				{"text": "我需要准备一下", "action": "end"}
			]
		}
	]

## 获取默认对话
static func _get_default_dialogue(npc_id: String) -> Array[Dictionary]:
	return [
		{
			"speaker": npc_id,
			"text": "...",
			"choices": [
				{"text": "告辞", "action": "end"}
			]
		}
	]

## 获取商店物品
static func get_shop_items(npc_id: String) -> Array[Dictionary]:
	match npc_id:
		"merchant", "merchant_forest", "merchant_castle", "merchant_void":
			return _get_merchant_items()
		"blacksmith", "blacksmith_castle":
			return _get_blacksmith_items()
		_:
			return []

## 获取商人物品
static func _get_merchant_items() -> Array[Dictionary]:
	return [
		{
			"name": "生命药水",
			"cost": 50,
			"type": "consumable",
			"effect": "heal",
			"value": 30,
			"description": "恢复30点生命值"
		},
		{
			"name": "能量药水",
			"cost": 75,
			"type": "consumable",
			"effect": "energy",
			"value": 20,
			"description": "恢复20点能量"
		},
		{
			"name": "火球术卡牌",
			"cost": 200,
			"type": "card",
			"card_id": "fireball",
			"description": "发射一个火球造成火焰伤害"
		},
		{
			"name": "冰霜新星卡牌",
			"cost": 250,
			"type": "card",
			"card_id": "blizzard",
			"description": "释放冰霜新星冻结周围敌人"
		},
		{
			"name": "神圣祝福卡牌",
			"cost": 300,
			"type": "card",
			"card_id": "holy_blessing",
			"description": "获得神圣祝福，提升全属性"
		},
		{
			"name": "解毒草",
			"cost": 30,
			"type": "consumable",
			"effect": "cure_poison",
			"value": 1,
			"description": "解除中毒状态"
		}
	]

## 获取铁匠物品
static func _get_blacksmith_items() -> Array[Dictionary]:
	return [
		{
			"name": "铁剑",
			"cost": 150,
			"type": "equipment",
			"slot": "weapon",
			"attack": 5,
			"description": "基础铁制武器，攻击力+5"
		},
		{
			"name": "皮甲",
			"cost": 120,
			"type": "equipment",
			"slot": "armor",
			"defense": 3,
			"description": "轻便的皮甲，防御力+3"
		},
		{
			"name": "钢盾",
			"cost": 180,
			"type": "equipment",
			"slot": "shield",
			"defense": 5,
			"description": "坚固的钢盾，防御力+5"
		},
		{
			"name": "精钢长剑",
			"cost": 350,
			"type": "equipment",
			"slot": "weapon",
			"attack": 10,
			"description": "精钢打造的长剑，攻击力+10"
		},
		{
			"name": "锁子甲",
			"cost": 280,
			"type": "equipment",
			"slot": "armor",
			"defense": 6,
			"description": "结实的锁子甲，防御力+6"
		}
	]

## 获取NPC名称
static func get_npc_display_name(npc_id: String) -> String:
	match npc_id:
		"merchant", "merchant_forest", "merchant_castle", "merchant_void":
			return "商人"
		"blacksmith", "blacksmith_castle":
			return "铁匠"
		"quest_giver", "quest_giver_forest", "quest_giver_ruins":
			return "任务给予者"
		_:
			return npc_id
