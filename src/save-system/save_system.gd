# save_system.gd
# 存档系统核心类
# 提供存档和读档功能

class_name SaveSystem
extends Node

## 存档系统
## 管理游戏的存档和读档功能

# 信号
signal save_completed(success: bool, slot_id: int)
signal load_completed(success: bool, slot_id: int)
signal save_error(error_message: String)
signal load_error(error_message: String)

# 常量
const SAVE_VERSION: String = "1.0"

# 初始化
func _ready() -> void:
	# 确保存档目录存在
	SaveSlotManager.init_save_directory()
	print("[SaveSystem] Initialized")

## 保存数据到指定槽位
func save_to_slot(slot_id: int, save_data: Dictionary) -> bool:
	# 验证槽位
	if slot_id < 0 or slot_id >= SaveSlotManager.MAX_SLOTS:
		save_error.emit("无效的存档槽位: " + str(slot_id))
		return false
	
	# 添加版本信息和时间戳
	save_data["version"] = SAVE_VERSION
	save_data["timestamp"] = Time.get_datetime_string_from_system()
	
	# 获取文件路径
	var file_path = SaveSlotManager.get_slot_file_path(slot_id)
	
	# 序列化为JSON
	var json_string = JSON.stringify(save_data, "\t")
	
	# 写入文件
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		var error_msg = "无法打开文件进行写入: " + file_path
		save_error.emit(error_msg)
		push_error("[SaveSystem] " + error_msg)
		return false
	
	file.store_string(json_string)
	file.close()
	
	print("[SaveSystem] 保存成功到槽位: ", slot_id)
	save_completed.emit(true, slot_id)
	return true

## 从指定槽位加载数据
func load_from_slot(slot_id: int) -> Dictionary:
	# 验证槽位
	if slot_id < 0 or slot_id >= SaveSlotManager.MAX_SLOTS:
		load_error.emit("无效的存档槽位: " + str(slot_id))
		return {"success": false, "error_message": "无效的存档槽位"}
	
	# 检查槽位是否为空
	if SaveSlotManager.is_slot_empty(slot_id):
		load_error.emit("槽位为空: " + str(slot_id))
		return {"success": false, "error_message": "槽位为空"}
	
	# 获取文件路径
	var file_path = SaveSlotManager.get_slot_file_path(slot_id)
	
	# 读取文件
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		var error_msg = "无法打开文件进行读取: " + file_path
		load_error.emit(error_msg)
		push_error("[SaveSystem] " + error_msg)
		return {"success": false, "error_message": error_msg}
	
	var json_string = file.get_as_text()
	file.close()
	
	# 解析JSON
	var json = JSON.new()
	var error = json.parse(json_string)
	if error != OK:
		var error_msg = "JSON解析失败: " + json.get_error_message()
		load_error.emit(error_msg)
		push_error("[SaveSystem] " + error_msg)
		return {"success": false, "error_message": error_msg}
	
	var data = json.data
	if data is not Dictionary:
		var error_msg = "存档数据格式错误"
		load_error.emit(error_msg)
		push_error("[SaveSystem] " + error_msg)
		return {"success": false, "error_message": error_msg}
	
	# 验证版本
	var version = data.get("version", "")
	if version != SAVE_VERSION:
		push_warning("[SaveSystem] 存档版本不匹配: " + version + " (期望: " + SAVE_VERSION + ")")
	
	print("[SaveSystem] 从槽位加载成功: ", slot_id)
	load_completed.emit(true, slot_id)
	return {"success": true, "data": data}

## 删除指定槽位
func delete_slot(slot_id: int) -> bool:
	var result = SaveSlotManager.delete_slot(slot_id)
	if result:
		print("[SaveSystem] 删除槽位成功: ", slot_id)
	else:
		push_warning("[SaveSystem] 删除槽位失败: ", slot_id)
	return result

## 获取所有存档槽信息
func get_all_slot_info() -> Array:
	return SaveSlotManager.get_all_slot_info()

## 检查槽位是否为空
func is_slot_empty(slot_id: int) -> bool:
	return SaveSlotManager.is_slot_empty(slot_id)

## 获取空闲的手动槽位
func get_empty_manual_slot() -> int:
	return SaveSlotManager.get_empty_manual_slot()

## 检查手动槽位是否已满
func is_manual_slots_full() -> bool:
	return SaveSlotManager.is_manual_slots_full()
