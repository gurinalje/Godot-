# validation_test.gd
# Story 006: 存档验证
# Date: 2026-06-03

extends GutTest

## 存档验证测试
## 测试SaveValidator类的功能

## AC-1: 保存时计算CRC32校验和
func test_calculate_checksum():
	var data = {"version": "1.0", "player": {"level": 1}}
	var checksum = SaveValidator.calculate_checksum(data)
	assert_ne(checksum, 0, "校验和不应为0")

func test_calculate_checksum_consistency():
	var data = {"version": "1.0", "player": {"level": 1}}
	var checksum1 = SaveValidator.calculate_checksum(data)
	var checksum2 = SaveValidator.calculate_checksum(data)
	assert_eq(checksum1, checksum2, "相同数据应产生相同校验和")

func test_calculate_checksum_different_data():
	var data1 = {"version": "1.0", "player": {"level": 1}}
	var data2 = {"version": "1.0", "player": {"level": 2}}
	var checksum1 = SaveValidator.calculate_checksum(data1)
	var checksum2 = SaveValidator.calculate_checksum(data2)
	assert_ne(checksum1, checksum2, "不同数据应产生不同校验和")

## AC-2: 校验和存储在存档数据中
func test_add_checksum():
	var data = {"version": "1.0", "player": {"level": 1}}
	var data_with_checksum = SaveValidator.add_checksum(data)
	assert_true(data_with_checksum.has("checksum"), "应包含checksum字段")
	assert_ne(data_with_checksum["checksum"], 0, "校验和不应为0")

func test_add_checksum_preserves_data():
	var data = {"version": "1.0", "player": {"level": 1}}
	var data_with_checksum = SaveValidator.add_checksum(data)
	assert_eq(data_with_checksum["version"], "1.0", "应保留version字段")
	assert_true(data_with_checksum.has("player"), "应保留player字段")

## AC-3: 加载时验证CRC32校验和
func test_validate_save_data_valid():
	var data = {"version": "1.0", "player": {"level": 1}}
	var data_with_checksum = SaveValidator.add_checksum(data)
	var result = SaveValidator.validate_save_data(data_with_checksum)
	assert_true(result.valid, "有效数据应通过验证")
	assert_true(result.has_checksum, "应有校验和")
	assert_true(result.checksum_match, "校验和应匹配")

func test_validate_save_data_no_checksum():
	var data = {"version": "1.0", "player": {"level": 1}}
	var result = SaveValidator.validate_save_data(data)
	assert_false(result.valid, "无校验和数据应验证失败")
	assert_false(result.has_checksum, "应无校验和")

func test_validate_save_data_corrupted():
	var data = {"version": "1.0", "player": {"level": 1}}
	var data_with_checksum = SaveValidator.add_checksum(data)
	# 修改数据使其损坏
	data_with_checksum["player"]["level"] = 999
	var result = SaveValidator.validate_save_data(data_with_checksum)
	assert_false(result.valid, "损坏数据应验证失败")
	assert_true(result.has_checksum, "应有校验和")
	assert_false(result.checksum_match, "校验和不应匹配")

## AC-4: 校验和不匹配时显示错误
func test_validate_save_data_error_message():
	var data = {"version": "1.0", "player": {"level": 1}}
	var data_with_checksum = SaveValidator.add_checksum(data)
	data_with_checksum["player"]["level"] = 999
	var result = SaveValidator.validate_save_data(data_with_checksum)
	assert_ne(result.error_message, "", "应有错误信息")
	assert_true(result.error_message.contains("校验和"), "错误信息应包含校验和")

## AC-5: 损坏的存档尝试恢复部分数据
func test_validate_save_data_recovery():
	var data = {
		"version": "1.0",
		"player": {"level": 10, "experience": 1000, "gold": 500},
		"cards": {"collection": ["card_001"], "deck": ["card_001"]},
		"marks": {"good": 3, "evil": 1, "neutral": 2}
	}
	var data_with_checksum = SaveValidator.add_checksum(data)
	# 修改数据使其损坏
	data_with_checksum["player"]["level"] = 999
	var result = SaveValidator.validate_save_data(data_with_checksum)
	
	# 应该恢复部分数据
	assert_true(result.recovered_data.has("player"), "应恢复玩家数据")
	assert_true(result.recovered_data.has("cards"), "应恢复卡牌数据")
	assert_true(result.recovered_data.has("marks"), "应恢复印记数据")
	assert_eq(result.recovered_data["player"]["level"], 10, "应恢复原始等级")

## 测试版本兼容性检查
func test_check_version_compatibility():
	var data = {"version": "1.0", "player": {"level": 1}}
	var result = SaveValidator.check_version_compatibility(data, "1.0")
	assert_true(result.compatible, "相同版本应兼容")
	assert_false(result.needs_migration, "不应需要迁移")

func test_check_version_compatibility_different():
	var data = {"version": "1.0", "player": {"level": 1}}
	var result = SaveValidator.check_version_compatibility(data, "2.0")
	assert_false(result.compatible, "不同版本应不兼容")
	assert_true(result.needs_migration, "应需要迁移")

func test_check_version_compatibility_no_version():
	var data = {"player": {"level": 1}}
	var result = SaveValidator.check_version_compatibility(data, "1.0")
	assert_false(result.compatible, "无版本应不兼容")

## 测试恢复功能
func test_attempt_recovery():
	var data = {
		"version": "1.0",
		"player": {"level": 10, "experience": 1000, "gold": 500},
		"cards": {"collection": ["card_001"], "deck": ["card_001"]},
		"marks": {"good": 3, "evil": 1, "neutral": 2}
	}
	var recovered = SaveValidator._attempt_recovery(data)
	assert_true(recovered.has("player"), "应恢复玩家数据")
	assert_true(recovered.has("cards"), "应恢复卡牌数据")
	assert_true(recovered.has("marks"), "应恢复印记数据")
	assert_true(recovered.has("version"), "应恢复版本信息")

## 测试边界情况
func test_calculate_checksum_empty_data():
	var data = {}
	var checksum = SaveValidator.calculate_checksum(data)
	assert_ne(checksum, 0, "空数据也应有校验和")

func test_validate_save_data_empty():
	var data = {}
	var result = SaveValidator.validate_save_data(data)
	assert_false(result.valid, "空数据应验证失败")
