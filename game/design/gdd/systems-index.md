# 系统索引 — 命运卡牌局

> **版本**: 1.0  
> **创建日期**: 2026-06-03  
> **游戏概念**: design/gdd/game-concept.md

---

## 系统枚举

### 基础层（Foundation）— 4个系统

| # | 系统 | 类别 | 描述 | 依赖 |
|---|------|------|------|------|
| 1 | 存档系统 | 全局 | 游戏进度保存和加载 | 无 |
| 2 | 输入系统 | 全局 | 玩家输入处理和映射 | 无 |
| 3 | 卡牌数据库 | 卡牌 | 卡牌定义、属性、效果数据 | 无 |
| 4 | 角色属性系统 | RPG | 属性定义、成长曲线 | 无 |

### 核心层（Core）— 12个系统

| # | 系统 | 类别 | 描述 | 依赖 |
|---|------|------|------|------|
| 5 | 伤害计算系统 | 战斗 | 伤害公式、暴击、元素克制 | 4, 3 |
| 6 | 状态效果系统 | 战斗 | Buff/Debuff的管理和效果 | 3 |
| 7 | Combo连锁系统 | 战斗 | 卡牌之间的连锁触发机制 | 3 |
| 8 | 环境系统 | 战斗 | 环境/地形对战斗的影响 | 无 |
| 9 | 召唤物系统 | 战斗 | 召唤生物的管理和AI | 5, 6 |
| 10 | 故事印记系统 | 选择 | 选择留下的印记及其效果 | 无 |
| 11 | 元素系统 | 选择 | 元素切换和卡牌池解锁 | 3 |
| 12 | 规则改写系统 | 选择 | 永久改变战斗规则的机制 | 28 |
| 13 | 对话系统 | 叙事 | 对话树、选择、分支 | 无 |
| 14 | 技能树系统 | RPG | 技能解锁和升级 | 4 |
| 15 | 音频系统 | 全局 | 音效和音乐播放 | 无 |
| 16 | UI系统 | 全局 | 游戏界面和交互 | 无 |

### 功能层（Feature）— 8个系统

| # | 系统 | 类别 | 描述 | 依赖 |
|---|------|------|------|------|
| 17 | 卡牌战斗系统 | 战斗 | 卡牌对战的核心机制 | 5, 6, 7, 8, 9 |
| 18 | 选择系统 | 选择 | 选择改变游戏规则和故事 | 10, 11, 12 |
| 19 | 世界状态系统 | 世界 | 世界进度和解锁条件 | 18 |
| 20 | 区域系统 | 世界 | 每个世界的区域结构和内容 | 19, 27 |
| 21 | NPC系统 | 叙事 | NPC交互、对话、关系管理 | 13, 10 |
| 22 | 剧情追踪系统 | 叙事 | 主线/支线/隐藏剧情的进度追踪 | 18, 21 |
| 23 | 卡组构筑系统 | 卡牌 | 卡组构建规则和限制 | 3, 26 |
| 24 | 卡牌升级系统 | 卡牌 | 卡牌强化和进化 | 3, 4 |

### 表现层（Presentation）— 4个系统

| # | 系统 | 类别 | 描述 | 依赖 |
|---|------|------|------|------|
| 25 | 世界探索系统 | 世界 | 多世界探索和区域解锁 | 20, 19 |
| 26 | 卡组管理系统 | 卡牌 | 卡牌收集、升级、构筑 | 23, 24 |
| 27 | 叙事系统 | 叙事 | 三层剧情结构和选择影响 | 22, 21, 13 |
| 28 | RPG成长系统 | RPG | 角色属性成长和技能解锁 | 4, 14 |

### 打磨层（Polish）— 1个系统

| # | 系统 | 类别 | 描述 | 依赖 |
|---|------|------|------|------|
| 29 | 隐藏内容系统 | 世界 | 彩蛋、隐藏Boss、稀有卡牌 | 20, 19 |

---

## 依赖层级图

