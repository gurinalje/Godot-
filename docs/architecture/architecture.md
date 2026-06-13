# 命运卡牌局 — Master Architecture

## Document Status
- **Version**: 1.0
- **Last Updated**: 2026-06-03
- **Engine**: Godot 4.6.3
- **Language**: GDScript (primary) + C# (performance-critical)
- **GDDs Covered**: 29 system GDDs
- **ADRs Referenced**: None yet

---

## Engine Knowledge Gap Summary

**Engine**: Godot 4.6.3
**LLM Training Covers**: up to approximately Godot 4.3
**Risk Level**: MEDIUM

### HIGH RISK Domains
- **Rendering**: New 2D rendering features in 4.6.x
- **UI System**: Updated UI system in 4.6.x

### MEDIUM RISK Domains
- **GDScript**: Improved type system in 4.6.x
- **C# Integration**: Enhanced .NET 8+ integration

### LOW RISK Domains
- **Core**: Scene system, node hierarchy, signals — stable
- **Input**: InputMap, InputEvent — stable
- **Audio**: AudioStreamPlayer — stable
- **Resource**: Resource system — stable

---

## System Layer Map

```
┌─────────────────────────────────────────────────────────────┐
│  PRESENTATION LAYER (表现层)                                │
│  ├─ 世界探索系统 (#25)                                      │
│  ├─ 卡组管理系统 (#26)                                      │
│  ├─ 叙事系统 (#27)                                          │
│  └─ RPG成长系统 (#28)                                       │
├─────────────────────────────────────────────────────────────┤
│  FEATURE LAYER (功能层)                                     │
│  ├─ 卡牌战斗系统 (#17)                                      │
│  ├─ 选择系统 (#18)                                          │
│  ├─ 世界状态系统 (#19)                                      │
│  ├─ 区域系统 (#20)                                          │
│  ├─ NPC系统 (#21)                                           │
│  ├─ 剧情追踪系统 (#22)                                      │
│  ├─ 卡组构筑系统 (#23)                                      │
│  └─ 卡牌升级系统 (#24)                                      │
├─────────────────────────────────────────────────────────────┤
│  CORE LAYER (核心层)                                        │
│  ├─ 伤害计算系统 (#5)                                       │
│  ├─ 状态效果系统 (#6)                                       │
│  ├─ Combo连锁系统 (#7)                                      │
│  ├─ 环境系统 (#8)                                           │
│  ├─ 召唤物系统 (#9)                                         │
│  ├─ 故事印记系统 (#10)                                      │
│  ├─ 元素系统 (#11)                                          │
│  ├─ 规则改写系统 (#12)                                      │
│  ├─ 对话系统 (#13)                                          │
│  ├─ 技能树系统 (#14)                                        │
│  ├─ 音频系统 (#15)                                          │
│  └─ UI系统 (#16)                                            │
├─────────────────────────────────────────────────────────────┤
│  FOUNDATION LAYER (基础层)                                  │
│  ├─ 存档系统 (#1)                                           │
│  ├─ 输入系统 (#2)                                           │
│  ├─ 卡牌数据库 (#3)                                         │
│  └─ 角色属性系统 (#4)                                       │
├─────────────────────────────────────────────────────────────┤
│  PLATFORM LAYER (平台层)                                    │
│  └─ Godot Engine 4.6.3                                      │
└─────────────────────────────────────────────────────────────┘
```

---

## Module Ownership

### Foundation Layer (基础层)

| Module | Owns | Exposes | Consumes | Engine APIs |
|--------|------|---------|----------|-------------|
| 存档系统 | Save data, slot management | save(), load(), get_slots() | All systems | FileAccess, JSON |
| 输入系统 | Input mappings, buffer | get_action(), is_action_pressed() | All systems | InputMap, InputEvent |
| 卡牌数据库 | Card definitions | get_card(), get_cards_by_type() | None | Resource |
| 角色属性系统 | Player stats | get_stat(), add_stat() | None | Resource |

### Core Layer (核心层)

