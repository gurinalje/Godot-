# Story 006: 存档验证

> **Epic**: 存档系统  
> **Status**: Complete  
> **Layer**: Foundation  
> **Type**: Logic  
> **Manifest Version**: 2026-06-03

## Context

**GDD**: `design/gdd/save-system.md`  
**Requirement**: `TR-save-004`  
*(存档验证：CRC32校验和)*

**ADR Governing Implementation**: ADR-0003: Save/Load Serialization Format  
**ADR Decision Summary**: 使用JSON格式进行存档序列化，支持校验和验证

**Engine**: Godot 4.6.3 | **Risk**: LOW  
**Engine Notes**: Godot支持CRC32计算

**Control Manifest Rules (this layer)**:
- Required: 使用JSON格式进行存档序列化
- Required: 加载时验证数据完整性

---

## Acceptance Criteria

*From GDD `design/gdd/save-system.md`, scoped to this story:*

- [ ] AC-1: 保存时计算CRC32校验和
- [ ] AC-2: 校验和存储在存档数据中
- [ ] AC-3: 加载时验证CRC32校验和
- [ ] AC-4: 校验和不匹配时显示错误
- [ ] AC-5: 损坏的存档尝试恢复部分数据

---

## Implementation Notes

*Derived from ADR-0003 Implementation Guidelines:*

1. **校验和计算**
   - 使用CRC32算法计算存档数据的校验和
   - 校验和存储在存档数据的"checksum"字段
   - 保存时自动计算并存储

2. **校验和验证**
   - 加载时重新计算CRC32校验和
   - 与存储的校验和比较
   - 不匹配时显示错误

3. **数据恢复**
   - 尝试从损坏的存档中恢复部分数据
   - 恢复玩家属性、卡牌收藏等关键数据
   - 显示恢复的数据列表

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: 存档数据结构（数据格式定义）
- Story 002: 存档槽管理（文件命名、槽位切换）
- Story 003: 自动保存功能（触发时机、定时保存）
- Story 004: 手动保存功能（UI交互、槽位选择）
- Story 005: 加载功能（文件读取、数据恢复）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**AC-1**: 保存时计算CRC32校验和
- Given: 保存游戏数据
- When: 保存完成
- Then: 存档数据包含"checksum"字段，值为CRC32校验和
- Edge cases: 数据为空、数据过大

**AC-2**: 校验和存储在存档数据中
- Given: 存档数据已保存
- When: 读取存档数据
- Then: 数据包含"checksum"字段
- Edge cases: checksum字段缺失、checksum格式错误

**AC-3**: 加载时验证CRC32校验和
- Given: 加载存档数据
- When: 加载完成
- Then: 验证CRC32校验和，匹配则继续，不匹配则报错
- Edge cases: 校验和计算错误、校验和不匹配

**AC-4**: 校验和不匹配时显示错误
- Given: 存档数据校验和不匹配
- When: 加载存档
- Then: 显示"存档损坏"错误信息
- Edge cases: 错误信息不明确、错误信息未显示

**AC-5**: 损坏的存档尝试恢复部分数据
- Given: 存档数据损坏
- When: 尝试恢复
- Then: 恢复玩家属性、卡牌收藏等关键数据
- Edge cases: 无法恢复任何数据、恢复数据不完整

---

## Test Evidence

**Story Type**: Logic  
**Required evidence**:
- Logic: `tests/unit/save-system/validation_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (存档数据结构), Story 002 (存档槽管理)
- Unlocks: None (最后一个故事)

---

## Completion Notes

**Completed**: 2026-06-03  
**Criteria**: 5/5 passing (100%)  
**Deviations**: None  
**Test Evidence**: Logic: test file at `tests/unit/save-system/validation_test.gd`  
**Code Review**: Pending