```
Foundation (基础层) — MVP
├── [1] 存档系统
├── [2] 输入系统
├── [3] 卡牌数据库
└── [4] 角色属性系统

Core (核心层) — MVP
├── [5] 伤害计算系统 (→ 4, 3)
├── [6] 状态效果系统 (→ 3)
├── [7] Combo连锁系统 (→ 3)
├── [8] 环境系统 (无依赖)
├── [9] 召唤物系统 (→ 5, 6)
├── [10] 故事印记系统 (无依赖)
├── [11] 元素系统 (→ 3)
├── [12] 规则改写系统 (→ 28)
├── [13] 对话系统 (无依赖)
├── [14] 技能树系统 (→ 4)
├── [15] 音频系统 (无依赖)
└── [16] UI系统 (无依赖)

Feature (功能层) — 垂直切片
├── [17] 卡牌战斗系统 (→ 5, 6, 7, 8, 9)
├── [18] 选择系统 (→ 10, 11, 12)
├── [19] 世界状态系统 (→ 18)
├── [20] 区域系统 (→ 19, 27)
├── [21] NPC系统 (→ 13, 10)
├── [22] 剧情追踪系统 (→ 18, 21)
├── [23] 卡组构筑系统 (→ 3, 26)
└── [24] 卡牌升级系统 (→ 3, 4)

Presentation (表现层) — Alpha
├── [25] 世界探索系统 (→ 20, 19)
├── [26] 卡组管理系统 (→ 23, 24)
├── [27] 叙事系统 (→ 22, 21, 13)
└── [28] RPG成长系统 (→ 4, 14)

Polish (打磨层) — 完整版
└── [29] 隐藏内容系统 (→ 20, 19)
```

---

## 推荐设计顺序

### MVP 阶段（12个系统）

| 顺序 | 系统 | 里程碑 | 理由 |
|------|------|--------|------|
| 1 | 存档系统 | MVP | 基础设施，最先设计 |
| 2 | 输入系统 | MVP | 基础设施，最先设计 |
| 3 | 卡牌数据库 | MVP | 所有卡牌系统的基础 |
| 4 | 角色属性系统 | MVP | 伤害计算和成长的基础 |
| 5 | 伤害计算系统 | MVP | 卡牌战斗需要伤害计算 |
| 6 | 状态效果系统 | MVP | 增益减益类卡牌需要状态系统 |
| 7 | Combo连锁系统 | MVP | 30秒循环需要连锁机制 |
| 8 | 卡牌战斗系统 | MVP | 核心玩法，必须在MVP |
| 9 | 故事印记系统 | MVP | 选择如何影响卡牌的基础 |
| 10 | 选择系统 | MVP | 核心幻想，必须在MVP |
| 11 | UI系统 | MVP | 所有系统都需要UI |
| 12 | 音频系统 | MVP | 游戏需要音频反馈 |

### 垂直切片阶段（8个系统）

| 顺序 | 系统 | 里程碑 | 理由 |
|------|------|--------|------|
| 13 | 环境系统 | 垂直切片 | 环境阵地类卡牌需要环境 |
| 14 | 召唤物系统 | 垂直切片 | 召唤类卡牌需要召唤物 |
| 15 | 元素系统 | 垂直切片 | 选择系统需要元素切换 |
| 16 | 规则改写系统 | 垂直切片 | 选择系统需要规则改写 |
| 17 | 区域系统 | 垂直切片 | 垂直切片需要一个完整区域 |
| 18 | 世界状态系统 | 垂直切片 | 区域解锁需要状态管理 |
| 19 | 卡牌升级系统 | 垂直切片 | 成长感需要卡牌升级 |
| 20 | 卡组构筑系统 | 垂直切片 | 卡组管理需要构筑机制 |

### Alpha 阶段（5个系统）

| 顺序 | 系统 | 里程碑 | 理由 |
|------|------|--------|------|
| 21 | NPC系统 | Alpha | 叙事系统需要NPC |
| 22 | 对话系统 | Alpha | 叙事系统需要对话 |
| 23 | 剧情追踪系统 | Alpha | 三层剧情结构需要追踪 |
| 24 | 技能树系统 | Alpha | RPG成长需要技能树 |
| 25 | 世界探索系统 | Alpha | 多世界系统需要探索 |

### 完整版阶段（4个系统）

| 顺序 | 系统 | 里程碑 | 理由 |
|------|------|--------|------|
| 26 | 叙事系统 | 完整版 | 完整的故事体验 |
| 27 | RPG成长系统 | 完整版 | 完整的角色成长 |
| 28 | 卡组管理系统 | 完整版 | 完整的卡组管理 |
| 29 | 隐藏内容系统 | 完整版 | 彩蛋和隐藏内容 |