| Module | Owns | Exposes | Consumes | Engine APIs |
|--------|------|---------|----------|-------------|
| 伤害计算 | Damage formulas | calculate_damage() | 角色属性, 卡牌数据库 | None |
| 状态效果 | Buff/Debuff state | apply_effect(), get_effects() | 卡牌数据库 | Timer |
| Combo连锁 | Combo state | check_combo(), get_combo_count() | 卡牌数据库 | None |
| 环境 | Environment state | get_environment(), set_environment() | None | Node2D |
| 召唤物 | Summon units | summon(), get_summons() | 伤害计算, 状态效果 | CharacterBody2D |
| 故事印记 | Story marks | add_mark(), get_marks() | None | Resource |
| 元素 | Element state | get_element(), switch_element() | 卡牌数据库 | None |
| 规则改写 | Rule overrides | rewrite_rule(), get_rules() | None | Resource |
| 对话 | Dialogue trees | get_dialogue(), advance() | None | Resource |
| 技能树 | Skill tree | unlock_skill(), get_skills() | 角色属性 | Resource |
| 音频 | Audio playback | play_sfx(), play_bgm() | None | AudioStreamPlayer |
| UI | UI state | show_ui(), hide_ui() | All systems | Control, CanvasLayer |

### Feature Layer (功能层)

| Module | Owns | Exposes | Consumes | Engine APIs |
|--------|------|---------|----------|-------------|
| 卡牌战斗 | Battle state | start_battle(), play_card(), end_turn() | 伤害计算, 状态效果, Combo, 环境, 召唤物 | Node2D |
| 选择 | Choice state | make_choice(), get_history() | 故事印记, 元素, 规则改写 | None |
| 世界状态 | World progress | get_world_state(), unlock_world() | 选择 | Resource |
| 区域 | Area data | get_area(), enter_area() | 世界状态 | Node2D |
| NPC | NPC state | interact(), get_attitude() | 对话, 故事印记 | CharacterBody2D |
| 剧情追踪 | Story progress | get_story(), update_progress() | 选择, NPC | Resource |
| 卡组构筑 | Deck rules | build_deck(), validate_deck() | 卡牌数据库 | None |
| 卡牌升级 | Card levels | upgrade_card(), get_level() | 卡牌数据库, 角色属性 | None |

### Presentation Layer (表现层)

| Module | Owns | Exposes | Consumes | Engine APIs |
|--------|------|---------|----------|-------------|
| 世界探索 | Exploration state | explore(), get_map() | 区域, 世界状态 | Node2D |
| 卡组管理 | Collection UI | show_collection(), filter_cards() | 卡组构筑, 卡牌升级 | Control |
| 叙事 | Narrative UI | show_story(), advance_story() | 剧情追踪, NPC, 对话 | Control |
| RPG成长 | Growth UI | show_growth(), allocate_stats() | 角色属性, 技能树 | Control |

---

## Data Flow

### 1. 战斗流程 (Battle Flow)

```
玩家输入 → 输入系统 → 卡牌战斗系统
                         ↓
                    卡牌数据库 (获取卡牌数据)
                         ↓
                    伤害计算系统 (计算伤害)
                         ↓
                    状态效果系统 (应用Buff/Debuff)
                         ↓
                    Combo连锁系统 (检测连锁)
                         ↓
                    环境系统 (应用环境效果)
                         ↓
                    召唤物系统 (管理召唤物)
                         ↓
                    UI系统 (更新界面)
                         ↓
                    音频系统 (播放音效)
```

### 2. 选择流程 (Choice Flow)

```
对话/剧情 → 选择系统
               ↓
          故事印记系统 (添加印记)
               ↓
          元素系统 (解锁元素)
               ↓
          规则改写系统 (改写规则)
               ↓
          世界状态系统 (更新世界状态)
               ↓
          剧情追踪系统 (更新剧情进度)
```

### 3. 存档/读档流程 (Save/Load Flow)

