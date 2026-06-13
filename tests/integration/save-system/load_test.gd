# load_test.gd
# Story 005: 加载功能
# Date: 2026-06-03

extends GutTest

## 加载功能测试
## 测试LoadManager类的功能

var load_manager: LoadManager
var mock_save_system: MockSaveSystem
var mock_save_slot_manager: MockSaveSlotManager

# Mock SaveSystem
class MockSaveSystem:
	var load_count: int = 0
	var last_slot: int = -1
	var should_succeed: bool = true
	var mock_data: Dictionary = {"version": "1.0", "player": {"level": 10}}
	
	func load_from_slot(slot_id: int) -> Dictionary:
		load_count += 1
		last_slot = slot_id
		if should_succeed:
			return {"success": true, "data": mock_data}
		else:
			return {"success": false, "error_message": "加载失败"}

# Mock SaveSlotManager
class MockSaveSlotManager:
	var filled_slots: Array[int] = [0, 1, 2]
	
	func get_slot_info(slot_id: int):
		var is_empty = slot_id not in filled_slots
		var info = SaveSlotManager.SaveSlotInfo.new(slot_id, "", is_empty, slot_id == 0)
		if not is_empty:
			info.timestamp = "2026-06-03T12:00:00"
			info.play_time = "2小时"
			info.location = "森林区域"
		return info
	
	func is_slot_empty(slot_id: int) -> bool:
		return slot_id not in filled_slots

func before_each():
	load_manager = LoadManager.new()
	mock_save_system = MockSaveSystem.new()
	mock_save_slot_manager = MockSaveSlotManager.new()
	load_manager.set_save_system(mock_save_system)
	load_manager.set_save_slot_manager(mock_save_slot_manager)
	add_child(load_manager)

func after_each():
	load_manager.queue_free()

## AC-1: 玩家在菜单中选择"加载游戏"
func test_request_load():
	var signal_received = false
	load_manager.load_slot_list_requested.connect(func(): signal_received = true)
	load_manager.request_load()
	assert_true(signal_received, "应发送显示存档槽列表信号")

## AC-2: 显示存档槽列表（所有槽位）
func test_get_all_save_slots():
	var slots = load_manager.get_all_save_slots()
	assert_eq(slots.size(), 6, "应有6个存档槽")
	for i in range(6):
		assert_eq(slots[i].slot_id, i, "槽位ID应为%d" % i)

## AC-3: 玩家选择槽位后加载游戏
func test_select_filled_slot():
	# 有存档的槽位应该加载
	load_manager.select_slot(1)
	assert_eq(mock_save_system.load_count, 1, "应加载一次")
	assert_eq(mock_save_system.last_slot, 1, "应从Slot 1加载")

func test_select_empty_slot():
	# 空槽位应该报错
	var error_received = false
	load_manager.load_error.connect(func(message): error_received = true)
	load_manager.select_slot(3)  # Slot 3是空的
	assert_true(error_received, "应发送错误信号")
	assert_eq(mock_save_system.load_count, 0, "不应加载")

## AC-4: 加载成功后恢复游戏状态
func test_load_success():
	var success_received = false
	var received_slot = -1
	load_manager.load_completed.connect(func(success, slot_id): 
		success_received = success
		received_slot = slot_id
	)
	load_manager.select_slot(1)
	assert_true(success_received, "应发送成功信号")
	assert_eq(received_slot, 1, "应返回正确的槽位ID")

## AC-5: 加载失败后显示错误信息
func test_load_failure():
	mock_save_system.should_succeed = false
	var error_received = false
	load_manager.load_error.connect(func(message): error_received = true)
	load_manager.select_slot(1)
	assert_true(error_received, "应发送错误信号")

## 测试游戏状态恢复信号
func test_game_state_restored_signal():
	var signal_received = false
	load_manager.game_state_restored.connect(func(): signal_received = true)
	load_manager.select_slot(1)
	assert_true(signal_received, "应发送游戏状态恢复信号")

## 测试无效槽位
func test_invalid_slot():
	var error_received = false
	load_manager.load_error.connect(func(message): error_received = true)
	load_manager.select_slot(6)  # 无效槽位
	assert_true(error_received, "应发送错误信号")

## 测试有存档的槽位数量
func test_filled_slot_count():
	assert_eq(load_manager.get_filled_slot_count(), 3, "应有3个有存档的槽位")

## 测试是否有存档
func test_has_save_data():
	assert_true(load_manager.has_save_data(), "应有存档数据")

## 测试自动存档信息
func test_auto_save_info():
	var info = load_manager.get_auto_save_info()
	assert_eq(info.slot_id, 0, "应为Slot 0")
	assert_false(info.is_empty, "自动存档不应为空")
	assert_eq(info.timestamp, "2026-06-03T12:00:00", "时间戳应匹配")
	assert_eq(info.location, "森林区域", "位置应匹配")

## 测试手动存档信息
func test_manual_save_infos():
	var infos = load_manager.get_manual_save_infos()
	assert_eq(infos.size(), 5, "应有5个手动存档槽")
	assert_eq(infos[0].slot_id, 1, "第一个槽位ID应为1")
	assert_false(infos[0].is_empty, "Slot 1不应为空")
	assert_true(infos[2].is_empty, "Slot 3应为空")

## 测试取消加载
func test_cancel_load():
	load_manager.select_slot(1)
	load_manager.cancel_load()
	assert_eq(load_manager.get_selected_slot(), -1, "选中槽位应重置为-1")
	assert_false(load_manager.is_loading(), "不应正在加载")
