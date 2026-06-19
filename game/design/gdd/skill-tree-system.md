# 技能树系统

> **Status**: In Design
> **Author**: user + agents
> **Last Updated**: 2026-06-03
> **Implements Pillar**: 支柱4 — 持久的成长感

## Overview

技能树系统是游戏的RPG成长核心，管理玩家角色的技能解锁和升级。玩家通过消耗技能点解锁新技能或强化现有技能，塑造自己的角色构建风格。该系统与角色属性系统配合，为玩家提供长期成长目标和构建多样性。技能树分为三大分支：战斗、魔法、辅助，每个分支有多个层级，玩家需要在分支之间做出选择。

## Player Fantasy

"我的角色在不断成长，变得越来越强大" — 玩家应该感受到：
- **期待感**：每次升级都期待解锁新技能
- **成就感**：看到技能树逐渐填满，感受到自己的成长
- **掌控感**：可以选择技能发展方向，塑造独特的角色构建
- **策略深度**：需要在不同分支之间做出权衡

**情感锚点**：像暗黑破坏神中的技能树——每一个技能点都让你的角色变得独一无二。

**支柱对齐**：支柱4 — 持久的成长感。技能树系统直接服务于"玩家应该清楚地感受到自己在变强"这一支柱。

## Detailed Design

### Core Rules

1. **技能树结构**：
   - 三大分支：战斗、魔法、辅助
   - 每个分支5层，每层3个技能
   - 总计45个技能（3分支 × 5层 × 3技能）
   - 层级解锁：需要在前一层解锁至少1个技能才能解锁下一层

2. **技能类型**：
   - **被动技能**：永久加成，如"+10%攻击力"
   - **主动技能**：需要玩家主动使用，如"火球术"
   - **条件技能**：满足条件自动触发，如"暴击时回复生命"

3. **技能点获取**：
   - 每升1级获得1技能点
   - 完成特定任务获得额外技能点
   - 技能点可累积，不强制立即使用

4. **技能解锁规则**：
   - 消耗技能点解锁技能
   - 解锁技能需要满足前置条件（属性要求/前置技能）
   - 已解锁技能不可重置（除非使用特殊道具）

5. **技能效果**：
   - 被动技能：永久修改属性或战斗规则
   - 主动技能：消耗能量使用，有冷却时间
   - 条件技能：满足条件自动触发，有触发概率

### States and Transitions

| 状态 | 描述 | 触发条件 |
|------|------|----------|
| 锁定 | 技能未解锁，前置条件不满足 | 等级不足/前置技能未解锁 |
| 可解锁 | 前置条件满足，有技能点 | 前置技能解锁+有技能点 |
| 已解锁 | 技能已解锁，可以使用 | 消耗技能点解锁 |
| 升级中 | 技能正在升级 | 消耗技能点升级 |

**转换规则**：
- 锁定 → 可解锁：前置技能解锁 + 等级满足要求
- 可解锁 → 已解锁：消耗技能点
- 已解锁 → 升级中：消耗技能点升级（最高5级）
- 升级中 → 已解锁：升级完成

### Interactions with Other Systems

**上游依赖**：
- **角色属性系统**：提供属性数据，用于技能解锁条件判断

**下游被依赖**：
- **RPG成长系统**：依赖技能树提供技能解锁和升级功能

**交互接口**：
- `get_skill_tree() -> Dictionary`：获取完整技能树数据
- `get_skill(skill_id) -> SkillData`：获取单个技能数据
- `unlock_skill(skill_id) -> bool`：解锁技能
- `upgrade_skill(skill_id) -> bool`：升级技能
- `get_available_skills() -> Array`：获取可解锁技能列表
- `get_skill_points() -> int`：获取剩余技能点

## Formulas

The skill_point_cost formula is defined as:

`skill_point_cost = base_cost * (1 + skill_level * 0.5)`

**Variables:**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| base_cost | b | int | 1-3 | 基础技能点消耗 |
| skill_level | l | int | 1-5 | 技能当前等级 |

**Output Range:** 1 to 7.5 under normal play; 最低1点，最高7.5点
**Example:** 基础消耗2点的技能，升到3级需要 2 * (1 + 3*0.5) = 5点

The skill_effect_multiplier formula is defined as:

`skill_effect_multiplier = 1 + (skill_level - 1) * 0.3`

**Variables:**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| skill_level | l | int | 1-5 | 技能当前等级 |

**Output Range:** 1 to 2.2 under normal play; 1级为1倍，5级为2.2倍
**Example:** 3级技能效果为 1 + (3-1)*0.3 = 1.6倍

The unlock_requirement formula is defined as:

`unlock_requirement = min_level + (tier - 1) * 10`

**Variables:**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| min_level | m | int | 1-100 | 基础等级要求 |
| tier | t | int | 1-5 | 技能树层级 |

**Output Range:** 1 to 41 under normal play; 第1层1级，第5层41级
**Example:** 第3层技能需要 min_level + (3-1)*10 = min_level + 20级

## Edge Cases

