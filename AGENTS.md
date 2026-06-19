# 命运卡牌局 (Destiny Card Game)

OpenCode驱动的独立游戏开发框架，通过49个协调的OpenCode代理管理。

## 项目概述

**游戏类型**: 2D卡牌RPG，融合《杀戮尖塔》、《游戏王》和《炉石传说》的机制

**技术栈**:
- **引擎**: Godot 4.6.3（注意：LLM训练数据仅覆盖到4.3版本，需要查阅引擎文档）
- **语言**: GDScript（主要）、C#（性能关键系统）、C++ via GDExtension（仅原生）
- **构建系统**: .NET SDK + Godot导出模板
- **资产管道**: Godot导入系统 + 自定义资源管道

**项目阶段**: Production（生产阶段状态文件：`production/stage.txt`）

### 当前状态
- **史诗任务**: 22个（全部待开始）
- **故事任务**: 69个（全部待开始）
- **源代码系统**: 22个（已创建）
- **测试文件**: 67个（已创建，177个测试函数）

### 当前优先级
1. **运行测试验证**: 在Godot中运行所有测试
2. **代码审查**: 运行 `/code-review` 审查实现
3. **集成测试**: 运行 `/smoke-check` 验证系统集成
4. **QA计划**: 运行 `/qa-plan` 创建测试计划
5. **冲刺计划**: 运行 `/sprint-plan` 创建生产冲刺计划

## 项目结构

```text
/
├── AGENTS.md                    # 本文件 - 项目配置和代理指南
├── opencode.json                # OpenCode配置（权限、插件、MCP服务器）
├── project.godot                # Godot项目文件（主场景：res://src/main.tscn）
├── .opencode/                   # 框架组件
│   ├── commands/                # 50个斜杠命令（路由到技能）
│   ├── agents/                  # 51个代理定义
│   ├── skills/                  # 77个技能
│   ├── plugins/                 # TypeScript插件（生命周期钩子、验证、日志）
│   └── rules/                   # 11个路径作用域的编码标准
├── src/                         # 游戏源代码
│   ├── autoload/                # 自动加载单例（GameManager, ResourceManager）
│   ├── card-database/           # 卡牌数据库系统
│   ├── damage-calculation/      # 伤害计算系统
│   ├── status-effect-system/    # 状态效果系统
│   └── ...                      # 25+游戏系统
├── tests/                       # 测试目录
│   ├── unit/                    # 单元测试（按系统组织）
│   ├── integration/             # 集成测试
│   └── workflow/                 # 工作流测试
├── design/                      # 游戏设计文档
│   └── gdd/                     # 30个游戏设计文档
├── docs/                        # 文档
│   ├── architecture/            # 架构决策记录（ADR）
│   └── engine-reference/        # 引擎API快照（版本固定）
├── production/                  # 生产文档
│   ├── epics/                   # 史诗和故事文件
│   └── session-state/           # 会话状态
├── assets/                      # 游戏资产
├── tools/                       # 开发工具
└── scripts/                     # 自动化脚本
```

## 核心游戏系统（已实现）

项目包含25+游戏系统，分为四个层次：

1. **基础层**: 卡牌数据库、伤害计算、状态效果、战斗日志
2. **核心层**: 玩家系统、敌人AI、战斗系统、回合管理
3. **功能层**: 商店系统、背包系统、任务系统、成就系统
4. **表现层**: UI系统、动画系统、音效系统、粒子系统

## OpenCode框架使用

### 关键命令

```bash
# 项目设置
/start                          # 引导式入门流程
/setup-engine godot 4.6         # 配置引擎版本
/project-stage-detect           # 分析现有项目

# 设计阶段
/brainstorm                     # 探索游戏创意
/map-systems                    # 分解游戏系统
/design-system                  # 设计单个系统

# 开发阶段
/create-architecture            # 创建架构文档
/create-epics                   # 创建史诗
/create-stories                 # 创建故事
/dev-story                      # 实现故事

# 测试阶段
/test-setup                     # 设置测试框架
/smoke-check                    # 关键路径测试
/qa-plan                        # 创建QA计划

# 生产阶段
/sprint-plan                    # 创建冲刺计划
/sprint-status                  # 检查冲刺状态
/release-checklist              # 发布检查清单
```

### 代理使用指南

**代理层次结构**:
- **Tier 1 - 总监**: creative-director, technical-director, producer
- **Tier 2 - 部门主管**: game-designer, lead-programmer, art-director等
- **Tier 3 - 专家**: gameplay-programmer, engine-programmer等

**关键规则**:
1. **垂直委派**: 总监委派给部门主管，主管委派给专家
2. **水平协商**: 同级代理可以协商，但不能在域外做约束性决定
3. **冲突解决**: 设计冲突升级到creative-director，技术冲突升级到technical-director
4. **变更传播**: 跨域变更由producer协调

### 协作协议

**用户驱动协作，非自主执行**:
1. 每个任务遵循：**问题 → 选项 → 决策 → 草案 → 批准**
2. 代理必须在写入文件前询问："我可以将此写入[文件路径]吗？"
3. 多文件更改需要明确批准完整变更集
4. 没有用户指令不提交代码

## Godot 4.6.3 开发指南

### 关键注意事项

1. **引擎版本**: Godot 4.6.3，LLM训练数据仅覆盖到4.3版本
   - 必须查阅`docs/engine-reference/godot/`中的API文档
   - 使用`skill(name="setup-engine")`获取版本特定指导

