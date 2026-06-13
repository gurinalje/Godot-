# Control Manifest

> **Engine**: Godot 4.6.3  
> **Last Updated**: 2026-06-03  
> **Manifest Version**: 2026-06-03  
> **ADRs Covered**: ADR-0001, ADR-0002, ADR-0003, ADR-0004, ADR-0005, ADR-0006, ADR-0007, ADR-0008, ADR-0009, ADR-0010  
> **Status**: Active — regenerate with `/create-control-manifest update` when ADRs change

This manifest is a programmer's quick-reference extracted from all Accepted ADRs, technical preferences, and engine reference docs. For the reasoning behind each rule, see the referenced ADR.

---

## Foundation Layer Rules

*Applies to: scene management, event architecture, save/load, engine initialisation*

### Required Patterns
- **使用SceneManager (Autoload)管理场景切换** — source: ADR-0001
- **使用异步加载(ResourceLoader.load_threaded_request())避免卡顿** — source: ADR-0001
- **使用场景缓存池减少重复加载** — source: ADR-0001
- **使用JSON格式进行存档序列化** — source: ADR-0003
- **存档槽管理：Slot 0为自动保存，Slot 1-5为手动保存** — source: ADR-0003
- **使用Resource系统定义卡牌数据** — source: ADR-0004

### Forbidden Approaches
- **Never使用同步加载大场景** — 会导致主线程卡顿 — source: ADR-0001
- **Never使用二进制格式存档** — 人类不可读，调试困难 — source: ADR-0003

### Performance Guardrails
- **场景加载**: max 5秒/场景 — source: Technical Preferences
- **存档文件大小**: max 1MB/存档 — source: ADR-0003

---

## Core Layer Rules

*Applies to: core gameplay loop, main player systems, physics, collision*

### Required Patterns
- **使用全局EventBus (Autoload)进行跨层通信** — source: ADR-0002
- **使用直接信号进行同层/父子关系通信** — source: ADR-0002
- **使用有限状态机 (FSM)管理战斗流程** — source: ADR-0005
- **使用分层叠加规则管理状态效果** — source: ADR-0006
- **同类Buff最多叠加5层，同类Debuff刷新持续时间** — source: ADR-0006
- **使用基于Resource的对话树格式** — source: ADR-0007
- **使用分层状态管理世界状态** — source: ADR-0008
- **使用数值化态度系统管理NPC关系** — source: ADR-0009

### Forbidden Approaches
- **Never在EventBus中放置性能关键逻辑** — EventBus可能成为性能瓶颈 — source: ADR-0002
- **Never超过5层Buff叠加** — 会导致数值溢出 — source: ADR-0006
- **Never让NPC态度值超过-100~+100范围** — 会导致数值异常 — source: ADR-0009

### Performance Guardrails
- **EventBus事件处理**: max 1ms/事件 — source: ADR-0002
- **状态效果计算**: max 2ms/帧 — source: ADR-0006

---

## Feature Layer Rules

*Applies to: secondary mechanics, AI systems, secondary features*

### Required Patterns
- **卡牌能量消耗范围：0-10点** — source: ADR-0004
- **卡组大小限制：最小20张，最大40张** — source: ADR-0004
- **每张卡牌最多携带3张** — source: ADR-0004
- **世界状态使用Resource存储** — source: ADR-0008
- **区域解锁条件支持多种类型（进度/选择/印记/物品/隐藏）** — source: ADR-0008
- **NPC态度影响价格：-100~-50=+50%，-49~-1=+20%，0~49=0%，50~79=-20%，80~100=-50%** — source: ADR-0009

### Forbidden Approaches
- **Never硬编码卡牌数值** — 必须使用Resource — source: ADR-0004
- **Never跳过世界状态验证** — 必须验证状态合法性 — source: ADR-0008

### Performance Guardrails
- **卡牌数据加载**: max 10ms/卡牌 — source: ADR-0004

---

## Presentation Layer Rules

*Applies to: rendering, audio, UI, VFX, shaders, animations*

### Required Patterns
- **使用分层资源管理策略** — source: ADR-0010
- **核心资源启动时预加载，场景资源异步加载** — source: ADR-0010
- **使用LRU缓存管理流式资源** — source: ADR-0010
- **UI应支持鼠标和手柄导航** — source: Technical Preferences

### Forbidden Approaches
- **Never在主线程同步加载大资源** — 会导致卡顿 — source: ADR-0010

### Performance Guardrails
- **帧率**: 60 FPS — source: Technical Preferences
- **帧预算**: 16.6ms — source: Technical Preferences
- **Draw Call限制**: 1000 (2D) — source: Technical Preferences
- **内存预算**: 2GB (PC) — source: Technical Preferences

---

## Global Rules (All Layers)

### Naming Conventions
| 元素 | 约定 | 示例 |
|------|------|------|
| Classes | PascalCase | PlayerController |
| Variables/functions | snake_case | move_speed |
| Signals | snake_case past tense | health_changed |
| Files | snake_case matching class | player_controller.gd |
| Constants | UPPER_SNAKE_CASE | MAX_HEALTH |

### Performance Budgets
| 目标 | 值 |
|------|-----|
| 帧率 | 60 FPS |
| 帧预算 | 16.6ms |
| Draw Call限制 | 1000 (2D) |
| 内存预算 | 2GB (PC) |
| 场景加载时间 | < 5秒 |

### Approved Libraries / Addons
- **GUT (Godot Unit Testing)** — 用于单元测试
- **Godot Resource系统** — 用于数据存储
- **Godot Signal系统** — 用于事件通信

### Forbidden APIs (Godot 4.6.3)
These APIs are deprecated or unverified for Godot 4.6.3:
- 无已知弃用API（Godot 4.6.3是最新版本）

### Cross-Cutting Constraints
- **数据驱动设计** — 所有游戏值必须存储在外部资源中，永不硬编码 — source: Architecture Principles
- **信号优先通信** — 系统间通过信号松耦合通信，直接调用仅用于紧耦合系统 — source: ADR-0002
- **资源化状态** — 所有持久状态必须存储在Godot Resource中 — source: ADR-0004
- **层级分离** — 高层可依赖低层，低层不可依赖高层 — source: Architecture Principles
- **单一职责** — 每个系统只负责一个领域 — source: Architecture Principles