```
存档请求 → 存档系统
               ↓
          收集所有系统状态
          ├─ 角色属性
          ├─ 卡牌数据库
          ├─ 世界状态
          ├─ 剧情进度
          ├─ NPC状态
          ├─ 故事印记
          └─ 卡组配置
               ↓
          序列化为JSON
               ↓
          写入文件 (FileAccess)
```

### 4. 初始化顺序 (Initialization Order)

```
1. Platform Layer (Godot Engine)
2. Foundation Layer
   ├─ 存档系统
   ├─ 输入系统
   ├─ 卡牌数据库
   └─ 角色属性系统
3. Core Layer
   ├─ 音频系统
   ├─ UI系统
   ├─ 伤害计算系统
   ├─ 状态效果系统
   ├─ Combo连锁系统
   ├─ 环境系统
   ├─ 召唤物系统
   ├─ 故事印记系统
   ├─ 元素系统
   ├─ 规则改写系统
   ├─ 对话系统
   └─ 技能树系统
4. Feature Layer (loaded on demand)
5. Presentation Layer (loaded on demand)
```

---

## API Boundaries

### Foundation Layer APIs

```gdscript
# 存档系统
class_name SaveSystem
func save_game(slot: int) -> bool
func load_game(slot: int) -> bool
func get_save_slots() -> Array[SaveSlot]
func delete_save(slot: int) -> bool

# 输入系统
class_name InputSystem
func get_action_strength(action: String) -> float
func is_action_just_pressed(action: String) -> bool
func get_input_buffer() -> InputBuffer

# 卡牌数据库
class_name CardDatabase
func get_card(card_id: String) -> CardData
func get_cards_by_type(type: CardType) -> Array[CardData]
func get_cards_by_element(element: ElementType) -> Array[CardData]

# 角色属性系统
class_name CharacterAttributes
func get_stat(stat_name: String) -> int
func set_stat(stat_name: String, value: int) -> void
func add_stat(stat_name: String, amount: int) -> void
```

### Core Layer APIs

```gdscript
# 伤害计算系统
class_name DamageCalculator
func calculate_damage(attacker: CharacterAttributes, defender: CharacterAttributes, card: CardData) -> DamageResult
func apply_element_modifier(base_damage: int, attacker_element: ElementType, defender_element: ElementType) -> int

# 状态效果系统
class_name StatusEffectSystem
func apply_effect(target: Node, effect: StatusEffect) -> void
func remove_effect(target: Node, effect_id: String) -> void
func get_active_effects(target: Node) -> Array[StatusEffect]

# Combo连锁系统
class_name ComboChainSystem
func check_combo(cards_played: Array[CardData]) -> ComboResult
func get_combo_count() -> int
func reset_combo() -> void

# 环境系统
class_name EnvironmentSystem
func get_current_environment() -> EnvironmentData
func set_environment(env_id: String) -> void
func get_environment_bonus() -> EnvironmentBonus

# 召唤物系统
class_name SummonSystem
func summon(card: CardData, position: Vector2) -> SummonUnit
func get_summons() -> Array[SummonUnit]
func remove_summon(unit: SummonUnit) -> void

# 故事印记系统
class_name StoryMarkSystem
func add_mark(mark_type: MarkType, value: int) -> void
func get_marks() -> Array[StoryMark]
func has_mark(mark_type: MarkType) -> bool

# 元素系统
class_name ElementSystem
func get_current_element() -> ElementType
func switch_element(element: ElementType) -> void
func get_element_modifier(attacker: ElementType, defender: ElementType) -> float

# 规则改写系统
class_name RuleRewritingSystem
func rewrite_rule(rule_id: String, new_value: Variant) -> void
func get_active_rules() -> Array[RuleOverride]
func reset_rules() -> void

# 对话系统
class_name DialogueSystem
func start_dialogue(dialogue_id: String) -> void
func advance_dialogue(choice_index: int) -> void
func get_current_node() -> DialogueNode

# 技能树系统
class_name SkillTreeSystem
func unlock_skill(skill_id: String) -> bool
func get_unlocked_skills() -> Array[SkillData]
func get_skill_tree() -> SkillTree

# 音频系统
class_name AudioSystem
func play_sfx(sfx_id: String) -> void
func play_bgm(bgm_id: String) -> void
func stop_bgm() -> void
func set_volume(bus: String, volume: float) -> void

# UI系统
class_name UISystem
func show_ui(ui_name: String) -> void
func hide_ui(ui_name: String) -> void
func show_notification(message: String) -> void
```

