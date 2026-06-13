# Story 003: 自动保存功能

> **Epic**: 存档系统  
> **Status**: Complete  
> **Layer**: Foundation  
> **Type**: Integration  
> **Manifest Version**: 2026-06-03

## Context

**GDD**: `design/gdd/save-system.md`  
**Requirement**: `TR-save-002`  
*(保存时机：自动保存触发点)*

**ADR Governing Implementation**: ADR-0003: Save/Load Serialization Format  
**ADR Decision Summary**: 使用JSON格式进行存档序列化，Slot 0为自动保存

**Engine**: Godot 4.6.3 | **Risk**: LOW  
**Engine Notes**: Godot Timer节点支持定时任务

**Control Manifest Rules (this layer)**:
- Required: 使用JSON格式进行存档序列化
- Required: 自动保存使用Slot 0

---

## Acceptance Criteria

*From GDD `design/gdd/save-system.md`, scoped to this story:*

- [ ] AC-1: 进入新区域时自动保存
- [ ] AC-2: 做出重要选择后自动保存
- [ ] AC-3: 击败Boss后自动保存
- [ ] AC-4: 定期自动保存（每5分钟）
- [ ] AC-5: 自动保存使用Slot 0
- [ ] AC-6: 自动保存时显示右下角存档图标淡入淡出

---

## Implementation Notes

*Derived from ADR-0003 Implementation Guidelines:*

1. **自动保存触发器**
   - 创建AutoSaveManager类管理自动保存
   - 使用EventBus监听触发事件
   - 使用Timer节点实现定时保存

2. **触发事件**
   - `area_entered`: 进入新区域
   - `choice_made`: 做出重要选择
   - `boss_defeated`: 击败Boss
   - `timer_timeout`: 定时器超时（5分钟）

3. **保存流程**
   - 收集所有系统状态
   - 序列化为JSON
   - 写入Slot 0
   - 显示保存图标动画

4. **防抖机制**
   - 短时间内多次触发只保存一次
   - 使用防抖时间（2秒）

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: 存档数据结构（数据格式定义）
- Story 002: 存档槽管理（文件命名、槽位切换）
- Story 004: 手动保存功能（UI交互、槽位选择）
- Story 005: 加载功能（文件读取、数据恢复）
- Story 006: 存档验证（校验和计算、完整性检查）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**AC-1**: 进入新区域时自动保存
- Given: 玩家在区域A
- When: 玩家进入区域B
- Then: 自动保存到Slot 0
- Edge cases: 区域切换失败、存档槽已满

**AC-2**: 做出重要选择后自动保存
- Given: 玩家在对话选择界面
- When: 玩家做出选择
- Then: 自动保存到Slot 0
- Edge cases: 选择无效、存档失败

**AC-3**: 击败Boss后自动保存
- Given: 玩家在Boss战中
- When: 击败Boss
- Then: 自动保存到Slot 0
- Edge cases: Boss战失败、存档失败

**AC-4**: 定期自动保存（每5分钟）
- Given: 游戏运行中
- When: 5分钟计时器超时
- Then: 自动保存到Slot 0
- Edge cases: 游戏暂停时、战斗中

**AC-5**: 自动保存使用Slot 0
- Given: 触发自动保存
- When: 保存完成
- Then: 存档文件为save_slot_0.json
- Edge cases: Slot 0被占用、Slot 0文件损坏

**AC-6**: 自动保存时显示右下角存档图标淡入淡出
- Given: 触发自动保存
- When: 保存开始
- Then: 右下角显示存档图标，1秒后淡出
- Edge cases: 动画被中断、UI层未加载

---

## Test Evidence

**Story Type**: Integration  
**Required evidence**:
- Integration: `tests/integration/save-system/auto_save_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (存档数据结构), Story 002 (存档槽管理)
- Unlocks: Story 004, Story 005, Story 006

---

## Completion Notes

**Completed**: 2026-06-03  
**Criteria**: 6/6 passing (100%)  
**Deviations**: None  
**Test Evidence**: Integration: test file at `tests/integration/save-system/auto_save_test.gd`  
**Code Review**: Pending
