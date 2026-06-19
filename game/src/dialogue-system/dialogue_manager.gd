## 对话管理器
## 管理NPC对话和对话树

class_name DialogueManager
extends Node

# 当前对话状态
var current_dialogue_id: String = ""
var current_node_id: String = ""
var is_dialogue_active: bool = false

# 对话数据
var dialogues: Dictionary = {}

# NPC好感度
var npc_affinity: Dictionary = {}

# 信号
signal dialogue_started(dialogue_id: String)
signal dialogue_ended(dialogue_id: String)
signal dialogue_node_changed(node_id: String)
signal choice_selected(choice_id: String, option: String)

func _ready() -> void:
	initialize()

func initialize() -> void:
	print("[DialogueManager] Initialized")
	_load_dialogue_data()

## 加载对话数据
func _load_dialogue_data() -> void:
	# TODO: 从文件加载对话数据
	dialogues = {
		"merchant_greeting": {
			"start": {
				"text": "欢迎光临！有什么我能帮你的吗？",
				"choices": [
					{"id": "shop", "text": "我想看看你的商品", "next": "shop"},
					{"id": "quest", "text": "有什么任务吗？", "next": "quest"},
					{"id": "leave", "text": "再见", "next": "end"}
				]
			},
			"shop": {
				"text": "好的，这是我的商品列表。",
				"choices": [
					{"id": "back", "text": "返回", "next": "start"}
				]
			},
			"quest": {
				"text": "我需要你帮我收集一些材料。",
				"choices": [
					{"id": "accept", "text": "接受任务", "next": "accept_quest"},
					{"id": "decline", "text": "拒绝", "next": "start"}
				]
			},
			"accept_quest": {
				"text": "太好了！请收集10个森林精华。",
				"choices": [
					{"id": "ok", "text": "好的", "next": "end"}
				]
			},
			"end": {
				"text": "再见，祝你好运！",
				"choices": []
			}
		}
	}

## 开始对话
func start_dialogue(dialogue_id: String) -> bool:
	if not dialogues.has(dialogue_id):
		push_warning("[DialogueManager] Dialogue not found: " + dialogue_id)
		return false
	
	current_dialogue_id = dialogue_id
	current_node_id = "start"
	is_dialogue_active = true
	dialogue_started.emit(dialogue_id)
	print("[DialogueManager] Started dialogue: ", dialogue_id)
	
	# 显示第一个对话节点
	_show_current_node()
	return true

## 结束对话
func end_dialogue() -> void:
	var dialogue_id = current_dialogue_id
	current_dialogue_id = ""
	current_node_id = ""
	is_dialogue_active = false
	dialogue_ended.emit(dialogue_id)
	print("[DialogueManager] Ended dialogue: ", dialogue_id)

## 显示当前对话节点
func _show_current_node() -> void:
	var dialogue = dialogues.get(current_dialogue_id, {})
	var node = dialogue.get(current_node_id, {})
	
	if node.is_empty():
		end_dialogue()
		return
	
	# 发送节点变更信号
	dialogue_node_changed.emit(current_node_id)

## 获取当前对话文本
func get_current_text() -> String:
	var dialogue = dialogues.get(current_dialogue_id, {})
	var node = dialogue.get(current_node_id, {})
	return node.get("text", "")

## 获取当前对话选项
func get_current_choices() -> Array:
	var dialogue = dialogues.get(current_dialogue_id, {})
	var node = dialogue.get(current_node_id, {})
	return node.get("choices", [])

## 选择选项
func select_choice(choice_id: String) -> void:
	var choices = get_current_choices()
	
	for choice in choices:
		if choice.get("id") == choice_id:
			var next_node = choice.get("next", "end")
			
			# 记录选择
			choice_selected.emit(choice_id, choice.get("text", ""))
			
			if next_node == "end":
				end_dialogue()
			else:
				current_node_id = next_node
				_show_current_node()
			return
	
	push_warning("[DialogueManager] Choice not found: " + choice_id)

## 检查对话是否激活
func is_active() -> bool:
	return is_dialogue_active

## 获取NPC好感度
func get_npc_affinity(npc_id: String) -> int:
	return npc_affinity.get(npc_id, 0)

## 增加NPC好感度
func add_npc_affinity(npc_id: String, amount: int) -> void:
	npc_affinity[npc_id] = npc_affinity.get(npc_id, 0) + amount
	print("[DialogueManager] Added ", amount, " affinity to ", npc_id)

## 获取当前对话ID
func get_current_dialogue_id() -> String:
	return current_dialogue_id
