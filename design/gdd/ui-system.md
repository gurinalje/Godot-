# UI系统

> **Status**: In Design
> **Author**: user + agents
> **Last Updated**: 2026-06-03
> **Implements Pillar**: 支柱2 — 爽快的策略深度

## Overview

UI系统是游戏的全局基础设施，管理所有游戏界面的显示、交互和状态。该系统为战斗、探索、对话、菜单等所有游戏状态提供界面支持，确保玩家能够清晰地获取信息并进行操作。

## Player Fantasy

"界面清晰易用，让我专注于游戏" — 玩家应该感受到：
- **清晰感**：信息层次分明，重要信息突出
- **掌控感**：操作反馈及时，交互流畅
- **沉浸感**：界面风格与游戏世界一致

**支柱对齐**：支柱2 — 爽快的策略深度。UI是"策略深度"的展示窗口。

## Detailed Design

### Core Rules

1. **界面层级**：
   - HUD层：战斗信息、生命值、能量
   - 菜单层：暂停菜单、设置界面
   - 对话层：对话框、选择按钮
   - 弹窗层：确认框、提示框

2. **状态管理**：
   - 探索状态：显示地图、任务追踪
   - 战斗状态：显示手牌、能量、敌人信息
   - 对话状态：显示对话框、选择按钮
   - 菜单状态：显示菜单选项

3. **交互模式**：
   - 鼠标/触屏：点击、拖拽
   - 手柄：方向键导航、A键确认
   - 键盘：快捷键操作

4. **动画系统**：
   - 界面切换动画：淡入淡出、滑动
   - 元素动画：弹出、缩放、旋转
   - 反馈动画：成功、失败、警告

5. **响应式设计**：
   - 支持不同分辨率
   - 支持不同屏幕比例
   - 支持不同DPI

### States and Transitions

| 状态 | 描述 | 触发条件 |
|------|------|----------|
| 探索 | 探索界面 | 进入探索状态 |
| 战斗 | 战斗界面 | 进入战斗状态 |
| 对话 | 对话界面 | 进入对话状态 |
| 菜单 | 菜单界面 | 打开菜单 |
| 弹窗 | 弹窗界面 | 触发弹窗 |

### Interactions with Other Systems

**上游依赖**：无

**下游被依赖**：
- 所有需要界面的系统

**交互接口**：
- `show_screen(screen_name)`: 显示界面
- `hide_screen(screen_name)`: 隐藏界面
- `show_popup(popup_data)`: 显示弹窗
- `hide_popup()`: 隐藏弹窗
- `show_tooltip(text, position)`: 显示提示
- `hide_tooltip()`: 隐藏提示

## Formulas

The ui_animation_duration formula is defined as:

`animation_duration = base_duration * distance_factor`

**Variables:**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| base_duration | d | float | 0.1-1.0 | 基础动画时长（秒） |
| distance_factor | f | float | 0.5-2.0 | 距离因子 |

**Output Range:** 0.05 to 2.0 under normal play; 最短0.05秒，最长2秒
**Example:** 基础时长0.3秒，距离因子1.5，动画时长为0.45秒

## Edge Cases

- **If UI element overlaps another**: Higher layer takes priority for interaction.
- **If animation interrupted**: Skip to end state, don't play remaining animation.
- **If screen resolution changes**: Re-layout all UI elements.
- **If input device changes**: Switch input hints (keyboard/gamepad/touch).
- **If UI state corrupted**: Reset to default state.
- **If popup already showing**: Queue new popup, show after current closes.
- **If tooltip text too long**: Truncate with ellipsis, show full text on hover.
- **If menu opens during animation**: Pause animation, resume when menu closes.

## Dependencies

**硬依赖**：无

**软依赖**：
- 存档系统：保存UI设置

**被依赖**：
- 所有需要界面的系统

## Tuning Knobs

| 参数 | 默认值 | 范围 | 描述 |
|------|--------|------|------|
| 动画时长 | 0.3秒 | 0.1-1.0 | 默认动画时长 |
| 弹窗显示时间 | 3秒 | 1-10 | 自动关闭弹窗的时间 |
| 提示延迟 | 0.5秒 | 0.1-2.0 | 鼠标悬停后显示提示的延迟 |
| 界面切换时长 | 0.5秒 | 0.1-1.0 | 界面切换动画时长 |
| 最小点击区域 | 44px | 20-100 | 最小可点击区域（适配触屏） |
| 字体大小 | 16px | 12-24 | 默认字体大小 |
| 边距 | 16px | 8-32 | 默认界面边距 |
| 圆角 | 8px | 0-16 | 默认圆角大小 |

## Visual/Audio Requirements

**视觉效果**：
- 界面风格：华丽的暗黑童话风格
- 字体：清晰易读的无衬线字体
- 颜色：高对比度，重要信息突出
- 动画：流畅的过渡动画

**音频效果**：
- 界面切换音效：轻微的切换声
- 按钮点击音效：清脆的点击声
- 弹窗显示音效：轻微的弹出声
- 错误提示音效：低沉的错误声

## UI Requirements

**HUD界面**：
- 生命值条：显示当前/最大生命值
- 能量条：显示当前/最大能量
- 手牌区域：显示当前手牌
- 敌人信息：显示敌人生命值和状态
- 小地图：显示当前位置和目标

**菜单界面**：
- 暂停菜单：继续、设置、退出
- 设置界面：音量、画面、控制设置
- 存档界面：保存、加载、删除存档

**对话界面**：
- 对话框：显示NPC对话
- 选择按钮：显示玩家选择
- 好感度显示：显示NPC好感度

## Acceptance Criteria

- **AC-1**: GIVEN 玩家进入战斗, WHEN 战斗开始, THEN 战斗界面正确显示
- **AC-2**: GIVEN 玩家打出卡牌, WHEN 卡牌使用, THEN 卡牌动画播放
- **AC-3**: GIVEN 玩家打开菜单, WHEN 菜单打开, THEN 菜单界面正确显示
- **AC-4**: GIVEN 玩家调整设置, WHEN 设置修改, THEN 设置立即生效
- **AC-5**: GIVEN 玩家切换输入设备, WHEN 输入设备改变, THEN 输入提示正确切换
- **AC-6**: GIVEN 玩家触屏操作, WHEN 点击界面, THEN 点击区域足够大
- **AC-7**: GIVEN 玩家打开对话, WHEN 对话开始, THEN 对话框正确显示
- **AC-8**: GIVEN 玩家选择选项, WHEN 选择确认, THEN 选择动画播放
- **AC-9**: GIVEN 界面动画播放, WHEN 动画完成, THEN 界面状态正确
- **AC-10**: GIVEN 玩家保存游戏, WHEN 重新加载, THEN UI设置恢复

## Open Questions

1. **UI主题系统**：是否需要支持多种UI主题（如亮色/暗色）？
2. **UI自定义**：是否允许玩家自定义UI布局？
3. **UI无障碍**：是否需要支持色盲模式、大字体模式？
4. **UI性能**：如何优化UI渲染性能？
5. **UI扩展**：是否需要预留DLC界面扩展接口？