2. **自动加载系统**: 
   - `GameManager`: 中央系统管理器，初始化25+游戏系统
   - `ResourceManager`: 资源管理单例
   - 在`project.godot`中配置

3. **测试框架**:
   - 使用GUT（Godot Unit Testing）框架
   - 配置文件：`.gutconfig.json`
   - 测试目录：`tests/unit/`和`tests/integration/`
   - 运行测试：`tests/workflow/run-all.mjs`

4. **场景管理**:
   - 主场景：`res://src/main.tscn`
   - 使用MCP Godot工具进行场景操作
   - 场景文件格式：`.tscn`（文本格式）

### MCP工具使用

项目配置了两个MCP服务器：

1. **Aseprite MCP** (`aseprite-mcp`):
   - 用于创建和编辑2D艺术资产
   - 支持精灵、动画、调色板管理
   - 用法：`skill(name="art-generate")`生成占位符艺术

2. **Godot MCP** (`godot`):
   - 用于场景管理和项目操作
   - 支持节点添加、场景保存、项目运行
   - 用法：直接调用godot_*工具函数

### 常见陷阱

1. **不要硬编码游戏值**: 所有游戏值必须数据驱动（外部配置）
2. **不要跳过测试**: 每个游戏系统都需要对应的单元测试
3. **不要忽略文档**: 每个系统都需要架构决策记录（ADR）
4. **不要跨域修改**: 代理不能修改其指定目录外的文件
5. **不要自主提交**: 必须等待用户指令才能提交代码

## 编码标准

### 通用要求

- 所有游戏代码必须包含公共API的文档注释
- 每个系统必须在`docs/architecture/`中有对应的架构决策记录
- 游戏值必须数据驱动（外部配置），永不硬编码
- 所有公共方法必须可单元测试（依赖注入优于单例）
- 提交必须引用相关设计文档或任务ID

### 验证驱动开发

- 添加游戏系统时首先编写测试
- UI更改通过截图验证
- 在标记工作完成前比较预期输出与实际输出
- 每个实现都应该有方法证明其工作正常

### GDScript特定标准

- 使用静态类型（`var health: int = 100`）
- 遵循Godot命名约定（PascalCase类名，snake_case变量）
- 使用信号进行系统间通信
- 避免在热路径中使用`get_node()`，缓存节点引用

## 上下文管理

上下文是OpenCode会话中最关键的资源。主动管理。

**文件是记忆，不是对话**：对话是临时的，会被压缩或丢失。磁盘上的文件在压缩和会话崩溃时持久存在。

维护`production/session-state/active.md`作为实时检查点，在每个重要里程碑后更新：
- 设计部分批准并写入文件
- 架构决策制定
- 实现里程碑达成
- 测试结果获得

状态文件应包含：当前任务、进度检查清单、关键决策、正在处理的文件和开放问题。

## 工作流程模式

### 混合工作流（推荐用于独立团队）

- **发现阶段**: 快速原型设计以找到乐趣。低流程开销，最少代理，`prototypes/`中的可丢弃代码。
- **生产阶段**: 设计验证后使用完整OCGS纪律。正式GDD、ADR、测试和质量门。
- **适用**: 1-5人团队，未知设计，迭代寻找乐趣。
- **详情**: `docs/hybrid-workflow.md`

### 完整OCGS工作流

- **所有阶段正式**: 每个功能都经过设计→架构→故事→代码→测试→审查。
- **适用**: 5-15人团队，已知设计，长时间线，发布商要求。
- **详情**: `docs/`和`.opencode/skills/`

## 质量门

在合并到`development`之前，CI必须通过：

1. **代理验证**: 所有代理文件具有必需的前置内容和部分
2. **技能验证**: 所有技能文件具有指向现有代理的有效交叉引用
3. **插件测试**: `node .opencode/plugins/tests/test-*.mjs`
4. **游戏测试**: `node tests/workflow/run-all.mjs`

## 快速参考

### 常用文件位置

- **游戏设计文档**: `design/gdd/`
- **架构决策记录**: `docs/architecture/`
- **测试文件**: `tests/unit/[系统名]/`
- **生产文档**: `production/epics/`
- **会话状态**: `production/session-state/active.md`

### 常用技能

- **设计**: `brainstorm`, `design-system`, `map-systems`
- **架构**: `create-architecture`, `architecture-decision`
- **实现**: `dev-story`, `create-stories`
- **测试**: `test-setup`, `smoke-check`, `qa-plan`
- **生产**: `sprint-plan`, `sprint-status`, `release-checklist`

### 常用代理

- **设计**: game-designer, systems-designer, economy-designer
- **编程**: gameplay-programmer, ui-programmer, ai-programmer
- **艺术**: art-director, technical-artist, sound-designer
- **质量**: qa-lead, qa-tester, performance-analyst

## 注意事项

这是从[Claude Code Game Studios](https://github.com/Donchitos/Claude-Code-Game-Studios)
到OpenCode的移植。77个技能在`.opencode/skills/`中，51个代理在
`.opencode/agents/`中，12个原始bash钩子在TypeScript插件中实现。

要贡献框架本身——添加代理、技能、命令、规则或插件——请参阅`docs/CONTRIBUTING.md`。

要了解游戏特定信息，请参阅：
- `README.md`: 项目概述和已实现系统
- `docs/architecture/architecture.md`: 主架构文档
- `design/gdd/`: 游戏设计文档集合