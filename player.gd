extends CharacterBody2D

@export var speed = 400 # 移动速度，可以在编辑器中修改

# 获取屏幕大小，用于限制移动范围
@onready var screen_size = get_viewport_rect().size
# 自身的碰撞形状大小（这里假设是矩形，半宽半高）
@onready var sprite_size = $ColorRect.size

func _physics_process(delta):
	var velocity = Vector2.ZERO # 玩家的移动向量
	
	# 1. 检测键盘输入 (优先)
	if Input.is_action_pressed("ui_right"):
		velocity.x += 1
	if Input.is_action_pressed("ui_left"):
		velocity.x -= 1
	if Input.is_action_pressed("ui_down"):
		velocity.y += 1
	if Input.is_action_pressed("ui_up"):
		velocity.y -= 1

	# 2. 检测触摸/鼠标输入 (如果没有键盘输入)
	# Godot 默认将单点触摸映射为鼠标左键
	if velocity == Vector2.ZERO and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var target_pos = get_global_mouse_position()
		var direction = target_pos - position
		
		# 设置一个死区(10像素)，防止到达目标点后抖动
		if direction.length() > 10:
			velocity = direction.normalized()

	# 如果有输入，归一化并乘以速度
	if velocity.length() > 0:
		velocity = velocity.normalized() * speed

	# 更新位置
	position += velocity * delta
	
	# 限制玩家在屏幕范围内
	# 减去/加上半个身位，保证身体不通过边缘
	position.x = clamp(position.x, sprite_size.x / 2, screen_size.x - sprite_size.x / 2)
	position.y = clamp(position.y, sprite_size.y / 2, screen_size.y - sprite_size.y / 2)
