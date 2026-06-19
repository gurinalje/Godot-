extends CharacterBody2D

## Player movement speed in pixels per second.
@export var speed: float = 200.0

## Player jump velocity.
@export var jump_velocity: float = -400.0

## Gravity from project settings.
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

## Current animation state
var current_animation: String = "idle"

## Spritesheet paths
const IDLE_SHEET = "res://assets/sprites/characters/players/char_players_vampire_mage_idle.png"
const WALK_SHEET = "res://assets/sprites/characters/players/char_players_vampire_mage_walk.png"
const ATTACK_SHEET = "res://assets/sprites/characters/players/char_players_vampire_mage_attack.png"

## Frame dimensions for spritesheet slicing
const IDLE_FRAME_WIDTH = 128  # 512px / 4帧
const WALK_FRAME_WIDTH = 192  # 1152px / 6帧
const ATTACK_FRAME_WIDTH = 128  # 假设与idle相同
const FRAME_HEIGHT = 48

## Frame counts per animation
const IDLE_FRAMES = 4
const WALK_FRAMES = 6
const ATTACK_FRAMES = 5

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	_setup_animations()


func _setup_animations() -> void:
	"""Configure AnimatedSprite2D with spritesheet-based animations."""
	var sprite_frames = SpriteFrames.new()
	
	# Add idle animation from spritesheet
	_add_animation_from_sheet(sprite_frames, "idle", IDLE_SHEET, IDLE_FRAMES, IDLE_FRAME_WIDTH, 4.0, true)
	
	# Add walk animation from spritesheet
	_add_animation_from_sheet(sprite_frames, "walk", WALK_SHEET, WALK_FRAMES, WALK_FRAME_WIDTH, 10.0, true)
	
	# Add attack animation from spritesheet
	_add_animation_from_sheet(sprite_frames, "attack", ATTACK_SHEET, ATTACK_FRAMES, ATTACK_FRAME_WIDTH, 20.0, false)
	
	animated_sprite.sprite_frames = sprite_frames
	animated_sprite.play("idle")


func _add_animation_from_sheet(sprite_frames: SpriteFrames, anim_name: String, sheet_path: String, frame_count: int, frame_width: int, fps: float, loop: bool) -> void:
	"""Add an animation to SpriteFrames by slicing a spritesheet."""
	var texture: Texture2D = load(sheet_path)
	if texture == null:
		push_error("Failed to load texture: " + sheet_path)
		return
	
	sprite_frames.add_animation(anim_name)
	sprite_frames.set_animation_speed(anim_name, fps)
	sprite_frames.set_animation_loop(anim_name, loop)
	
	# Create AtlasTexture for each frame
	for i in range(frame_count):
		var atlas_texture = AtlasTexture.new()
		atlas_texture.atlas = texture
		atlas_texture.region = Rect2(i * frame_width, 0, frame_width, FRAME_HEIGHT)
		sprite_frames.add_frame(anim_name, atlas_texture)


func _physics_process(delta: float) -> void:
	# Add gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity

	# Get input direction.
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

	# Update animation based on movement
	_update_animation(direction)

	move_and_slide()


func _update_animation(direction: float) -> void:
	"""Update the current animation based on player state."""
	var new_animation: String = "idle"
	
	if not is_on_floor():
		new_animation = "idle"  # Could add jump animation later
	elif direction != 0:
		new_animation = "walk"
		# Flip sprite based on direction
		animated_sprite.flip_h = direction < 0
	
	if new_animation != current_animation:
		current_animation = new_animation
		animated_sprite.play(current_animation)


func attack() -> void:
	"""Play attack animation."""
	current_animation = "attack"
	animated_sprite.play("attack")
	# Wait for animation to finish
	await animated_sprite.animation_finished
	current_animation = "idle"
	animated_sprite.play("idle")
