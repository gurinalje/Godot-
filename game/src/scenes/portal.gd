## 传送门
## 允许玩家传送到其他区域
class_name Portal
extends Area2D

# 传送门属性
@export var target_area: String = ""
@export var portal_name: String = "传送门"

# 信号
signal portal_entered(target_area: String)

# 初始化
func _ready() -> void:
	# 创建视觉效果
	_create_visual()
	
	# 连接信号
	body_entered.connect(_on_body_entered)

## 创建视觉效果
func _create_visual() -> void:
	# 创建传送门精灵
	var sprite = Sprite2D.new()
	var texture = _create_portal_texture()
	sprite.texture = texture
	sprite.scale = Vector2(3, 3)
	add_child(sprite)
	
	# 创建碰撞形状
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 24
	collision.shape = shape
	add_child(collision)
	
	# 创建标签
	var label = Label.new()
	label.text = portal_name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position.y = -60
	add_child(label)

## 创建传送门纹理
func _create_portal_texture() -> ImageTexture:
	var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	# 绘制传送门（蓝色光环）
	var center = Vector2(16, 16)
	for x in range(32):
		for y in range(32):
			var pos = Vector2(x, y)
			var distance = pos.distance_to(center)
			
			# 外环
			if distance >= 12 and distance <= 14:
				image.set_pixel(x, y, Color(0.2, 0.6, 1.0))
			# 内环
			elif distance >= 8 and distance <= 10:
				image.set_pixel(x, y, Color(0.4, 0.8, 1.0))
			# 中心
			elif distance < 8:
				image.set_pixel(x, y, Color(0.6, 0.9, 1.0, 0.8))
	
	return ImageTexture.create_from_image(image)

## 玩家进入传送门
func _on_body_entered(body: Node2D) -> void:
	# 使用group检测而非节点名检测（更可靠）
	if body.is_in_group("player") or body.name == "Player":
		portal_entered.emit(target_area)