### Feature Layer APIs

```gdscript
# 卡牌战斗系统
class_name CardBattleSystem
func start_battle(enemy_id: String) -> void
func play_card(card: CardData, target: Node = null) -> void
func end_turn() -> void
func get_battle_state() -> BattleState

# 选择系统
class_name ChoiceSystem
func make_choice(choice_id: String, option_index: int) -> void
func get_choice_history() -> Array[ChoiceRecord]
func get_available_choices() -> Array[Choice]

# 世界状态系统
class_name WorldStateSystem
func get_world_state(world_id: String) -> WorldState
func unlock_world(world_id: String) -> void
func is_world_unlocked(world_id: String) -> bool

# 区域系统
class_name AreaSystem
func get_area(area_id: String) -> AreaData
func enter_area(area_id: String) -> void
func get_current_area() -> AreaData

# NPC系统
class_name NPCSystem
func interact(npc_id: String) -> void
func get_npc_attitude(npc_id: String) -> int
func update_attitude(npc_id: String, change: int) -> void

# 剧情追踪系统
class_name StoryTrackingSystem
func get_story_progress(story_id: String) -> StoryProgress
func update_progress(story_id: String, progress: int) -> void
func get_active_stories() -> Array[StoryData]

# 卡组构筑系统
class_name DeckBuildingSystem
func build_deck(cards: Array[CardData]) -> Deck
func validate_deck(deck: Deck) -> bool
func get_deck_rules() -> DeckRules

# 卡牌升级系统
class_name CardUpgradeSystem
func upgrade_card(card_id: String) -> bool
func get_upgrade_cost(card_id: String) -> UpgradeCost
func get_card_level(card_id: String) -> int
```

---

## ADR Audit

**Current ADRs**: None yet

**Required ADRs** (must create before coding):

### Foundation Layer
1. **Scene Management Strategy** — How scenes are loaded/unloaded
2. **Event Bus Architecture** — Signal vs direct call strategy
3. **Save/Load Serialization Format** — JSON structure for save data
4. **Resource Management** — How .tres resources are organized

### Core Layer
5. **Card Data Structure** — CardData Resource format
6. **Battle State Machine** — Battle flow state machine
7. **Status Effect Stack Rules** — How effects stack/override
8. **Dialogue Tree Format** — DialogueNode structure

### Feature Layer
9. **World State Persistence** — How world progress is saved
10. **NPC Attitude System** — How NPC attitudes are tracked

---

## Architecture Principles

1. **Data-Driven Design**: All game values (card stats, formulas, configurations) are stored in external resources (.tres), never hardcoded.

2. **Signal-Based Communication**: Systems communicate via Godot signals to maintain loose coupling. Direct method calls only for tightly coupled systems.

3. **Resource-Based State**: All persistent state is stored in Godot Resources, making serialization straightforward.

4. **Layer Separation**: Higher layers can depend on lower layers, but lower layers cannot depend on higher layers.

5. **Single Responsibility**: Each system owns one specific domain and exposes a clean API boundary.

---

## Open Questions

| # | 问题 | 优先级 | 负责人 | 目标解决日期 |
|---|------|--------|--------|--------------|
| OQ-1 | 是否使用Autoload单例或依赖注入？ | 高 | 架构师 | MVP前 |
| OQ-2 | 信号总线是全局还是局部？ | 高 | 架构师 | MVP前 |
| OQ-3 | C#用于哪些性能关键系统？ | 中 | 架构师 | 垂直切片前 |
| OQ-4 | 如何处理跨语言边界（GDScript/C#）？ | 中 | 架构师 | 垂直切片前 |
| OQ-5 | 资源加载策略是什么（预加载/懒加载）？ | 中 | 架构师 | 垂直切片前 |
