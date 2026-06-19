# combo_chain_manager.gd
# 连锁管理器
# 管理所有连锁规则和出牌序列
class_name ComboChainManager
extends Node

## 信号：连锁触发
signal combo_triggered(combo: ComboChain, damage_bonus: float)

## 信号：连锁检测完成
signal combo_check_completed(matched_combos: Array[ComboChain])

## 所有连锁规则
var combo_chains: Array[ComboChain] = []

## 当前出牌序列
var played_cards: Array[CardData] = []

## 本回合已触发的连锁
var triggered_combos: Array[String] = []

## 连锁触发次数限制
const MAX_COMBOS_PER_TURN: int = 3

## 当前回合连锁触发次数
var combo_count_this_turn: int = 0

## 初始化
func _ready() -> void:
	_load_combos_from_files()

## 从文件加载连锁规则
func _load_combos_from_files() -> void:
	var combos_dir = "res://data/combos/"
	var dir = DirAccess.open(combos_dir)
	
	if not dir:
		push_warning("[ComboChainManager] Combos directory not found: " + combos_dir)
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".json"):
			_load_json_combos(combos_dir + file_name)
		file_name = dir.get_next()
	
	# 加载完成后按优先级排序（只排序一次）
	_sort_combos_by_priority()

## 按优先级排序连击规则（降序，高优先级在前）
func _sort_combos_by_priority() -> void:
	combo_chains.sort_custom(func(a: ComboChain, b: ComboChain): return a.priority > b.priority)

## 加载 JSON 格式连锁规则
func _load_json_combos(json_path: String) -> void:
	var file = FileAccess.open(json_path, FileAccess.READ)
	if not file:
		push_warning("[ComboChainManager] Cannot open JSON file: " + json_path)
		return
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_string)
	if error != OK:
		push_warning("[ComboChainManager] JSON parse error in " + json_path + ": " + json.get_error_message())
		return
	
	var data = json.data
	if not data is Dictionary or not data.has("combo_chains"):
		push_warning("[ComboChainManager] Invalid JSON structure in " + json_path)
		return
	
	for combo_dict in data["combo_chains"]:
		var combo = _create_combo_from_dict(combo_dict)
		if combo:
			combo_chains.append(combo)

## 从字典创建连锁规则
func _create_combo_from_dict(data: Dictionary) -> ComboChain:
	if not data.has("chain_id"):
		push_warning("[ComboChainManager] Combo missing 'chain_id' field")
		return null
	
	var combo = ComboChain.new()
	combo.chain_id = data.get("chain_id", "")
	combo.chain_name = data.get("chain_name", "")
	combo.description = data.get("description", "")
	combo.chain_type = data.get("chain_type", ComboChain.ChainType.CARD_TYPE)
	combo.trigger_conditions = data.get("trigger_conditions", {})
	combo.effect_type = data.get("effect_type", ComboChain.ChainEffectType.DAMAGE_BONUS)
	combo.effect_value = data.get("effect_value", 0.5)
	combo.priority = data.get("priority", 0)
	return combo

## ==================== 连锁管理 ====================

## 添加连锁规则（保持优先级排序）
func add_combo_chain(combo: ComboChain) -> void:
	# 找到插入位置以保持排序
	var insert_index: int = 0
	for i in range(combo_chains.size()):
		if combo.priority > combo_chains[i].priority:
			insert_index = i
			break
		insert_index = i + 1
	
	combo_chains.insert(insert_index, combo)

## 移除连锁规则
func remove_combo_chain(chain_id: String) -> void:
	for i in range(combo_chains.size()):
		if combo_chains[i].chain_id == chain_id:
			combo_chains.remove_at(i)
			return

## 获取连锁规则
func get_combo_chain(chain_id: String) -> ComboChain:
	for combo in combo_chains:
		if combo.chain_id == chain_id:
			return combo
	return null

## ==================== 出牌序列管理 ====================

## 记录出牌
func record_card_played(card: CardData) -> void:
	played_cards.append(card)
	_check_for_combos()

## 清空出牌序列
func clear_played_cards() -> void:
	played_cards.clear()

## 重置回合状态
func reset_turn() -> void:
	clear_played_cards()
	triggered_combos.clear()
	combo_count_this_turn = 0

## ==================== 连锁检测 ====================

## 检查是否有连锁触发
func _check_for_combos() -> void:
	if combo_count_this_turn >= MAX_COMBOS_PER_TURN:
		return
	
	var matched_combos: Array[ComboChain] = []
	
	# combo_chains 已在加载时按优先级排序，无需再次排序
	
	# 检查每个连锁规则
	for combo in combo_chains:
		# 跳过已触发的连锁
		if triggered_combos.has(combo.chain_id):
			continue
		
		# 检查条件
		if combo.check_conditions(played_cards):
			matched_combos.append(combo)
			
			# 触发连锁
			_trigger_combo(combo)
			
			# 达到限制时停止
			if combo_count_this_turn >= MAX_COMBOS_PER_TURN:
				break
	
	combo_check_completed.emit(matched_combos)

## 触发连锁
func _trigger_combo(combo: ComboChain) -> void:
	triggered_combos.append(combo.chain_id)
	combo_count_this_turn += 1
	
	# 计算连锁效果
	var effect_value: float = combo.effect_value
	
	# 发送信号
	combo_triggered.emit(combo, effect_value)

## ==================== 查询接口 ====================

## 获取当前出牌序列
func get_played_cards() -> Array[CardData]:
	return played_cards

## 获取本回合已触发的连锁
func get_triggered_combos() -> Array[String]:
	return triggered_combos

## 获取本回合连锁触发次数
func get_combo_count_this_turn() -> int:
	return combo_count_this_turn

## 检查是否还能触发连锁
func can_trigger_more_combos() -> bool:
	return combo_count_this_turn < MAX_COMBOS_PER_TURN

## 获取所有可用的连锁规则
func get_available_combos() -> Array[ComboChain]:
	return combo_chains

## 获取匹配当前出牌序列的连锁
func get_matching_combos() -> Array[ComboChain]:
	var matching: Array[ComboChain] = []
	for combo in combo_chains:
		if combo.check_conditions(played_cards):
			matching.append(combo)
	return matching

## 获取连锁预览（用于UI显示）
func get_combo_preview(card: CardData) -> Array[Dictionary]:
	var preview: Array[Dictionary] = []
	
	# 模拟出牌
	var simulated_cards: Array[CardData] = played_cards.duplicate()
	simulated_cards.append(card)
	
	# 检查所有连锁
	for combo in combo_chains:
		if combo.check_conditions(simulated_cards):
			preview.append({
				"chain_name": combo.chain_name,
				"description": combo.description,
				"effect": combo.get_effect_description(),
				"color": combo.chain_color
			})
	
	return preview

## ==================== 序列化 ====================

## 序列化为字典
func to_dict() -> Dictionary:
	var combos_data: Array[Dictionary] = []
	for combo in combo_chains:
		combos_data.append(combo.to_dict())
	
	return {
		"combo_chains": combos_data,
		"triggered_combos": triggered_combos,
		"combo_count_this_turn": combo_count_this_turn
	}

## 从字典反序列化
func load_from_dict(data: Dictionary) -> void:
	combo_chains.clear()
	
	var combos_data: Array = data.get("combo_chains", [])
	for combo_data in combos_data:
		if combo_data is Dictionary:
			combo_chains.append(ComboChain.from_dict(combo_data))
	
	triggered_combos = data.get("triggered_combos", [])
	combo_count_this_turn = data.get("combo_count_this_turn", 0)
