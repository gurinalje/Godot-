## 资源管理器
## 统一加载和管理游戏中的所有资源

extends Node

# 单例实例
static var instance: Node

# 资源缓存
var _cache: Dictionary = {}

# 资源索引
var _index: Dictionary = {}

# 加载状态
var _loading_progress: float = 0.0
var _is_loading: bool = false

# 信号
signal resource_loaded(key: String)
signal all_resources_loaded()
signal loading_progress_changed(progress: float)

func _init() -> void:
	instance = self

func _ready() -> void:
	_load_index()

## 加载资源索引
func _load_index() -> void:
	var index_path = "res://assets/index.tres"
	if ResourceLoader.exists(index_path):
		var index_resource = load(index_path)
		if index_resource:
			_index = {
				"cards": index_resource.cards,
				"characters": index_resource.characters,
				"ui": index_resource.ui,
				"environments": index_resource.environments,
				"effects": index_resource.effects,
				"audio": index_resource.audio
			}
			print("[ResourceManager] Index loaded: ", _index.size(), " categories")

## 获取资源
func get_resource(key: String, category: String = "") -> Resource:
	# 检查缓存
	if _cache.has(key):
		return _cache[key]
	
	# 查找资源路径
	var path = _find_resource_path(key, category)
	if path.is_empty():
		push_warning("[ResourceManager] Resource not found: " + key)
		return null
	
	# 加载资源
	if ResourceLoader.exists(path):
		var resource = load(path)
		if resource:
			_cache[key] = resource
			resource_loaded.emit(key)
			return resource
	
	push_warning("[ResourceManager] Failed to load: " + path)
	return null

## 查找资源路径
func _find_resource_path(key: String, category: String) -> String:
	if category.is_empty():
		# 搜索所有类别
		for cat in _index.values():
			if cat.has(key):
				return cat[key]
	else:
		# 搜索指定类别
		if _index.has(category) and _index[category].has(key):
			return _index[category][key]
	return ""

## 异步加载资源
func load_resource_async(key: String, category: String = "") -> void:
	var path = _find_resource_path(key, category)
	if path.is_empty():
		return
	
	_is_loading = true
	ResourceLoader.load_threaded_request(path)
	
	# 等待加载完成
	while true:
		var progress = []
		var status = ResourceLoader.load_threaded_get_status(path, progress)
		
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			var resource = ResourceLoader.load_threaded_get(path)
			_cache[key] = resource
			resource_loaded.emit(key)
			break
		elif status == ResourceLoader.THREAD_LOAD_FAILED:
			push_error("[ResourceManager] Failed to load: " + path)
			break
		
		# 更新进度
		if progress.size() > 0:
			_loading_progress = progress[0]
			loading_progress_changed.emit(_loading_progress)
		
		await get_tree().process_frame
	
	_is_loading = false

## 批量加载资源
func load_resources_batch(keys: Array[String], category: String = "") -> void:
	_is_loading = true
	var total = keys.size()
	var loaded = 0
	
	for key in keys:
		await load_resource_async(key, category)
		loaded += 1
		_loading_progress = float(loaded) / float(total)
		loading_progress_changed.emit(_loading_progress)
	
	_is_loading = false
	all_resources_loaded.emit()

## 预加载常用资源
func preload_common_resources() -> void:
	var common_keys = [
		"button_primary",
		"button_secondary",
		"panel_main",
		"icon_health",
		"icon_mana",
		"bar_health",
		"bar_mana"
	]
	
	await load_resources_batch(common_keys, "ui")

## 获取卡牌图片
func get_card_image(card_id: String) -> Texture2D:
	return get_resource(card_id, "cards") as Texture2D

## 获取角色立绘
func get_character_sprite(character_id: String) -> Texture2D:
	return get_resource(character_id, "characters") as Texture2D

## 获取UI元素
func get_ui_element(element_id: String) -> Texture2D:
	return get_resource(element_id, "ui") as Texture2D

## 获取环境背景
func get_environment_background(area_id: String) -> Texture2D:
	return get_resource(area_id, "environments") as Texture2D

## 获取特效
func get_effect(effect_id: String) -> Texture2D:
	return get_resource(effect_id, "effects") as Texture2D

## 获取音效
func get_audio(audio_id: String) -> AudioStream:
	return get_resource(audio_id, "audio") as AudioStream

## 清除缓存
func clear_cache() -> void:
	_cache.clear()
	print("[ResourceManager] Cache cleared")

## 清除指定资源
func unload_resource(key: String) -> void:
	if _cache.has(key):
		_cache.erase(key)
		print("[ResourceManager] Unloaded: " + key)

## 获取加载进度
func get_loading_progress() -> float:
	return _loading_progress

## 是否正在加载
func is_loading() -> bool:
	return _is_loading

## 获取缓存大小
func get_cache_size() -> int:
	return _cache.size()

## 获取所有资源键
func get_all_keys(category: String = "") -> Array[String]:
	var keys: Array[String] = []
	
	if category.is_empty():
		for cat in _index.values():
			keys.append_array(cat.keys())
	else:
		if _index.has(category):
			keys.append_array(_index[category].keys())
	
	return keys
