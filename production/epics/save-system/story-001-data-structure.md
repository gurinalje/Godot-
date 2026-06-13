# Story 001: 存档数据结构

> **Epic**: 存档系统  
> **Status**: Complete  
> **Layer**: Foundation  
> **Type**: Logic  
> **Estimate**: 2小时  
> **Performance**: 无性能影响（纯数据结构，无运行时开销）  
> **Manifest Version**: 2026-06-03

## Context

**GDD**: `design/gdd/save-system.md`  
**Requirement**: `TR-save-001`  
*(存档数据结构：嵌套字典JSON格式)*

**ADR Governing Implementation**: ADR-0003: Save/Load Serialization Format  
**ADR Decision Summary**: 使用JSON格式进行存档序列化，存档结构包含version、timestamp、player、cards、worlds、stories、marks等字段

**Engine**: Godot 4.6.3 | **Risk**: LOW  
**Engine Notes**: Godot内置JSON类，稳定可靠

**Control Manifest Rules (this layer)**:
- Required: 使用JSON格式进行存档序列化
- Forbidden: Never使用二进制格式存档

---

## Acceptance Criteria

*From GDD `design/gdd/save-system.md`, scoped to this story:*

- [ ] AC-1: 存档数据包含version字段（字符串格式）
- [ ] AC-2: 存档数据包含timestamp字段（ISO 8601格式）
- [ ] AC-3: 存档数据包含player字段（包含level、experience、attributes、gold）
- [ ] AC-4: 存档数据包含cards字段（包含collection、deck、levels）
- [ ] AC-5: 存档数据包含worlds字段（每个世界包含unlocked、completed状态）
- [ ] AC-6: 存档数据包含stories字段（每个剧情包含progress、choices）
- [ ] AC-7: 存档数据包含marks字段（善良、邪恶、中立印记数量）

---

## Implementation Notes

*Derived from ADR-0003 Implementation Guidelines:*

1. **数据结构定义**
   - 创建SaveData类（继承Resource）定义存档数据结构
   - 使用@export导出所有字段，支持编辑器调试
   - 字段类型必须明确（int、float、String、Dictionary、Array）

2. **序列化方法**
   - `serialize() -> Dictionary`: 将SaveData转换为Dictionary
   - `deserialize(data: Dictionary) -> SaveData`: 将Dictionary转换为SaveData
   - 使用JSON.stringify()和JSON.parse()进行序列化

3. **版本兼容**
   - 存档包含version字段，用于未来版本迁移
   - 加载时检查version，如果不兼容尝试迁移

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: 存档槽管理（文件命名、槽位切换）
- Story 003: 自动保存功能（触发时机、定时保存）
- Story 004: 手动保存功能（UI交互、槽位选择）
- Story 005: 加载功能（文件读取、数据恢复）
- Story 006: 存档验证（校验和计算、完整性检查）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**AC-1**: 存档数据包含version字段
- Given: 创建新的SaveData实例
- When: 调用serialize()方法
- Then: 返回的Dictionary包含"version"键，值为字符串
- Edge cases: version为空字符串、version格式错误

**AC-2**: 存档数据包含timestamp字段
- Given: 创建新的SaveData实例
- When: 调用serialize()方法
- Then: 返回的Dictionary包含"timestamp"键，值为ISO 8601格式字符串
- Edge cases: timestamp为过去时间、timestamp为未来时间

**AC-3**: 存档数据包含player字段
- Given: 创建包含玩家数据的SaveData实例
- When: 调用serialize()方法
- Then: 返回的Dictionary包含"player"键，包含level、experience、attributes、gold
- Edge cases: 玩家属性为0、玩家属性为最大值

**AC-4**: 存档数据包含cards字段
- Given: 创建包含卡牌数据的SaveData实例
- When: 调用serialize()方法
- Then: 返回的Dictionary包含"cards"键，包含collection、deck、levels
- Edge cases: 卡牌收藏为空、卡牌收藏已满

**AC-5**: 存档数据包含worlds字段
- Given: 创建包含世界状态的SaveData实例
- When: 调用serialize()方法
- Then: 返回的Dictionary包含"worlds"键，每个世界包含unlocked、completed
- Edge cases: 所有世界未解锁、所有世界已完成

**AC-6**: 存档数据包含stories字段
- Given: 创建包含剧情进度的SaveData实例
- When: 调用serialize()方法
- Then: 返回的Dictionary包含"stories"键，每个剧情包含progress、choices
- Edge cases: 剧情未开始、剧情已完成

**AC-7**: 存档数据包含marks字段
- Given: 创建包含印记数据的SaveData实例
- When: 调用serialize()方法
- Then: 返回的Dictionary包含"marks"键，包含good、evil、neutral
- Edge cases: 所有印记为0、印记达到上限

---

## Test Evidence

**Story Type**: Logic  
**Required evidence**:
- Logic: `tests/unit/save-system/data_structure_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None (第一个故事)
- Unlocks: Story 002, Story 003, Story 004, Story 005, Story 006

---

## Completion Notes

**Completed**: 2026-06-03  
**Criteria**: 7/7 passing (100%)  
**Deviations**: None  
**Test Evidence**: Logic: test file at `tests/unit/save-system/data_structure_test.gd`  
**Code Review**: Complete (APPROVED)