- **If the player has no skill points but tries to unlock a skill**: Show "技能点不足" message and disable the unlock button.
- **If the player tries to unlock a skill without meeting level requirements**: Show "等级不足" message and display required level.
- **If the player tries to unlock a skill without prerequisite skills**: Show "需要先解锁前置技能" message and highlight required skills.
- **If the player tries to upgrade a skill beyond max level (5)**: Show "已达最大等级" message and disable upgrade button.
- **If the player tries to unlock a skill that's already unlocked**: Show "技能已解锁" message and disable unlock button.
- **If the player tries to reset skills without reset item**: Show "需要技能重置道具" message.
- **If the player tries to unlock skills in multiple branches simultaneously**: Allow it - no restriction on cross-branch unlocking.
- **If the player tries to unlock a skill during combat**: Block skill tree access during combat, show "战斗中无法操作技能树" message.

## Dependencies

**硬依赖**：
- **角色属性系统**：提供属性数据，用于技能解锁条件判断

**软依赖**：
- **存档系统**：技能树数据需要保存

**被依赖**：
- **RPG成长系统**：依赖技能树提供技能解锁和升级功能

**交互接口**：
- 角色属性系统 → 技能树系统：`get_attribute(attribute_name) -> int`
- 技能树系统 → 存档系统：`save_skill_tree(data)`, `load_skill_tree() -> Dictionary`
- 技能树系统 → RPG成长系统：`get_skill_tree()`, `unlock_skill()`, `upgrade_skill()`

## Tuning Knobs

| 参数 | 默认值 | 范围 | 描述 |
|------|--------|------|------|
| 技能点获取间隔 | 每级1点 | 1-3 | 每升1级获得的技能点数 |
| 最大技能等级 | 5 | 1-10 | 单个技能的最大等级 |
| 层级解锁要求 | 10级/层 | 5-20 | 每层需要的额外等级 |
| 技能树分支数量 | 3 | 2-5 | 技能树的分支数量 |
| 每层技能数量 | 3 | 2-5 | 每层的技能数量 |
| 技能重置道具掉率 | 5% | 1-20% | 技能重置道具的掉落概率 |
| 技能效果倍率 | 0.3/级 | 0.1-0.5 | 每级技能效果的提升倍率 |
| 前置技能要求 | 1个 | 1-3 | 解锁下一层需要的前置技能数量

## Visual/Audio Requirements

**视觉效果**：
- **技能树界面**：树状结构，分支清晰可见
- **技能图标**：每个技能有独特图标，显示技能类型
- **解锁动画**：技能解锁时有光效动画
- **升级动画**：技能升级时有数字弹出效果
- **锁定状态**：未解锁技能显示为灰色
- **可解锁状态**：可解锁技能有闪烁提示
- **已解锁状态**：已解锁技能显示为彩色

**音频效果**：
- **解锁音效**：技能解锁时播放清脆的叮声
- **升级音效**：技能升级时播放上升音效
- **错误音效**：操作失败时播放低沉的错误音效
- **界面音效**：切换分支时播放轻微的切换音效

## UI Requirements

**技能树界面**：
- 树状结构显示，分支清晰可见
- 每个技能显示：图标、名称、等级、效果描述
- 技能点剩余显示在界面顶部
- 分支切换按钮（战斗/魔法/辅助）

**技能详情界面**：
- 点击技能显示详情
- 显示：当前效果、下一级效果、解锁条件、消耗
- 解锁/升级按钮（根据状态显示/隐藏）

**交互规则**：
- 点击可解锁技能：弹出确认对话框
- 点击已解锁技能：显示升级选项
- 点击锁定技能：显示解锁条件
- 长按技能：显示详细说明

**响应式设计**：
- PC：鼠标点击交互
- 手柄：方向键导航，A键确认
- 触屏：点击交互

## Acceptance Criteria

- **AC-1**: GIVEN 玩家有技能点, WHEN 点击可解锁技能并确认, THEN 技能解锁成功，技能点减少
- **AC-2**: GIVEN 玩家没有技能点, WHEN 尝试解锁技能, THEN 显示"技能点不足"错误
- **AC-3**: GIVEN 玩家等级不足, WHEN 尝试解锁技能, THEN 显示"等级不足"错误
- **AC-4**: GIVEN 玩家没有前置技能, WHEN 尝试解锁技能, THEN 显示"需要先解锁前置技能"错误
- **AC-5**: GIVEN 技能已达到最大等级, WHEN 尝试升级, THEN 显示"已达最大等级"错误
- **AC-6**: GIVEN 玩家解锁技能, WHEN 技能效果生效, THEN 属性或战斗规则正确修改
- **AC-7**: GIVEN 玩家升级技能, WHEN 技能效果生效, THEN 效果按公式正确提升
- **AC-8**: GIVEN 玩家重置技能, WHEN 使用重置道具, THEN 所有技能重置，技能点返还
- **AC-9**: GIVEN 玩家保存游戏, WHEN 重新加载, THEN 技能树状态正确恢复
- **AC-10**: GIVEN 玩家在战斗中, WHEN 尝试打开技能树, THEN 显示"战斗中无法操作技能树"错误

## Open Questions

1. **技能重置机制**：是否允许玩家重置单个技能，还是只能重置整个技能树？
2. **技能组合效果**：不同技能组合是否产生额外效果？
3. **技能树扩展**：是否需要预留扩展空间，为DLC或更新添加新技能？
4. **技能平衡**：如何确保不同分支的技能强度平衡？
5. **技能获取方式**：除了升级，是否还有其他方式获取技能点？
