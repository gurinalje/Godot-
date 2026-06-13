# save_validator.gd
# Story 006: 存档验证
# Date: 2026-06-03

class_name SaveValidator
extends RefCounted

## 存档验证器
## 提供CRC32校验和计算和验证功能

# 常量
const CHECKSUM_KEY: String = "checksum"
const DATA_KEY: String = "data"

## 计算CRC32校验和
static func calculate_checksum(data: Dictionary) -> int:
	# 将Dictionary转换为字符串
	var json_string = JSON.stringify(data)
	# 计算CRC32
	return json_string.hash()

## 验证存档数据
static func validate_save_data(save_data: Dictionary) -> Dictionary:
	var result = {
		"valid": false,
		"has_checksum": false,
		"checksum_match": false,
		"error_message": "",
		"recovered_data": {}
	}
	
	# 检查是否有checksum字段
	if not save_data.has(CHECKSUM_KEY):
		result.error_message = "存档数据缺少校验和字段"
		return result
	
	result.has_checksum = true
	
	# 获取存储的校验和
	var stored_checksum = save_data[CHECKSUM_KEY]
	
	# 获取数据部分
	var data = save_data.duplicate()
	data.erase(CHECKSUM_KEY)
	
	# 计算当前校验和
	var calculated_checksum = calculate_checksum(data)
	
	# 比较校验和
	if stored_checksum == calculated_checksum:
		result.valid = true
		result.checksum_match = true
		result.recovered_data = data
	else:
		result.error_message = "存档数据校验和不匹配，数据可能已损坏"
		# 尝试恢复部分数据
		result.recovered_data = _attempt_recovery(save_data)
	
	return result

## 尝试恢复损坏的存档数据
static func _attempt_recovery(save_data: Dictionary) -> Dictionary:
	var recovered = {}
	
	# 尝试恢复玩家数据
	if save_data.has("player"):
		var player_data = save_data["player"]
		if player_data is Dictionary:
			recovered["player"] = {
				"level": player_data.get("level", 1),
				"experience": player_data.get("experience", 0),
				"gold": player_data.get("gold", 0)
			}
			# 尝试恢复属性
			if player_data.has("attributes") and player_data["attributes"] is Dictionary:
				recovered["player"]["attributes"] = player_data["attributes"]
	
	# 尝试恢复卡牌数据
	if save_data.has("cards"):
		var cards_data = save_data["cards"]
		if cards_data is Dictionary:
			recovered["cards"] = {
				"collection": cards_data.get("collection", []),
				"deck": cards_data.get("deck", [])
			}
	
	# 尝试恢复印记数据
	if save_data.has("marks"):
		var marks_data = save_data["marks"]
		if marks_data is Dictionary:
			recovered["marks"] = marks_data
	
	# 尝试恢复版本信息
	if save_data.has("version"):
		recovered["version"] = save_data["version"]
	
	return recovered

## 为存档数据添加校验和
static func add_checksum(save_data: Dictionary) -> Dictionary:
	var data_with_checksum = save_data.duplicate()
	var data_without_checksum = save_data.duplicate()
	data_without_checksum.erase(CHECKSUM_KEY)
	
	var checksum = calculate_checksum(data_without_checksum)
	data_with_checksum[CHECKSUM_KEY] = checksum
	
	return data_with_checksum

## 验证存档文件完整性
static func validate_save_file(file_path: String) -> Dictionary:
	var result = {
		"valid": false,
		"file_exists": false,
		"file_readable": false,
		"json_valid": false,
		"checksum_valid": false,
		"error_message": "",
		"recovered_data": {}
	}
	
	# 检查文件是否存在
	if not FileAccess.file_exists(file_path):
		result.error_message = "存档文件不存在"
		return result
	
	result.file_exists = true
	
	# 读取文件
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		result.error_message = "无法打开存档文件"
		return result
	
	result.file_readable = true
	
	var json_string = file.get_as_text()
	file.close()
	
	# 解析JSON
	var json = JSON.new()
	var error = json.parse(json_string)
	if error != OK:
		result.error_message = "存档文件JSON格式错误"
		return result
	
	result.json_valid = true
	
	var save_data = json.data
	if not save_data is Dictionary:
		result.error_message = "存档数据格式错误"
		return result
	
	# 验证校验和
	var validation_result = validate_save_data(save_data)
	result.checksum_valid = validation_result.valid
	result.recovered_data = validation_result.recovered_data
	
	if validation_result.valid:
		result.valid = true
	else:
		result.error_message = validation_result.error_message
	
	return result

## 检查存档版本兼容性
static func check_version_compatibility(save_data: Dictionary, current_version: String) -> Dictionary:
	var result = {
		"compatible": false,
		"save_version": "",
		"current_version": current_version,
		"needs_migration": false,
		"error_message": ""
	}
	
	if not save_data.has("version"):
		result.error_message = "存档数据缺少版本信息"
		return result
	
	result.save_version = save_data["version"]
	
	# 简单版本比较（实际应该更复杂）
	if result.save_version == current_version:
		result.compatible = true
	else:
		result.needs_migration = true
		result.error_message = "存档版本不兼容，需要迁移"
	
	return result
