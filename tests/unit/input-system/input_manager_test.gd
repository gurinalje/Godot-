# 输入系统单元测试
# 测试输入管理器、缓冲系统和上下文管理

extends GutTest

## 测试输入管理器
func test_input_manager_initialization() -> void:
	var input_manager = InputManager.new()
	add_child(input_manager)
	
	# 验证初始化
	assert_not_null(input_manager.input_buffer, "Input buffer should be initialized")
	assert_not_null(input_manager.input_mapping, "Input mapping should be initialized")
	assert_eq(input_manager.current_context, InputManager.InputContext.EXPLORATION, "Default context should be exploration")
	
	input_manager.queue_free()

## 测试输入缓冲
func test_input_buffer() -> void:
	var buffer = InputBuffer.new()
	add_child(buffer)
	
	# 测试添加动作
	buffer.add_to_buffer("test_action")
	assert_eq(buffer.get_buffer_size(), 1, "Buffer should have 1 action")
	
	# 测试获取缓冲动作
	assert_true(buffer.has_buffered_action("test_action"), "Should have buffered action")
	assert_eq(buffer.get_buffer_size(), 0, "Buffer should be empty after consumption")
	
	# 测试缓冲上限
	buffer.add_to_buffer("action1")
	buffer.add_to_buffer("action2")
	buffer.add_to_buffer("action3")  # 应该覆盖第一个
	assert_eq(buffer.get_buffer_size(), 2, "Buffer should respect max size")
	
	buffer.queue_free()

## 测试输入上下文
func test_input_context() -> void:
	var context = InputContext.new()
	add_child(context)
	
	# 测试初始上下文
	assert_eq(context.get_current_context(), InputManager.InputContext.EXPLORATION, "Should start in exploration")
	
	# 测试上下文切换
	var result = context.switch_to(InputManager.InputContext.COMBAT)
	assert_true(result, "Should be able to switch to combat")
	assert_eq(context.get_current_context(), InputManager.InputContext.COMBAT, "Should be in combat context")
	
	# 测试优先级（不能从战斗切换到探索）
	result = context.switch_to(InputManager.InputContext.EXPLORATION)
	assert_false(result, "Should not be able to switch to lower priority context")
	
	context.queue_free()

## 测试输入映射
func test_input_mapping() -> void:
	var mapping = InputMapping.new()
	add_child(mapping)
	
	# 测试默认映射设置
	mapping.setup_default_mappings()
	
	# 验证动作存在
	var actions = mapping.get_all_actions()
	assert_true(actions.size() > 0, "Should have default actions")
	assert_true("play_card" in actions, "Should have play_card action")
	assert_true("select_card" in actions, "Should have select_card action")
	
	mapping.queue_free()

## 测试上下文动作过滤
func test_context_action_filtering() -> void:
	var mapping = InputMapping.new()
	add_child(mapping)
	
	mapping.setup_default_mappings()
	
	# 测试战斗上下文的动作
	var combat_actions = mapping.get_context_actions(InputManager.InputContext.COMBAT)
	assert_true("play_card" in combat_actions, "Combat should allow play_card")
	assert_true("select_card" in combat_actions, "Combat should allow select_card")
	
	# 测试探索上下文的动作
	var exploration_actions = mapping.get_context_actions(InputManager.InputContext.EXPLORATION)
	assert_true("move_up" in exploration_actions, "Exploration should allow move_up")
	assert_false("play_card" in exploration_actions, "Exploration should not allow play_card")
	
	mapping.queue_free()

## 测试设备检测
func test_device_detection() -> void:
	var input_manager = InputManager.new()
	add_child(input_manager)
	
	# 测试默认设备
	assert_eq(input_manager.current_device, "keyboard", "Default device should be keyboard")
	
	input_manager.queue_free()

## 测试信号发射
func test_signals() -> void:
	var input_manager = InputManager.new()
	add_child(input_manager)
	
	# 连接信号
	var context_changed_received = false
	input_manager.context_changed.connect(func(old, new): context_changed_received = true)
	
	# 切换上下文
	input_manager.switch_context(InputManager.InputContext.COMBAT)
	
	# 验证信号发射
	assert_true(context_changed_received, "Context changed signal should be emitted")
	
	input_manager.queue_free()
