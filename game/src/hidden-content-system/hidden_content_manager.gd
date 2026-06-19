## 隐藏内容管理器
## 管理游戏中的隐藏内容和彩蛋

class_name HiddenContentManager
extends Node

# 隐藏内容类型
enum ContentType {
	HIDDEN_AREA,      # 隐藏区域
	SECRET_QUEST,     # 隐藏任务
	EASTER_EGG,       # 彩蛋
	HIDDEN_ITEM,      # 隐藏物品
	HIDDEN_CHARACTER  # 隐藏角色
}

# 已发现的隐藏内容
var discovered_content: Array[String] = []

# 隐藏内容数据
var hidden_content: Dictionary = {}

# 信号
signal content_discovered(content_id: String, content_type: ContentType)

func _ready() -> void:
	initialize()

func initialize() -> void:
	print("[HiddenContentManager] Initialized")
	_load_hidden_content()

## 加载隐藏内容
func _load_hidden_content() -> void:
	# TODO: 从文件加载隐藏内容数据
	hidden_content = {
		"secret_garden": {
			"id": "secret_garden",
			"type": ContentType.HIDDEN_AREA,
			"name": "秘密花园",
			"description": "一个隐藏的花园，充满了稀有植物",
			"discovery_condition": "find_all_fragments",
			"reward": {"gold": 1000, "card": "legendary_card"}
		},
		"shadow_quests": {
			"id": "shadow_quests",
			"type": ContentType.SECRET_QUEST,
			"name": "暗影任务",
			"description": "一系列隐藏的任务线",
			"discovery_condition": "complete_evil_path",
			"reward": {"card": "shadow_card", "mark": "hidden"}
		},
		"developer_room": {
			"id": "developer_room",
			"type": ContentType.EASTER_EGG,
			"name": "开发者房间",
			"description": "一个隐藏的开发者房间",
			"discovery_condition": "enter_konami_code",
			"reward": {"achievement": "developer_secret"}
		}
	}

## 发现隐藏内容
func discover_content(content_id: String) -> bool:
	if content_id in discovered_content:
		push_warning("[HiddenContentManager] Content already discovered: " + content_id)
		return false
	
	if not hidden_content.has(content_id):
		push_warning("[HiddenContentManager] Content not found: " + content_id)
		return false
	
	discovered_content.append(content_id)
	var content = hidden_content[content_id]
	var content_type = content.get("type", ContentType.EASTER_EGG)
	
	content_discovered.emit(content_id, content_type)
	print("[HiddenContentManager] Discovered content: ", content_id)
	
	# 发放奖励
	_grant_reward(content_id)
	
	return true

## 发放奖励
func _grant_reward(content_id: String) -> void:
	var content = hidden_content.get(content_id, {})
	var reward = content.get("reward", {})
	
	# TODO: 发放奖励
	print("[HiddenContentManager] Granted reward for: ", content_id)

## 检查内容是否已发现
func is_content_discovered(content_id: String) -> bool:
	return content_id in discovered_content

## 获取隐藏内容数据
func get_content_data(content_id: String) -> Dictionary:
	return hidden_content.get(content_id, {})

## 获取所有隐藏内容
func get_all_content() -> Dictionary:
	return hidden_content

## 获取已发现的内容
func get_discovered_content() -> Array[String]:
	return discovered_content

## 检查发现条件
func check_discovery_condition(content_id: String, condition_data: Dictionary) -> bool:
	var content = hidden_content.get(content_id, {})
	var condition = content.get("discovery_condition", "")
	
	# TODO: 检查各种发现条件
	match condition:
		"find_all_fragments":
			return condition_data.get("fragments_found", 0) >= condition_data.get("total_fragments", 0)
		"complete_evil_path":
			return condition_data.get("evil_marks", 0) >= 10
		"enter_konami_code":
			return condition_data.get("konami_entered", false)
		_:
			return false

## 获取内容类型名称
func get_content_type_name(content_type: ContentType) -> String:
	match content_type:
		ContentType.HIDDEN_AREA:
			return "隐藏区域"
		ContentType.SECRET_QUEST:
			return "隐藏任务"
		ContentType.EASTER_EGG:
			return "彩蛋"
		ContentType.HIDDEN_ITEM:
			return "隐藏物品"
		ContentType.HIDDEN_CHARACTER:
			return "隐藏角色"
		_:
			return "未知"

## 重置发现状态
func reset_discoveries() -> void:
	discovered_content.clear()
	print("[HiddenContentManager] Discoveries reset")
