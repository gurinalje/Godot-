## 音频管理器
## 管理游戏中的所有音频播放
class_name AudioManager
extends Node

## 游戏配置资源路径
const GAME_CONFIG_PATH: String = "res://src/resources/game_config.tres"

# 依赖注入
@export var game_config: GameConfig

## BGM播放器
var bgm_player: AudioStreamPlayer

## SFX播放器池
var sfx_players: Array[AudioStreamPlayer] = []

## 主音量（0.0 ~ 1.0）
var master_volume: float = 1.0

## BGM音量（0.0 ~ 1.0）
var bgm_volume: float = 0.8

## SFX音量（0.0 ~ 1.0）
var sfx_volume: float = 1.0

## 当前播放的BGM名称
var current_bgm: String = ""

## 音频缓存（键为音频名称，值为AudioStream资源）
var audio_cache: Dictionary[String, AudioStream] = {}

## 信号：BGM切换
signal bgm_changed(track_name: String)

## 信号：音效播放
signal sfx_played(sfx_name: String)

func _ready() -> void:
	initialize()

## 初始化音频管理器
## 加载游戏配置，创建音频播放器并加载音频缓存
func initialize() -> void:
	_load_game_config()
	_create_audio_players()
	_load_audio_cache()
	print("[AudioManager] Initialized")

## 加载游戏配置
## 尝试从资源文件加载GameConfig，如果失败则创建默认配置
func _load_game_config() -> void:
	if game_config:
		return
	
	# 尝试从资源文件加载
	if ResourceLoader.exists(GAME_CONFIG_PATH):
		var config: GameConfig = load(GAME_CONFIG_PATH) as GameConfig
		if config:
			game_config = config
			# 应用配置中的默认音量
			bgm_volume = config.default_bgm_volume
			sfx_volume = config.default_sfx_volume
			return
	
	# 创建默认配置
	game_config = GameConfig.new()
	push_warning("[AudioManager] Using default GameConfig")

## 设置GameConfig依赖
func set_game_config(config: GameConfig) -> void:
	game_config = config
	# 应用配置中的默认音量
	bgm_volume = config.default_bgm_volume
	sfx_volume = config.default_sfx_volume

## 创建音频播放器
## 创建BGM播放器和SFX播放器池
func _create_audio_players() -> void:
	# 创建BGM播放器
	bgm_player = AudioStreamPlayer.new()
	bgm_player.name = "BGMPlayer"
	var music_bus_exists = AudioServer.get_bus_index("Music") != -1
	bgm_player.bus = "Music" if music_bus_exists else "Master"
	add_child(bgm_player)
	
	# 创建SFX播放器池
	var sfx_bus_exists = AudioServer.get_bus_index("SFX") != -1
	for i in range(8):
		var sfx_player = AudioStreamPlayer.new()
		sfx_player.name = "SFXPlayer" + str(i)
		sfx_player.bus = "SFX" if sfx_bus_exists else "Master"
		add_child(sfx_player)
		sfx_players.append(sfx_player)

## 加载音频缓存
## 扫描配置中指定的音频目录，加载所有音频文件到缓存
func _load_audio_cache() -> void:
	# 扫描音频目录
	var audio_dir: String = game_config.audio_path
	_scan_audio_directory(audio_dir + "sfx/")
	_scan_audio_directory(audio_dir + "music/")

## 扫描音频目录
func _scan_audio_directory(path: String) -> void:
	var dir = DirAccess.open(path)
	if not dir:
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if dir.current_is_dir():
			if not file_name.begins_with("."):
				_scan_audio_directory(path + file_name + "/")
		elif file_name.ends_with(".wav") or file_name.ends_with(".ogg"):
			var audio_path = path + file_name
			var audio = load(audio_path)
			if audio:
				var key = file_name.get_basename()
				audio_cache[key] = audio
		file_name = dir.get_next()
	
	dir.list_dir_end()

## 播放BGM
func play_bgm(track_name: String) -> void:
	if current_bgm == track_name:
		return
	
	var audio = _get_audio(track_name)
	if not audio:
		push_warning("[AudioManager] BGM not found: " + track_name)
		return
	
	bgm_player.stream = audio
	bgm_player.volume_db = linear_to_db(bgm_volume * master_volume)
	bgm_player.play()
	current_bgm = track_name
	bgm_changed.emit(track_name)
	print("[AudioManager] Playing BGM: ", track_name)

## 停止BGM
func stop_bgm() -> void:
	bgm_player.stop()
	current_bgm = ""

## 播放音效
func play_sfx(sfx_name: String) -> void:
	var audio = _get_audio(sfx_name)
	if not audio:
		push_warning("[AudioManager] SFX not found: " + sfx_name)
		return
	
	# 找到空闲的SFX播放器
	var player = _get_free_sfx_player()
	if not player:
		push_warning("[AudioManager] No free SFX player")
		return
	
	player.stream = audio
	player.volume_db = linear_to_db(sfx_volume * master_volume)
	player.play()
	sfx_played.emit(sfx_name)

## 获取音频
func _get_audio(audio_name: String) -> AudioStream:
	# 检查缓存
	if audio_cache.has(audio_name):
		return audio_cache[audio_name]
	
	# 尝试加载
	var audio_dir: String = game_config.audio_path
	var paths = [
		audio_dir + "sfx/" + audio_name + ".wav",
		audio_dir + "sfx/" + audio_name + ".ogg",
		audio_dir + "music/" + audio_name + ".wav",
		audio_dir + "music/" + audio_name + ".ogg"
	]
	
	for path in paths:
		if ResourceLoader.exists(path):
			var audio = load(path)
			if audio:
				audio_cache[audio_name] = audio
				return audio
	
	return null

## 获取空闲的SFX播放器
func _get_free_sfx_player() -> AudioStreamPlayer:
	for player in sfx_players:
		if not player.playing:
			return player
	return sfx_players[0]

## 设置主音量
func set_master_volume(volume: float) -> void:
	master_volume = clamp(volume, 0.0, 1.0)
	_update_volumes()

## 设置BGM音量
func set_bgm_volume(volume: float) -> void:
	bgm_volume = clamp(volume, 0.0, 1.0)
	bgm_player.volume_db = linear_to_db(bgm_volume * master_volume)

## 设置SFX音量
func set_sfx_volume(volume: float) -> void:
	sfx_volume = clamp(volume, 0.0, 1.0)

## 更新音量
func _update_volumes() -> void:
	if bgm_player.playing:
		bgm_player.volume_db = linear_to_db(bgm_volume * master_volume)

## 获取当前BGM
func get_current_bgm() -> String:
	return current_bgm

## 暂停BGM
func pause_bgm() -> void:
	bgm_player.stream_paused = true

## 恢复BGM
func resume_bgm() -> void:
	bgm_player.stream_paused = false

## 清理音频缓存
## 释放所有缓存的音频资源，释放内存
func clear_cache() -> void:
	audio_cache.clear()
	print("[AudioManager] Audio cache cleared")
