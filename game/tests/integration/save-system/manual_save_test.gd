# manual_save_test.gd
# Story 004: 手动保存功能
# Date: 2026-06-03

extends GutTest

## 手动保存功能测试
## 测试ManualSaveManager类的功能

var manual_save_manager: ManualSaveManager
var mock_save_system: MockSaveSystem
var mock_save_slot_manager: MockSaveSlotManager

# Mock SaveSystem
class MockSaveSystem:
	var save_count: int = 0
	var last_slot: int = -1
	var last_data: Dictionary = {}
	var should_succeed: bool = true
	
	func save_to_slot(slot_id: int, data: Dictionary) -> bool:
		save_count += 1
		last_slot = slot_id
		last_data = data
		return should_succeed

# Mock SaveSlotManager
class MockSaveSlotManager:
	var empty_slots: Array[int] = [1, 2, 3, 4, 5]
	
	func get_slot_info(slot_id: int):
		var info = SaveSlotManager.SaveSlotInfo.new(slot_id, "", slot_id in empty_slots, false)
		return info
	
	func is_slot_empty(slot_id: int) -> bool:
		return slot_id in empty_slots
	
	func get_overwritable_slots() -> Array[int]:
		var slots: Array[int] = []
		for i in range(1, 6):
			if i not in empty_slots:
				slots.append(i)
		return slots

func before_each():
	manual_save_manager = ManualSaveManager.new()
	mock_save_system = MockSaveSystem.new()
	mock_save_slot_manager = MockSaveSlotManager.new()
	manual_save_manager.set_save_system(mock_save_system)
	manual_save_manager.set_save_slot_manager(mock_save_slot_manager)
	add_child(manual_save_manager)

func after_each():
	manual_save_manager.queue_free()

## AC-1: 玩家在菜单中选择"保存游戏"
func test_request_save():
	var signal_received = false
	manual_save_manager.save_slot_list_requested.connect(func(): signal_received = true)
	manual_save_manager.request_save()
	assert_true(signal_received, "应发送显示存档槽列表信号")

## AC-2: 显示存档槽列表（Slot 1-5）
func test_get_manual_save_slots():
	var slots = manual_save_manager.get_manual_save_slots()
	assert_eq(slots.size(), 5, "应有5个手动存档槽")
	for i in range(5):
		assert_eq(slots[i].slot_id, i + 1, "槽位ID应为%d" % (i + 1))

## AC-3: 玩家选择槽位后保存游戏
func test_select_empty_slot():
	# 空槽位应该直接保存
	manual_save_manager.select_slot(1)
	assert_eq(mock_save_system.save_count, 1, "应保存一次")
	assert_eq(mock_save_system.last_slot, 1, "应保存到Slot 1")

func test_select_occupied_slot():
	# 已占用槽位应该请求确认
	mock_save_slot_manager.empty_slots = []
	var confirmation_received = false
	manual_save_manager.save_confirmation_required.connect(func(slot_id): confirmation_received = true)
	manual_save_manager.select_slot(1)
	assert_true(confirmation_received, "应发送确认信号")
	assert_eq(mock_save_system.save_count, 0, "不应立即保存")

## AC-4: 保存成功后显示确认信息
func test_save_success():
	var success_received = false
	var received_slot = -1
	manual_save_manager.save_completed.connect(func(success, slot_id): 
		success_received = success
		received_slot = slot_id
	)
	manual_save_manager.select_slot(1)
	assert_true(success_received, "应发送成功信号")
	assert_eq(received_slot, 1, "应返回正确的槽位ID")

## AC-5: 保存失败后显示错误信息
func test_save_failure():
	mock_save_system.should_succeed = false
	var error_received = false
	manual_save_manager.save_error.connect(func(message): error_received = true)
	manual_save_manager.select_slot(1)
	assert_true(error_received, "应发送错误信号")

## 测试确认覆盖
func test_confirm_overwrite():
	mock_save_slot_manager.empty_slots = []
	manual_save_manager.select_slot(1)
	manual_save_manager.confirm_overwrite()
	assert_eq(mock_save_system.save_count, 1, "确认后应保存")
	assert_eq(mock_save_system.last_slot, 1, "应保存到Slot 1")

## 测试取消覆盖
func test_cancel_overwrite():
	mock_save_slot_manager.empty_slots = []
	manual_save_manager.select_slot(1)
	manual_save_manager.cancel_overwrite()
	assert_eq(mock_save_system.save_count, 0, "取消后不应保存")

## 测试无效槽位
func test_invalid_slot():
	var error_received = false
	manual_save_manager.save_error.connect(func(message): error_received = true)
	manual_save_manager.select_slot(0)  # Slot 0是自动保存槽
	assert_true(error_received, "应发送错误信号")

## 测试空闲槽位数量
func test_empty_slot_count():
	assert_eq(manual_save_manager.get_empty_slot_count(), 5, "初始状态应有5个空闲槽位")
	mock_save_slot_manager.empty_slots = [1, 2]
	assert_eq(manual_save_manager.get_empty_slot_count(), 2, "应有2个空闲槽位")

## 测试是否有空闲槽位
func test_has_empty_slot():
	assert_true(manual_save_manager.has_empty_slot(), "初始状态应有空闲槽位")
	mock_save_slot_manager.empty_slots = []
	assert_false(manual_save_manager.has_empty_slot(), "无空闲槽位时应返回false")

## 测试取消保存
func test_cancel_save():
	manual_save_manager.select_slot(1)
	manual_save_manager.cancel_save()
	assert_eq(manual_save_manager.get_selected_slot(), -1, "选中槽位应重置为-1")
	assert_false(manual_save_manager.is_saving(), "不应正在保存")

## 测试游戏状态收集
func test_game_state_collection():
	var state = manual_save_manager._collect_game_state()
	assert_true(state.has("systems"), "应包含systems字段")
	assert_true(state.has("player"), "应包含player字段")
	assert_true(state.player.has("health"), "player应包含health字段")
	assert_true(state.player.has("level"), "player应包含level字段")
	assert_true(state.player.has("gold"), "player应包含gold字段")
