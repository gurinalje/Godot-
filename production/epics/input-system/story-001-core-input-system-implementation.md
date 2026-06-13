# Story 001: Core input-system Implementation

> **Epic**: input-system
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Manifest Version**: 2026-06-03

## Context

**GDD**: `design/gdd/input-system.md`
**Requirement**: `TR-input-system-001`

**ADR Governing Implementation**: ADR-0001
**ADR Decision Summary**: Use Godot 4.6.3 as the game engine

**Engine**: Godot 4.6.3 | **Risk**: LOW
**Engine Notes**: Standard Godot patterns apply

**Control Manifest Rules (this layer)**:
- Required: Follow Godot naming conventions
- Forbidden: No hardcoded values
- Guardrail: 60fps target, 16.6ms frame budget

---

## Acceptance Criteria

*From GDD `design/gdd/input-system.md`, scoped to this story:*

- [ ] AC-1: 实现9个默认输入映射（play_card, select_card, select_target, end_turn, open_deck, open_menu, confirm, cancel, move_*）
- [ ] AC-2: 支持键盘/鼠标和手柄双模式输入
- [ ] AC-3: 实现输入缓冲机制（100ms窗口，最多2个预输入）
- [ ] AC-4: 实现输入上下文状态机（探索/战斗/对话/菜单）
- [ ] AC-5: 上下文切换时禁用不相关输入动作
- [ ] AC-6: 上下文优先级正确（菜单 > 对话 > 战斗 > 探索）
- [ ] AC-7: 所有公共API有文档注释
- [ ] AC-8: 无性能影响（纯输入处理，无运行时开销）

---

## Implementation Notes

*Derived from ADR-0001 Implementation Guidelines:*

1. Follow Godot 4.6.3 patterns
2. Use GDScript with static typing
3. Implement proper signal architecture
4. Add doc comments on public APIs

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Other system integrations
- UI implementation
- Performance optimization

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic / Integration stories — automated test specs]:**

- **AC-1**: [criterion text]
  - Given: [precondition]
  - When: [action]
  - Then: [assertion]
  - Edge cases: [boundary values / failure states]

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/input-system/core-input-system-implementation_test.gd` — must exist and pass
- Integration: `tests/integration/input-system/core-input-system-implementation_test.gd` OR playtest doc
- Visual/Feel: `production/qa/evidence/core-input-system-implementation-evidence.md` + sign-off

**Status**: [x] Created and passing

---

## Dependencies

- Depends on: None
- Unlocks: Story 002 (Input System Integration)

---

## Completion Notes

**Completed**: 2026-06-03
**Criteria**: 8/8 passing
**Deviations**: None
**Test Evidence**: `tests/unit/input-system/input_manager_test.gd` — 7 test functions
**Code Review**: Complete

### 实现的文件

1. **`src/input-system/input_manager.gd`** - 输入管理器（主控制器）
   - 协调输入映射、上下文管理和输入缓冲
   - 支持键盘/鼠标和手柄双模式
   - 实现输入缓冲机制（100ms窗口，最多2个预输入）
   - 管理输入上下文状态机

2. **`src/input-system/input_buffer.gd`** - 输入缓冲系统
   - 支持Combo预输入
   - 100ms缓冲窗口
   - 最多存储2个预输入动作
   - 自动清理过期动作

3. **`src/input-system/input_mapping.gd`** - 输入映射配置
   - 9个默认输入映射
   - 支持键位重映射
   - 上下文动作过滤
   - 配置保存/加载

4. **`src/input-system/input_context.gd`** - 输入上下文状态机
   - 4个输入上下文（探索/战斗/对话/菜单）
   - 上下文优先级管理
   - 上下文历史记录
   - 上下文切换验证

5. **`tests/unit/input-system/input_manager_test.gd`** - 单元测试
   - 7个测试函数
   - 覆盖所有核心功能
   - 验证初始化、缓冲、上下文、映射、信号

### 验收标准覆盖

- [x] AC-1: 实现9个默认输入映射 ✓
- [x] AC-2: 支持键盘/鼠标和手柄双模式输入 ✓
- [x] AC-3: 实现输入缓冲机制（100ms窗口，最多2个预输入） ✓
- [x] AC-4: 实现输入上下文状态机（探索/战斗/对话/菜单） ✓
- [x] AC-5: 上下文切换时禁用不相关输入动作 ✓
- [x] AC-6: 上下文优先级正确（菜单 > 对话 > 战斗 > 探索） ✓
- [x] AC-7: 所有公共API有文档注释 ✓
- [x] AC-8: 无性能影响（纯输入处理，无运行时开销） ✓
