# ADR-0010: Resource Management

> **Status**: Accepted  
> **Date**: 2026-06-03  
> **Deciders**: Technical Director, Lead Programmer

---

## Context

《命运卡牌局》有大量资源（卡牌数据、对话、音效、图片等），需要统一管理。

**Key Requirements**:
- 支持预加载和懒加载
- 支持资源缓存
- 支持资源版本管理
- 支持热重载

---

## Decision

使用**分层资源管理策略**：

### 资源分类

| 资源类型 | 加载策略 | 缓存策略 | 示例 |
|----------|----------|----------|------|
| **核心资源** | 启动时预加载 | 常驻内存 | 卡牌数据库、UI主题 |
| **场景资源** | 异步加载 | 缓存当前场景 | 区域地图、战斗场景 |
| **按需资源** | 懒加载 | 不缓存 | 特定卡牌、对话 |
| **流式资源** | 流式加载 | LRU缓存 | 音乐、大图 |

### 资源管理器

```gdscript
# resource_manager.gd (Autoload)
extends Node

var _cache: Dictionary = {}
var _loading: Dictionary = {}

enum CacheStrategy {
    NONE,       # 不缓存
    SCENE,      # 场景级缓存
    GLOBAL,     # 全局缓存
    LRU         # LRU缓存
}

func load_resource(path: String, strategy: CacheStrategy = CacheStrategy.NONE) -> Resource:
    # 检查缓存
    if _cache.has(path):
        return _cache[path]
    
    # 检查是否正在加载
    if _loading.has(path):
        return null  # 等待加载完成
    
    # 加载资源
    var resource = load(path)
    
    # 缓存策略
    match strategy:
        CacheStrategy.GLOBAL:
            _cache[path] = resource
        CacheStrategy.SCENE:
            _cache[path] = resource
            # 场景切换时清除
        CacheStrategy.LRU:
            _add_to_lru(path, resource)
    
    return resource

func load_resource_async(path: String, callback: Callable) -> void:
    ResourceLoader.load_threaded_request(path)
    _loading[path] = callback
    # 在_process中轮询加载状态
```

### 资源目录结构

```
res://
├─ data/
│  ├─ cards/           # 卡牌数据 (.tres)
│  ├─ dialogues/       # 对话数据 (.tres)
│  ├─ stories/         # 剧情数据 (.tres)
│  └─ balance/         # 平衡数据 (.tres)
├─ assets/
│  ├─ sprites/         # 精灵图 (.png)
│  ├─ audio/           # 音频 (.ogg, .wav)
│  ├─ fonts/           # 字体 (.ttf)
│  └─ themes/          # UI主题 (.tres)
├─ scenes/
│  ├─ battle/          # 战斗场景 (.tscn)
│  ├─ world/           # 世界场景 (.tscn)
│  └─ ui/              # UI场景 (.tscn)
└─ scripts/
   ├─ autoload/        # 自动加载脚本
   ├─ systems/         # 系统脚本
   └─ entities/        # 实体脚本
```

---

## Consequences

### 正面影响
- ✅ 资源管理清晰
- ✅ 加载性能优化
- ✅ 内存使用可控
- ✅ 支持热重载

### 负面影响
- ⚠️ 管理复杂度高
- ⚠️ 需要管理缓存生命周期
- ⚠️ 异步加载增加代码复杂度

### 风险缓解
- 提供资源管理调试工具
- 实现资源使用统计
- 限制缓存大小

---

## ADR Dependencies

- ADR-0001 (Scene Management) — 场景资源加载
- ADR-0003 (Save/Load Serialization) — 存档资源

---

## Engine Compatibility

| 特性 | Godot 4.6.3 | 风险 |
|------|-------------|------|
| ResourceLoader | ✅ 稳定 | 低 |
| preload() | ✅ 稳定 | 低 |
| load() | ✅ 稳定 | 低 |
| ResourceLoader.load_threaded_request() | ✅ 稳定 | 低 |

---

## GDD Requirements Addressed

| Requirement ID | GDD | System |
|----------------|-----|--------|
| TR-resource-001 | 通用 | 资源加载策略 |
| TR-resource-002 | 通用 | 资源缓存管理 |
| TR-resource-003 | 通用 | 异步加载支持 |

---

## Implementation Notes

```gdscript
# resource_manager.gd (Autoload)
extends Node

var _cache: Dictionary = {}
var _lru_cache: LRUCache = LRUCache.new(100)  # 最多100个资源
var _loading: Dictionary = {}

func _process(_delta: float) -> void:
    _poll_loading()

func load_resource(path: String, strategy: CacheStrategy = CacheStrategy.NONE) -> Resource:
    # 检查缓存
    if _cache.has(path):
        return _cache[path]
    
    if _lru_cache.has(path):
        return _lru_cache.get(path)
    
    # 同步加载
    var resource = load(path)
    _apply_cache_strategy(path, resource, strategy)
    return resource

func load_resource_async(path: String, callback: Callable, strategy: CacheStrategy = CacheStrategy.NONE) -> void:
    if _cache.has(path):
        callback.call(_cache[path])
        return
    
    ResourceLoader.load_threaded_request(path)
    _loading[path] = {"callback": callback, "strategy": strategy}

func _poll_loading() -> void:
    for path in _loading.keys():
        var status = ResourceLoader.load_threaded_status(path)
        match status:
            ResourceLoader.THREAD_LOAD_LOADED:
                var resource = ResourceLoader.load_threaded_get(path)
                var data = _loading.erase(path)
                _apply_cache_strategy(path, resource, data.strategy)
                data.callback.call(resource)
            ResourceLoader.THREAD_LOAD_FAILED:
                _loading.erase(path)
                push_error("Failed to load resource: " + path)

func _apply_cache_strategy(path: String, resource: Resource, strategy: CacheStrategy) -> void:
    match strategy:
        CacheStrategy.GLOBAL:
            _cache[path] = resource
        CacheStrategy.SCENE:
            _cache[path] = resource
        CacheStrategy.LRU:
            _lru_cache.put(path, resource)

func clear_scene_cache() -> void:
    # 场景切换时调用
    var keys_to_remove = []
    for key in _cache:
        if not _is_global_resource(key):
            keys_to_remove.append(key)
    for key in keys_to_remove:
        _cache.erase(key)

func _is_global_resource(path: String) -> bool:
    # 判断是否是全局资源
    return path.begins_with("res://data/") or path.begins_with("res://assets/themes/")
```