---

## 高风险系统

| 系统 | 风险 | 原因 | 缓解策略 |
|------|------|------|----------|
| **卡牌数据库** | 高 | 所有卡牌系统的基础 | 先设计核心卡牌，逐步扩展 |
| **选择系统** | 高 | 核心幻想的关键 | 从简单选择开始，逐步复杂化 |
| **卡牌战斗系统** | 高 | 核心玩法 | 先实现基础战斗，再添加高级机制 |
| **Combo连锁系统** | 中 | 30秒循环的关键 | 从简单连锁开始，逐步增加深度 |
| **故事印记系统** | 中 | 选择如何影响卡牌 | 先实现基础印记，再添加复杂效果 |

---

## 进度追踪

| 系统 | 状态 | GDD文件 | 备注 |
|------|------|---------|------|
| 存档系统 | Designed | design/gdd/save-system.md | ✅ 8/8 sections + 3 optional |
| 输入系统 | Designed | design/gdd/input-system.md | ✅ 8/8 sections + 5 optional |
| 卡牌数据库 | Designed | design/gdd/card-database.md | ✅ 8/8 sections + 4 optional |
| 角色属性系统 | Designed | design/gdd/character-attributes.md | ✅ 8/8 sections + 5 optional |
| 伤害计算系统 | Designed | design/gdd/damage-calculation.md | ✅ 8/8 sections + 3 optional |
| 状态效果系统 | Designed | design/gdd/status-effect-system.md | ✅ 8/8 sections + 3 optional |
| Combo连锁系统 | Designed | design/gdd/combo-chain-system.md | ✅ 8/8 sections + 3 optional |
| 环境系统 | Designed | design/gdd/environment-system.md | ✅ 8/8 sections + 3 optional |
| 召唤物系统 | Designed | design/gdd/summon-system.md | ✅ 8/8 sections + 3 optional |
| 故事印记系统 | Designed | design/gdd/story-mark-system.md | ✅ 8/8 sections + 3 optional |
| 元素系统 | Designed | design/gdd/element-system.md | ✅ 8/8 sections + 3 optional |
| 规则改写系统 | Designed | design/gdd/rule-rewriting-system.md | ✅ 8/8 sections + 3 optional |
| 对话系统 | Designed | design/gdd/dialogue-system.md | ✅ 8/8 sections + 3 optional |
| 技能树系统 | Designed | design/gdd/skill-tree-system.md | ✅ 8/8 sections + 3 optional |
| 音频系统 | Designed | design/gdd/audio-system.md | ✅ 8/8 sections + 3 optional |
| UI系统 | Designed | design/gdd/ui-system.md | ✅ 8/8 sections + 3 optional |
| 卡牌战斗系统 | Designed | design/gdd/card-battle-system.md | ✅ 8/8 sections + 3 optional |
| 选择系统 | Designed | design/gdd/choice-system.md | ✅ 8/8 sections + 3 optional |
| 世界状态系统 | Designed | design/gdd/world-state-system.md | ✅ 8/8 sections + 3 optional |
| 区域系统 | Designed | design/gdd/area-system.md | ✅ 8/8 sections + 3 optional |
| NPC系统 | Designed | design/gdd/npc-system.md | ✅ 8/8 sections + 3 optional |
| 剧情追踪系统 | Designed | design/gdd/story-tracking-system.md | ✅ 8/8 sections + 3 optional |
| 卡组构筑系统 | Designed | design/gdd/card-deck-building-system.md | ✅ 8/8 sections + 3 optional |
| 卡牌升级系统 | Designed | design/gdd/card-upgrade-system.md | ✅ 8/8 sections + 3 optional |
| 世界探索系统 | Designed | design/gdd/world-exploration-system.md | ✅ 8/8 sections + 3 optional |
| 卡组管理系统 | Designed | design/gdd/card-deck-management-system.md | ✅ 8/8 sections + 3 optional |
| 叙事系统 | Designed | design/gdd/narrative-system.md | ✅ 8/8 sections + 3 optional |
| RPG成长系统 | Designed | design/gdd/rpg-growth-system.md | ✅ 8/8 sections + 3 optional |
| 隐藏内容系统 | Designed | design/gdd/hidden-content-system.md | ✅ 8/8 sections + 3 optional |
