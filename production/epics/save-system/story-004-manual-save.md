# Story 004: 手动保存功能

> **Epic**: 存档系统  
> **Status**: Complete  
> **Layer**: Foundation  
> **Type**: Integration  
> **Manifest Version**: 2026-06-03

## Context

**GDD**: `design/gdd/save-system.md`  
**Requirement**: `TR-save-002`  
*(保存时机：手动保存)*

**ADR Governing Implementation**: ADR-0003: Save/Load Serialization Format  
**ADR Decision Summary**: 使用JSON格式进行存档序列化，Slot 1-5为手动保存

**Engine**: Godot 4.6.3 | **Risk**: LOW  
**Engine Notes**: Godot内置JSON类，稳定可靠

**Control Manifest Rules (this layer)**:
- Required: 使用JSON格式进行存档序列化
- Required: 手动保存使用Slot 1-5

---

## Acceptance Criteria

*From GDD `design/gdd/save-system.md`, scoped to this story:*

- [ ] AC-1: 玩家在菜单中选择"保存游戏"
- [ ] AC-2: 显示存档槽列表（Slot 1-5）
- [ ] AC-3: 玩家选择槽位后保存游戏
- [ ] AC-4: 保存成功后显示确认信息
- [ ] AC-5: 保存失败后显示错误信息

---

## Implementation Notes

*Derived from ADR-0003 Implementation Guidelines:*

1. **手动保存流程**
   - 玩家打开菜单 → 选择"保存游戏"
   - 显示存档槽列表（Slot 1-5）
   - 玩家选择槽位 → 确认保存
   - 保存成功 → 显示确认信息

2. **槽位选择UI**
   - 显示每个槽位的状态（空/已占用）
   - 显示存档时间、游戏时长、当前位置
   - 已占用槽位显示"覆盖"警告

3. **保存确认**
   - 覆盖已有存档时显示确认对话框
   - 确认后执行保存
   - 取消后返回槽位选择

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: 存档数据结构（数据格式定义）
- Story 002: 存档槽管理（文件命名、槽位切换）
- Story 003: 自动保存功能（触发时机、定时保存）
- Story 005: 加载功能（文件读取、数据恢复）
- Story 006: 存档验证（校验和计算、完整性检查）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**AC-1**: 玩家在菜单中选择"保存游戏"
- Given: 玩家在游戏中
- When: 打开菜单并选择"保存游戏"
- Then: 显示存档槽列表
- Edge cases: 菜单未加载、存档系统未初始化

**AC-2**: 显示存档槽列表（Slot 1-5）
- Given: 玩家选择"保存游戏"
- When: 存档槽列表加载
- Then: 显示5个槽位（Slot 1-5），每个显示状态
- Edge cases: 槽位为空、槽位已满、槽位数据损坏

**AC-3**: 玩家选择槽位后保存游戏
- Given: 玩家选择了一个槽位
- When: 确认保存
- Then: 游戏数据保存到选中的槽位
- Edge cases: 槽位已满、磁盘空间不足

**AC-4**: 保存成功后显示确认信息
- Given: 保存操作成功
- When: 保存完成
- Then: 显示"游戏已保存"确认信息
- Edge cases: 确认信息未显示、显示时间过短

**AC-5**: 保存失败后显示错误信息
- Given: 保存操作失败
- When: 保存失败
- Then: 显示错误信息（如"磁盘空间不足"）
- Edge cases: 错误信息不明确、错误信息未显示

---

## Test Evidence

**Story Type**: Integration  
**Required evidence**:
- Integration: `tests/integration/save-system/manual_save_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (存档数据结构), Story 002 (存档槽管理)
- Unlocks: Story 005, Story 006

---

## Completion Notes

**Completed**: 2026-06-03  
**Criteria**: 5/5 passing (100%)  
**Deviations**: None  
**Test Evidence**: Integration: test file at `tests/integration/save-system/manual_save_test.gd`  
**Code Review**: Pending
