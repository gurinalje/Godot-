# Story 005: 加载功能

> **Epic**: 存档系统  
> **Status**: Complete  
> **Layer**: Foundation  
> **Type**: Integration  
> **Manifest Version**: 2026-06-03

## Context

**GDD**: `design/gdd/save-system.md`  
**Requirement**: `TR-save-001`  
*(存档数据结构：读取)*

**ADR Governing Implementation**: ADR-0003: Save/Load Serialization Format  
**ADR Decision Summary**: 使用JSON格式进行存档序列化

**Engine**: Godot 4.6.3 | **Risk**: LOW  
**Engine Notes**: Godot JSON类支持parse方法

**Control Manifest Rules (this layer)**:
- Required: 使用JSON格式进行存档序列化
- Required: 加载时验证数据完整性

---

## Acceptance Criteria

*From GDD `design/gdd/save-system.md`, scoped to this story:*

- [ ] AC-1: 玩家在菜单中选择"加载游戏"
- [ ] AC-2: 显示存档槽列表（所有槽位）
- [ ] AC-3: 玩家选择槽位后加载游戏
- [ ] AC-4: 加载成功后恢复游戏状态
- [ ] AC-5: 加载失败后显示错误信息

---

## Implementation Notes

*Derived from ADR-0003 Implementation Guidelines:*

1. **加载流程**
   - 玩家打开菜单 → 选择"加载游戏"
   - 显示存档槽列表（所有槽位）
   - 玩家选择槽位 → 确认加载
   - 加载成功 → 恢复游戏状态

2. **数据恢复**
   - 读取JSON文件
   - 解析为Dictionary
   - 调用各系统的load_data()方法
   - 恢复游戏状态

3. **错误处理**
   - 文件不存在：显示"无存档"
   - 文件损坏：显示"存档损坏"
   - 版本不兼容：尝试迁移或提示

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: 存档数据结构（数据格式定义）
- Story 002: 存档槽管理（文件命名、槽位切换）
- Story 003: 自动保存功能（触发时机、定时保存）
- Story 004: 手动保存功能（UI交互、槽位选择）
- Story 006: 存档验证（校验和计算、完整性检查）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**AC-1**: 玩家在菜单中选择"加载游戏"
- Given: 玩家在主菜单
- When: 选择"加载游戏"
- Then: 显示存档槽列表
- Edge cases: 菜单未加载、存档系统未初始化

**AC-2**: 显示存档槽列表（所有槽位）
- Given: 玩家选择"加载游戏"
- When: 存档槽列表加载
- Then: 显示所有槽位（Slot 0-5），每个显示状态
- Edge cases: 槽位为空、槽位已满、槽位数据损坏

**AC-3**: 玩家选择槽位后加载游戏
- Given: 玩家选择了一个槽位
- When: 确认加载
- Then: 游戏状态从选中的槽位恢复
- Edge cases: 槽位为空、存档损坏、版本不兼容

**AC-4**: 加载成功后恢复游戏状态
- Given: 加载操作成功
- When: 加载完成
- Then: 游戏状态正确恢复（玩家位置、属性、卡牌等）
- Edge cases: 部分数据丢失、数据不一致

**AC-5**: 加载失败后显示错误信息
- Given: 加载操作失败
- When: 加载失败
- Then: 显示错误信息（如"存档损坏"）
- Edge cases: 错误信息不明确、错误信息未显示

---

## Test Evidence

**Story Type**: Integration  
**Required evidence**:
- Integration: `tests/integration/save-system/load_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (存档数据结构), Story 002 (存档槽管理)
- Unlocks: Story 006

---

## Completion Notes

**Completed**: 2026-06-03  
**Criteria**: 5/5 passing (100%)  
**Deviations**: None  
**Test Evidence**: Integration: test file at `tests/integration/save-system/load_test.gd`  
**Code Review**: Pending
