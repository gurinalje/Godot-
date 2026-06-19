# 音频系统

> **Status**: In Design
> **Author**: user + agents
> **Last Updated**: 2026-06-03
> **Implements Pillar**: 支柱2 — 爽快的策略深度

## Overview

音频系统是游戏的全局基础设施，管理所有音效和音乐的播放、音量控制、混音和优先级。该系统为战斗、探索、对话等所有游戏状态提供音频反馈，增强玩家的沉浸感和爽快感。

## Player Fantasy

"游戏的声音让我更投入" — 玩家应该感受到：
- **沉浸感**：音效和音乐与游戏状态完美配合
- **爽快感**：卡牌打出、Combo触发时有强烈的音效反馈
- **掌控感**：可以自定义音量设置

**支柱对齐**：支柱2 — 爽快的策略深度。音效是"爽快感"的关键组成部分。

## Detailed Design

### Core Rules

1. **音频分类**：
   - BGM：背景音乐，循环播放
   - SFX：音效，一次性播放
   - Voice：语音，一次性播放
   - Ambient：环境音，循环播放

2. **音量控制**：
   - 主音量：0-100%
   - BGM音量：0-100%
   - SFX音量：0-100%
   - Voice音量：0-100%

3. **优先级系统**：
   - 高优先级：战斗音效、Boss音乐
   - 中优先级：普通音效、探索音乐
   - 低优先级：环境音、UI音效

4. **打断规则**：
   - 高优先级可以打断低优先级
   - 同优先级按时间顺序播放
   - 同类音效限制最大同时播放数量

5. **混音规则**：
   - 战斗时降低BGM音量，突出SFX
   - 对话时降低所有音量，突出Voice
   - 菜单时降低所有音量

### States and Transitions

| 状态 | 描述 | 触发条件 |
|------|------|----------|
| 静音 | 无音频播放 | 游戏暂停/最小化 |
| 探索 | 探索BGM + 环境音 | 进入探索状态 |
| 战斗 | 战斗BGM + 战斗音效 | 进入战斗状态 |
| 对话 | 对话BGM + 语音 | 进入对话状态 |
| 菜单 | 菜单音效 | 打开菜单 |

### Interactions with Other Systems

**上游依赖**：无

**下游被依赖**：
- 所有需要音效的系统

**交互接口**：
- `play_sfx(sfx_name, priority)`: 播放音效
- `play_bgm(bgm_name, fade_time)`: 播放背景音乐
- `stop_bgm(fade_time)`: 停止背景音乐
- `set_volume(category, volume)`: 设置音量
- `mute_all()`: 静音所有
- `unmute_all()`: 取消静音

## Formulas

The volume_adjustment formula is defined as:

`final_volume = base_volume * category_multiplier * priority_multiplier`

**Variables:**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| base_volume | v | float | 0-1 | 基础音量 |
| category_multiplier | c | float | 0-1 | 分类倍率 |
| priority_multiplier | p | float | 0-1 | 优先级倍率 |

**Output Range:** 0 to 1 under normal play; 0为静音，1为最大音量
**Example:** 基础音量0.8，分类倍率0.5，优先级倍率1.0，最终音量为0.4

## Edge Cases

- **If too many SFX play simultaneously**: Limit to max 10 concurrent SFX, drop lowest priority.
- **If BGM changes during fade**: Interrupt current fade, start new BGM immediately.
- **If game loses focus**: Pause all audio, resume when focus returns.
- **If audio file not found**: Log error, play silent placeholder.
- **If volume set to 0**: Mute category, don't stop playback.
- **If priority tie**: First-come-first-served.
- **If SFX loop requested**: Loop until stopped.
- **If BGM fade time is 0**: Immediate switch, no crossfade.

## Dependencies

**硬依赖**：无

**软依赖**：
- 存档系统：保存音量设置

**被依赖**：
- 所有需要音效的系统

## Tuning Knobs

| 参数 | 默认值 | 范围 | 描述 |
|------|--------|------|------|
| 最大同时SFX数 | 10 | 5-20 | 同时播放的最大音效数量 |
| BGM淡入淡出时间 | 2秒 | 0-5 | BGM切换的淡入淡出时间 |
| 主音量 | 80% | 0-100% | 默认主音量 |
| BGM音量 | 70% | 0-100% | 默认BGM音量 |
| SFX音量 | 90% | 0-100% | 默认SFX音量 |
| Voice音量 | 100% | 0-100% | 默认Voice音量 |
| 战斗BGM音量倍率 | 0.8 | 0.5-1.0 | 战斗时BGM音量降低倍率 |
| 对话音量倍率 | 0.3 | 0.1-0.5 | 对话时其他音量降低倍率 |

## Visual/Audio Requirements

**音频资源**：
- BGM：探索、战斗、对话、菜单、Boss战（5-10首）
- SFX：卡牌打出、Combo触发、伤害、治疗、升级、UI操作（50-100个）
- Voice：NPC对话（可选，0-20条）
- Ambient：风声、水流、鸟叫（5-10个）

**音频格式**：
- BGM：OGG（循环支持好）
- SFX：WAV（低延迟）
- Voice：OGG（压缩率高）

## UI Requirements

**音量设置界面**：
- 滑动条控制各类音量
- 静音按钮
- 测试音效按钮

**交互规则**：
- 实时预览音量变化
- 保存设置到存档

## Acceptance Criteria

- **AC-1**: GIVEN 玩家进入战斗, WHEN 战斗开始, THEN 战斗BGM播放，音效正常
- **AC-2**: GIVEN 玩家打出卡牌, WHEN 卡牌使用, THEN 对应音效播放
- **AC-3**: GIVEN 玩家触发Combo, WHEN 连锁触发, THEN 连锁音效播放
- **AC-4**: GIVEN 玩家调整音量, WHEN 设置音量, THEN 音量实时变化
- **AC-5**: GIVEN 玩家静音, WHEN 点击静音, THEN 所有音频停止
- **AC-6**: GIVEN 玩家进入对话, WHEN 对话开始, THEN BGM音量降低，语音正常
- **AC-7**: GIVEN 玩家打开菜单, WHEN 菜单打开, THEN 所有音量降低
- **AC-8**: GIVEN 玩家保存游戏, WHEN 重新加载, THEN 音量设置恢复
- **AC-9**: GIVEN 音效播放过多, WHEN 超过最大数量, THEN 低优先级音效被丢弃
- **AC-10**: GIVEN 游戏失去焦点, WHEN 窗口最小化, THEN 所有音频暂停

## Open Questions

1. **音频压缩**：是否需要对音频资源进行压缩以减小包体积？
2. **音频流式加载**：是否需要支持音频流式加载以减少内存占用？
3. **音频可视化**：是否需要音频可视化效果（如音量条）？
4. **音频无障碍**：是否需要为听障玩家提供视觉提示？
5. **音频扩展**：是否需要预留DLC音频扩展接口？
