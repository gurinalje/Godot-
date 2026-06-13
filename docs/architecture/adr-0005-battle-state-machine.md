# ADR-0005: Battle State Machine

> **Status**: Accepted  
> **Date**: 2026-06-03  
> **Deciders**: Technical Director, Lead Programmer

---

## Context

《命运卡牌局》的战斗系统需要管理复杂的战斗流程，包括回合制、卡牌打出、效果处理等。

**Key Requirements**:
- 支持回合制战斗
- 支持卡牌打出和效果处理
- 支持Combo连锁检测
- 支持SL回档（保存/加载）

---

## Decision

使用**有限状态机 (FSM)** 管理战斗流程，每个状态有明确的进入/退出条件。

### 战斗状态机

```
┌─────────────────────────────────────────────────────────────┐
│  BATTLE_INIT                                                │
│  ├─ 初始化双方属性                                          │
│  ├─ 抽初始手牌                                              │
│  └─ 转换到 → PLAYER_TURN                                    │
├─────────────────────────────────────────────────────────────┤
│  PLAYER_TURN                                                │
│  ├─ 恢复能量                                                │
│  ├─ 抽牌                                                    │
│  └─ 转换到 → PLAYER_ACTION                                  │
├─────────────────────────────────────────────────────────────┤
│  PLAYER_ACTION                                              │
│  ├─ 等待玩家操作                                            │
│  ├─ 打出卡牌 → CARD_PLAYED                                  │
│  ├─ 结束回合 → ENEMY_TURN                                   │
│  └─ SL回档 → SAVE_STATE                                     │
├─────────────────────────────────────────────────────────────┤
│  CARD_PLAYED                                                │
│  ├─ 执行卡牌效果                                            │
│  ├─ 检测Combo → COMBO_CHECK                                 │
│  ├─ 应用状态效果                                            │
│  └─ 转换到 → PLAYER_ACTION                                  │
├─────────────────────────────────────────────────────────────┤
│  COMBO_CHECK                                                │
│  ├─ 检测连锁条件                                            │
│  ├─ 触发连锁效果                                            │
│  └─ 转换到 → PLAYER_ACTION                                  │
├─────────────────────────────────────────────────────────────┤
│  ENEMY_TURN                                                 │
│  ├─ AI决策                                                  │
│  ├─ 执行敌方行动                                            │
│  └─ 转换到 → TURN_END                                       │
├─────────────────────────────────────────────────────────────┤
│  TURN_END                                                   │
│  ├─ 处理持续效果                                            │
│  ├─ 检查胜负条件                                            │
│  ├─ 胜利 → BATTLE_WIN                                       │
│  ├─ 失败 → BATTLE_LOSE                                      │
│  └─ 继续 → PLAYER_TURN                                      │
├─────────────────────────────────────────────────────────────┤
│  BATTLE_WIN / BATTLE_LOSE                                   │
│  ├─ 显示结算界面                                            │
│  ├─ 发放奖励                                                │
│  └─ 转换到 → BATTLE_END                                     │
└─────────────────────────────────────────────────────────────┘
```

### 状态转换表

| 当前状态 | 触发条件 | 目标状态 |
|----------|----------|----------|
| BATTLE_INIT | 初始化完成 | PLAYER_TURN |
| PLAYER_TURN | 回合开始 | PLAYER_ACTION |
| PLAYER_ACTION | 打出卡牌 | CARD_PLAYED |
| PLAYER_ACTION | 结束回合 | ENEMY_TURN |
| CARD_PLAYED | 效果执行完成 | COMBO_CHECK |
| COMBO_CHECK | 连锁检测完成 | PLAYER_ACTION |
| ENEMY_TURN | AI行动完成 | TURN_END |
| TURN_END | 胜利 | BATTLE_WIN |
| TURN_END | 失败 | BATTLE_LOSE |
| TURN_END | 继续 | PLAYER_TURN |

---

## Consequences

### 正面影响
- ✅ 战斗流程清晰可控
- ✅ 易于调试和测试
- ✅ 支持复杂战斗机制
- ✅ 易于扩展新状态

### 负面影响
- ⚠️ 状态数量可能膨胀
- ⚠️ 需要管理状态转换条件
- ⚠️ 异步操作增加复杂度

### 风险缓解
- 限制状态数量
- 使用状态转换表
- 提供状态调试工具

---

## ADR Dependencies

- ADR-0002 (Event Bus) — 战斗事件广播

---

## Engine Compatibility

| 特性 | Godot 4.6.3 | 风险 |
|------|-------------|------|
| State Machine Pattern | ✅ 自定义实现 | 低 |
| Signal | ✅ 稳定 | 低 |
| Timer | ✅ 稳定 | 低 |

---

## GDD Requirements Addressed

| Requirement ID | GDD | System |
|----------------|-----|--------|
| TR-battle-001 | 卡牌战斗系统 | 战斗流程管理 |
| TR-battle-002 | 卡牌战斗系统 | 回合制实现 |
| TR-battle-003 | 卡牌战斗系统 | SL回档支持 |

---

## Implementation Notes

```gdscript
# battle_state_machine.gd
class_name BattleStateMachine
extends Node

signal state_changed(old_state: BattleState, new_state: BattleState)

enum BattleState {
    BATTLE_INIT,
    PLAYER_TURN,
    PLAYER_ACTION,
    CARD_PLAYED,
    COMBO_CHECK,
    ENEMY_TURN,
    TURN_END,
    BATTLE_WIN,
    BATTLE_LOSE,
    BATTLE_END
}

var current_state: BattleState = BattleState.BATTLE_INIT
var battle_context: BattleContext

func change_state(new_state: BattleState) -> void:
    var old_state = current_state
    _exit_state(old_state)
    current_state = new_state
    _enter_state(new_state)
    state_changed.emit(old_state, new_state)

func _exit_state(state: BattleState) -> void:
    match state:
        BattleState.PLAYER_TURN:
            _on_player_turn_exit()
        BattleState.ENEMY_TURN:
            _on_enemy_turn_exit()

func _enter_state(state: BattleState) -> void:
    match state:
        BattleState.BATTLE_INIT:
            _on_battle_init_enter()
        BattleState.PLAYER_TURN:
            _on_player_turn_enter()
        BattleState.ENEMY_TURN:
            _on_enemy_turn_enter()
```
