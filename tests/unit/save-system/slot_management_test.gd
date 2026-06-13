# slot_management_test.gd
# Story 002: 存档槽管理
# Date: 2026-06-03

extends GutTest

## 存档槽管理测试
## 测试SaveSlotManager类的功能

var save_slot_manager: SaveSlotManager

func before_each():
	save_slot_manager = SaveSlotManager.new()
	# 初始化存档目录
	SaveSlotManager.init_save_directory()

## AC-1: 存档系统有6个存档槽
func test_has_six_slots():
	var slots = SaveSlotManager.get_all_slot_info()
	assert_eq(slots.size(), 6, "应有6个存档槽")

## AC-2: Slot 0为自动保存槽，只读
func test_slot_0_is_auto_save():
	assert_true(SaveSlotManager.is_slot_auto_save(0), "Slot 0应为自动保存槽")
	assert_false(SaveSlotManager.is_slot_manual_save(0), "Slot 0不应该是手动保存槽")

func test_slot_0_is_read_only():
	# 自动保存槽不可删除
	var result = SaveSlotManager.delete_slot(0)
	assert_false(result, "自动保存槽不可删除")

## AC-3: Slot 1-5为手动保存槽，可读写
func test_slots_1_5_are_manual_save():
	for i in range(1, 6):
		assert_true(SaveSlotManager.is_slot_manual_save(i), "Slot %d应为手动保存槽" % i)
		assert_false(SaveSlotManager.is_slot_auto_save(i), "Slot %d不应该是自动保存槽" % i)

## AC-4: 存档文件命名为save_slot_0.json到save_slot_5.json
func test_file_naming():
	for i in range(6):
		var expected_path = "user://saves/save_slot_%d.json" % i
		var actual_path = SaveSlotManager.get_slot_file_path(i)
		assert_eq(actual_path, expected_path, "Slot %d文件路径应为%s" % [i, expected_path])

## AC-5: 存档槽满时提示玩家覆盖现有存档
func test_is_manual_slots_full():
	# 初始状态应该不满
	assert_false(SaveSlotManager.is_manual_slots_full(), "初始状态手动槽位不应已满")

func test_get_overwritable_slots():
	# 初始状态应该没有可覆盖的槽位
	var slots = SaveSlotManager.get_overwritable_slots()
	assert_eq(slots.size(), 0, "初始状态不应有可覆盖的槽位")

## AC-6: 每个存档槽显示存档时间、游戏时长、当前位置
func test_slot_info_structure():
	var info = SaveSlotManager.get_slot_info(0)
	assert_not_null(info, "Slot 0信息不应为空")
	assert_eq(info.slot_id, 0, "槽位ID应为0")
	assert_true(info.is_auto_save, "应为自动保存槽")
	assert_not_null(info.file_path, "文件路径不应为空")

## 测试空槽位查询
func test_empty_slot_query():
	# 初始状态所有槽位应该为空
	for i in range(6):
		assert_true(SaveSlotManager.is_slot_empty(i), "Slot %d初始状态应为空" % i)

## 测试获取空闲手动槽位
func test_get_empty_manual_slot():
	var slot = SaveSlotManager.get_empty_manual_slot()
	assert_eq(slot, 1, "第一个空闲手动槽位应为1")

## 测试槽位统计
func test_slot_statistics():
	var stats = SaveSlotManager.get_slot_statistics()
	assert_eq(stats.total_slots, 6, "总槽位数应为6")
	assert_eq(stats.empty_slots, 6, "初始状态空槽位数应为6")
	assert_eq(stats.manual_slots_used, 0, "初始状态已用手动槽位数应为0")
	assert_false(stats.auto_save_exists, "初始状态自动保存不应存在")
	assert_eq(stats.manual_slots_available, 5, "初始状态可用手动槽位数应为5")

## 测试删除槽位
func test_delete_empty_slot():
	# 删除空槽位应该返回false
	var result = SaveSlotManager.delete_slot(1)
	assert_false(result, "删除空槽位应返回false")

## 测试边界情况
func test_invalid_slot_id():
	# 测试无效槽位ID
	assert_null(SaveSlotManager.get_slot_info(-1), "无效槽位ID应返回null")
	assert_null(SaveSlotManager.get_slot_info(6), "无效槽位ID应返回null")
	assert_true(SaveSlotManager.is_slot_empty(-1), "无效槽位ID应返回true")
	assert_true(SaveSlotManager.is_slot_empty(6), "无效槽位ID应返回true")
