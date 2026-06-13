## 输入系统 - 核心实现

### 文件结构
- `input_manager.gd` - 输入管理器（主控制器）
- `input_context.gd` - 输入上下文状态机
- `input_buffer.gd` - 输入缓冲系统
- `input_mapping.gd` - 输入映射配置

### 核心功能
1. **输入映射**：将物理输入映射为语义化动作
2. **上下文管理**：管理不同游戏状态的输入响应
3. **输入缓冲**：支持Combo预输入
4. **设备检测**：自动检测键盘/鼠标或手柄

### 使用示例
```gdscript
# 获取输入管理器
var input_manager = get_node("/root/InputManager")

# 检查输入
if input_manager.is_action_just_pressed("play_card"):
    play_selected_card()

# 获取输入上下文
var context = input_manager.get_current_context()
```

### 信号
- `action_pressed(action_name: String)` - 动作按下
- `action_released(action_name: String)` - 动作释放
- `context_changed(old_context: String, new_context: String)` - 上下文切换
- `device_changed(device_type: String)` - 设备类型变化

### 性能预算
- 输入处理：< 1ms/帧
- 内存占用：< 10MB
