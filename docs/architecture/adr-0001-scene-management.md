# ADR-0001: Scene Management Strategy

> **Status**: Accepted  
> **Date**: 2026-06-03  
> **Deciders**: Technical Director, Lead Programmer

---

## Context

《命运卡牌局》是一个包含多个世界、区域和战斗场景的2D RPG卡牌游戏。游戏需要在不同场景之间高效切换，同时保持状态一致性。

**Key Requirements**:
- 支持多个世界和区域的场景切换
- 战斗场景需要快速加载
- 场景切换时需要保持游戏状态
- 支持异步加载避免卡顿

---

## Decision

采用**基于SceneTree的场景管理策略**，使用Godot的`SceneTree.change_scene_to_file()`进行场景切换，配合`ResourceLoader.load_threaded_request()`进行异步预加载。

### 核心组件

1. **SceneManager (Autoload)** — 全局场景管理器
2. **SceneCache** — 场景缓存池
3. **LoadingScreen** — 加载界面

### 场景分类

| 场景类型 | 加载策略 | 缓存策略 |
|----------|----------|----------|
| 主菜单 | 启动时加载 | 常驻内存 |
| 世界地图 | 异步加载 | 缓存1个 |
| 区域地图 | 异步加载 | 缓存当前世界 |
| 战斗场景 | 预加载 | 缓存常用 |
| UI场景 | 预加载 | 常驻内存 |

---

## Consequences

### 正面影响
- ✅ 场景切换流畅，用户体验好
- ✅ 异步加载避免主线程卡顿
- ✅ 缓存机制减少重复加载
- ✅ 符合Godot最佳实践

### 负面影响
- ⚠️ 内存占用增加（缓存场景）
- ⚠️ 需要管理缓存生命周期
- ⚠️ 异步加载增加代码复杂度

### 风险缓解
- 设置缓存大小限制
- 实现LRU缓存淘汰策略
- 提供同步加载的fallback

---

## ADR Dependencies

- 无（基础ADR）

---

## Engine Compatibility

| 特性 | Godot 4.6.3 | 风险 |
|------|-------------|------|
| SceneTree.change_scene_to_file() | ✅ 稳定 | 低 |
| ResourceLoader.load_threaded_request() | ✅ 稳定 | 低 |
| PackedScene | ✅ 稳定 | 低 |

---

## GDD Requirements Addressed

| Requirement ID | GDD | System |
|----------------|-----|--------|
| TR-save-001 | 存档系统 | 场景切换时保存状态 |
| TR-world-001 | 世界探索系统 | 多世界场景切换 |
| TR-battle-001 | 卡牌战斗系统 | 战斗场景快速加载 |

---

## Implementation Notes

```gdscript
# scene_manager.gd (Autoload)
extends Node

var _cache: Dictionary = {}
var _loading_screen: PackedScene = preload("res://ui/loading_screen.tscn")

func change_scene(scene_path: String, use_cache: bool = true) -> void:
    if use_cache and _cache.has(scene_path):
        _change_to_cached(scene_path)
    else:
        _load_async(scene_path)

func _load_async(scene_path: String) -> void:
    ResourceLoader.load_threaded_request(scene_path)
    # Show loading screen
    # Poll ResourceLoader.load_threaded_status()
    # On completion: change_scene_to_file()

func _change_to_cached(scene_path: String) -> void:
    get_tree().change_scene_to_packed(_cache[scene_path])
```
