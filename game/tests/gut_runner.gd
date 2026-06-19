# gut_runner.gd
# GUT 测试运行器
# 用于在命令行中运行测试

extends SceneTree

func _init() -> void:
	# 检查 GUT 是否安装
	var gut_script = load("res://addons/gut/gut.gd")
	if gut_script == null:
		push_error("GUT not found. Please install GUT from AssetLib.")
		quit(1)
		return
	
	# 创建 GUT 实例
	var gut = gut_script.new()
	
	# 配置 GUT
	gut.set_should_exit(true)
	gut.set_log_level(1)
	
	# 运行测试
	gut.run_tests()
	
	# 等待测试完成
	await gut.all_tests_done
	
	# 退出
	quit(0)
