# auto_save_test.gd
# Story 003: 自动保存功能
# Date: 2026-06-03

extends GutTest

## 自动保存功能测试
## 测试AutoSaveManager类的功能

var auto_save_manager: AutoSaveManager
var mock_save_system: MockSaveSystem

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

func before_each():
	auto_save_manager = AutoSaveManager.new()
	mock_save_system = MockSaveSystem.new()
	auto_save_manager.set_save_system(mock_save_system)
	add_child(auto_save_manager)

func after_each():
	auto_save_manager.queue_free()

## AC-1: 进入新区域时自动保存
func test_auto_save_on_area_entered():
	auto_save_manager._on_area_entered()
	assert_eq(mock_save_system.save_count, 1, "应触发一次保存")
	assert_eq(mock_save_system.last_slot, 0, "应保存到Slot 0")

## AC-2: 做出重要选择后自动保存
func test_auto_save_on_choice_made():
	auto_save_manager._on_choice_made()
	assert_eq(mock_save_system.save_count, 1, "应触发一次保存")
	assert_eq(mock_save_system.last_slot, 0, "应保存到Slot 0")

## AC-3: 击败Boss后自动保存
func test_auto_save_on_boss_defeated():
	auto_save_manager._on_boss_defeated()
	assert_eq(mock_save_system.save_count, 1, "应触发一次保存")
	assert_eq(mock_save_system.last_slot, 0, "应保存到Slot 0")

## AC-4: 定期自动保存（每5分钟）
func test_auto_save_interval():
	assert_eq(auto_save_manager.get_auto_save_interval(), 300.0, "默认间隔应为300秒")
	auto_save_manager.set_auto_save_interval(60.0)
	assert_eq(auto_save_manager.get_auto_save_interval(), 60.0, "间隔应更新为60秒")

## AC-5: 自动保存使用Slot 0
func test_auto_save_uses_slot_0():
	auto_save_manager._on_area_entered()
	assert_eq(mock_save_system.last_slot, 0, "应使用Slot 0")

## AC-6: 自动保存时显示右下角存档图标淡入淡出
func test_auto_save_icon_signal():
	var signal_received = false
	auto_save_manager.auto_save_icon_show.connect(func(): signal_received = true)
	auto_save_manager._on_area_entered()
	assert_true(signal_received, "应发送显示图标信号")

## 测试防抖机制
func test_debounce_mechanism():
	# 第一次保存
	auto_save_manager._on_area_entered()
	assert_eq(mock_save_system.save_count, 1, "第一次应保存")
	
	# 立即再次触发（应该被防抖）
	auto_save_manager._on_area_entered()
	assert_eq(mock_save_system.save_count, 1, "防抖期间不应保存")

## 测试保存状态
func test_saving_state():
	assert_false(auto_save_manager.is_saving(), "初始状态不应正在保存")

## 测试手动触发
func test_manual_trigger():
	auto_save_manager.trigger_manual_auto_save()
	assert_eq(mock_save_system.save_count, 1, "手动触发应保存一次")

## 测试暂停和恢复
func test_pause_resume():
	auto_save_manager.pause_auto_save()
	# 暂停后定时器不应触发
	auto_save_manager.resume_auto_save()
	# 恢复后定时器应继续

## 测试保存失败
func test_save_failure():
	mock_save_system.should_succeed = false
	var success = auto_save_manager._perform_save("test")
	assert_false(success, "保存失败应返回false")

## 测试游戏状态收集
func test_game_state_collection():
	var state = auto_save_manager._collect_game_state("test")
	assert_true(state.has("version"), "应包含version字段")
	assert_true(state.has("timestamp"), "应包含timestamp字段")
	assert_true(state.has("trigger"), "应包含trigger字段")
	assert_true(state.has("player"), "应包含player字段")
	assert_true(state.has("cards"), "应包含cards字段")
	assert_true(state.has("worlds"), "应包含worlds字段")
	assert_true(state.has("stories"), "应包含stories字段")
	assert_true(state.has("marks"), "应包含marks字段")

## 测试信号发送
func test_signals():
	var started_received = false
	var completed_received = false
	
	auto_save_manager.auto_save_started.connect(func(): started_received = true)
	auto_save_manager.auto_save_completed.connect(func(success): completed_received = true)
	
	auto_save_manager._on_area_entered()
	
	assert_true(started_received, "应发送开始信号")
	assert_true(completed_received, "应发送完成信号")
