# 命运卡牌局

一款2D卡牌RPG游戏，融合了杀戮尖塔、游戏王和炉石传说的机制。

## 游戏特色

- **卡牌战斗系统**：4种卡牌类型（召唤、直接伤害、环境阵地、增益减益）
- **元素系统**：火、水、风、土、雷5种元素，循环克制
- **选择系统**：玩家选择影响剧情和游戏规则
- **RPG成长**：角色升级、技能树、属性分配
- **多区域探索**：森林、城堡、废墟、虚空4个区域
- **隐藏内容**：彩蛋、隐藏任务、隐藏区域

## 技术栈

- **引擎**: Godot 4.6.3
- **语言**: GDScript
- **构建系统**: Godot Export Templates
- **资源管道**: Godot Import System

## 项目结构

```
├── src/                    # 源代码
│   ├── autoload/           # 自动加载脚本
│   ├── core/               # 核心系统
│   ├── scenes/             # 游戏场景
│   ├── card-database/      # 卡牌数据库
│   ├── character-attributes/ # 角色属性
│   ├── damage-calculation/ # 伤害计算
│   ├── status-effect-system/ # 状态效果
│   ├── combo-chain-system/ # Combo连锁
│   ├── element-system/     # 元素系统
│   ├── summon-system/      # 召唤物系统
│   ├── environment-system/ # 环境系统
│   ├── choice-system/      # 选择系统
│   ├── world-state-system/ # 世界状态
│   ├── npc-system/         # NPC系统
│   ├── story-mark-system/  # 故事印记
│   ├── rule-rewriting-system/ # 规则改写
│   ├── dialogue-system/    # 对话系统
│   ├── skill-tree-system/  # 技能树
│   ├── deck-building-system/ # 卡组构筑
│   ├── card-upgrade-system/ # 卡牌升级
│   ├── world-exploration-system/ # 世界探索
│   ├── deck-management-system/ # 卡组管理
│   ├── narrative-system/   # 叙事系统
│   ├── rpg-growth-system/  # RPG成长
│   ├── hidden-content-system/ # 隐藏内容
│   ├── audio-system/       # 音频系统
│   └── ui-system/          # UI系统
├── assets/                 # 游戏资源
│   ├── sprites/            # 图片资源
│   │   ├── vampire/        # 吸血鬼角色资源
│   │   ├── characters/     # 角色资源
│   │   ├── cards/          # 卡牌资源
│   │   ├── ui/             # UI资源
│   │   └── effects/        # 特效资源
│   ├── audio/              # 音频资源
│   └── data/               # 数据文件
│       └── cards/          # 卡牌数据
├── tools/                  # 开发工具
│   ├── aseprite-mcp/       # Aseprite集成
│   └── generate/           # 资源生成脚本
├── design/                 # 设计文档
│   ├── gdd/                # 游戏设计文档
│   └── art/                # 美术规范
├── docs/                   # 技术文档
│   ├── architecture/       # 架构文档
│   └── engine-reference/   # 引擎参考
├── tests/                  # 测试代码
├── production/             # 生产管理
├── prototypes/             # 原型开发
└── scripts/                # 自动化脚本
```

## 已实现系统

### 核心层 (12个系统)
- ✅ 存档系统
- ✅ 输入系统
- ✅ 卡牌数据库
- ✅ 角色属性系统
- ✅ 伤害计算系统
- ✅ 状态效果系统
- ✅ Combo连锁系统
- ✅ 环境系统
- ✅ 召唤物系统
- ✅ 故事印记系统
- ✅ 元素系统
- ✅ 规则改写系统

### 功能层 (6个系统)
- ✅ 卡牌战斗系统
- ✅ 选择系统
- ✅ 世界状态系统
- ✅ NPC系统
- ✅ 剧情追踪系统
- ✅ 卡组构筑系统
- ✅ 卡牌升级系统

### 表现层 (4个系统)
- ✅ 世界探索系统
- ✅ 卡组管理系统
- ✅ 叙事系统
- ✅ RPG成长系统

### 打磨层 (1个系统)
- ✅ 隐藏内容系统

## 游戏场景

- **主菜单**：新游戏、继续游戏、设置、退出
- **世界探索**：玩家移动、NPC交互、区域切换
- **卡牌战斗**：抽牌、出牌、伤害计算、回合制战斗

## 资源统计

| 类型 | 数量 | 状态 |
|------|------|------|
| 卡牌图片 | 12 | ✅ 已生成 |
| 角色立绘 | 11 | ✅ 已生成 |
| UI元素 | 18 | ✅ 已生成 |
| 音效 | 19 | ✅ 已生成 |
| 背景音乐 | 0 | ⏳ 待生成 |

## 运行项目

1. 安装 Godot 4.6.3
2. 打开项目文件夹
3. 运行 `project.godot`

## 开发计划

### 第一阶段：核心玩法 ✅
- [x] 卡牌战斗系统
- [x] 元素克制系统
- [x] 基础UI

### 第二阶段：内容扩展 ⏳
- [ ] 更多卡牌
- [ ] 更多敌人
- [ ] 更多区域

### 第三阶段：打磨优化 ⏳
- [ ] 音效音乐
- [ ] 视觉特效
- [ ] 平衡调整

## 许可证

MIT License
