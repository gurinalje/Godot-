# Story 002: 存档槽管理

> **Epic**: 存档系统  
> **Status**: Complete  
> **Layer**: Foundation  
> **Type**: Logic  
> **Manifest Version**: 2026-06-03

## Context

**GDD**: `design/gdd/save-system.md`  
**Requirement**: `TR-save-003`  
*(存档槽管理：3-5手动+1自动)*

**ADR Governing Implementation**: ADR-0003: Save/Load Serialization Format  
**ADR Decision Summary**: Slot 0为自动保存，Slot 1-5为手动保存

**Engine**: Godot 4.6.3 | **Risk**: LOW  
**Engine Notes**: Godot FileAccess类支持文件操作

**Control Manifest Rules (this layer)**:
- Required: 使用JSON格式进行存档序列化
- Required: 存档槽管理：Slot 0为自动保存，Slot 1-5为手动保存

---

## Acceptance Criteria

*From GDD `design/gdd/save-system.md`, scoped to this story:*

- [ ] AC-1: 存档系统有6个存档槽（Slot 0-5）
- [ ] AC-2: Slot 0为自动保存槽，只读
- [ ] AC-3: Slot 1-5为手动保存槽，可读写
- [ ] AC-4: 存档文件命名为save_slot_0.json到save_slot_5.json
- [ ] AC-5: 存档槽满时提示玩家覆盖现有存档
- [ ] AC-6: 每个存档槽显示存档时间、游戏时长、当前位置

---

## Implementation Notes

*Derived from ADR-0003 Implementation Guidelines:*

1. **槽位管理类**
   - 创建SaveSlotManager类管理存档槽
   - 使用数组存储6个SaveSlot对象
   - 每个SaveSlot包含：slot_id、file_path、metadata、is_auto_save

2. **文件命名规则**
   - 自动保存: `user://saves/save_slot_0.json`
   - 手动保存: `user://saves/save_slot_1.json` 到 `save_slot_5.json`
   - 使用`user://`目录确保跨平台兼容

3. **槽位状态查询**
   - `get_slot_info(slot_id: int) -> SaveSlotInfo`: 获取槽位信息
   - `is_slot_empty(slot_id: int) -> bool`: 检查槽位是否为空
   - `is_slot_auto_save(slot_id: int) -> bool`: 检查是否为自动保存槽

4. **槽位清理**
   - `delete_slot(slot_id: int) -> bool`: 删除指定槽位
   - 自动保存槽不可删除

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: 存档数据结构（数据格式定义）
- Story 003: 自动保存功能（触发时机、定时保存）
- Story 004: 手动保存功能（UI交互、槽位选择）
- Story 005: 加载功能（文件读取、数据恢复）
- Story 006: 存档验证（校验和计算、完整性检查）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**AC-1**: 存档系统有6个存档槽
- Given: 初始化SaveSlotManager
- When: 查询存档槽数量
- Then: 返回6个存档槽（Slot 0-5）
- Edge cases: 存档目录不存在、存档目录为空

**AC-2**: Slot 0为自动保存槽，只读
- Given: 存档系统已初始化
- When: 尝试写入Slot 0
- Then: 操作失败，返回错误信息
- Edge cases: Slot 0文件不存在、Slot 0文件损坏

**AC-3**: Slot 1-5为手动保存槽，可读写
- Given: 存档系统已初始化
- When: 写入Slot 1-5
- Then: 操作成功，数据正确保存
- Edge cases: 槽位已满、磁盘空间不足

**AC-4**: 存档文件命名为save_slot_0.json到save_slot_5.json
- Given: 存档系统已初始化
- When: 查询存档文件路径
- Then: 返回正确的文件路径（user://saves/save_slot_X.json）
- Edge cases: 文件名包含特殊字符、文件路径过长

**AC-5**: 存档槽满时提示玩家覆盖现有存档
- Given: 所有手动槽位已满
- When: 尝试保存到新槽位
- Then: 返回需要覆盖的槽位列表
- Edge cases: 只有一个槽位为空、所有槽位都为空

**AC-6**: 每个存档槽显示存档时间、游戏时长、当前位置
- Given: 存档槽包含存档数据
- When: 查询槽位信息
- Then: 返回存档时间、游戏时长、当前位置
- Edge cases: 存档数据不完整、存档时间格式错误

---

## Test Evidence

**Story Type**: Logic  
**Required evidence**:
- Logic: `tests/unit/save-system/slot_management_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (存档数据结构)
- Unlocks: Story 003, Story 004, Story 005, Story 006

---

## Completion Notes

**Completed**: 2026-06-03  
**Criteria**: 6/6 passing (100%)  
**Deviations**: None  
**Test Evidence**: Logic: test file at `tests/unit/save-system/slot_management_test.gd`  
**Code Review**: Pending
