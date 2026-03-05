extends CharacterBody2D

@export var speed = 400  # 移动速度，可以在编辑器中修改

# 获取屏幕大小，用于限制移动范围
@onready var screen_size = get_viewport_rect().size
# 自身的碰撞形状大小（这里假设是矩形，半宽半高）
@onready var sprite_size = $ColorRect.size

# 技能系统
var base_scale = Vector2.ONE
var current_shield = 0
var reverse_controls_active = false
var blind_mode_active = false

# 信号
signal ball_dodged()

# 球跟踪计数（用于统计躲避的球）
var tracked_balls: Dictionary = {}

func _ready():
	# 初始化基础缩放
	base_scale = scale
	# 连接 SkillManager 信号
	if has_node("/root/SkillManager"):
		SkillManager.skill_acquired.connect(_on_skill_acquired)
		SkillManager.skill_removed.connect(_on_skill_removed)

	# 连接 Area2D 信号 - 用于检测球
	if has_node("DetectionArea"):
		$DetectionArea.body_entered.connect(_on_detection_area_body_entered)
		$DetectionArea.body_exited.connect(_on_detection_area_body_exited)
		# 添加 area_entered 用于检测问号块等 Area2D 对象
		$DetectionArea.area_entered.connect(_on_detection_area_area_entered)

func _physics_process(delta):
	var velocity = Vector2.ZERO  # 玩家的移动向量

	# 1. 检测键盘输入 (优先)
	var input_direction = Vector2.ZERO
	if Input.is_action_pressed("ui_right"):
		input_direction.x += 1
	if Input.is_action_pressed("ui_left"):
		input_direction.x -= 1
	if Input.is_action_pressed("ui_down"):
		input_direction.y += 1
	if Input.is_action_pressed("ui_up"):
		input_direction.y -= 1

	# 应用反向控制
	if SkillManager.has_reverse_controls():
		input_direction = -input_direction

	# 2. 检测触摸/鼠标输入 (如果没有键盘输入)
	# Godot 默认将单点触摸映射为鼠标左键
	if input_direction == Vector2.ZERO and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var target_pos = get_global_mouse_position()
		var direction = target_pos - position

		# 设置一个死区 (10 像素)，防止到达目标点后抖动
		if direction.length() > 10:
			velocity = direction.normalized()
	else:
		velocity = input_direction

	# 如果有输入，归一化并乘以速度
	if velocity.length() > 0:
		velocity = velocity.normalized() * get_current_speed()

	# 更新位置
	position += velocity * delta

	# 限制玩家在屏幕范围内
	# 减去/加上半个身位，保证身体不通过边缘
	var current_scale = get_current_scale()
	var adjusted_sprite_size = sprite_size * current_scale.x
	position.x = clamp(position.x, adjusted_sprite_size.x / 2, screen_size.x - adjusted_sprite_size.x / 2)
	position.y = clamp(position.y, adjusted_sprite_size.y / 2, screen_size.y - adjusted_sprite_size.y / 2)

func get_current_speed() -> float:
	"""获取当前移动速度（包含技能修饰）"""
	var base_speed = speed
	var modifier = SkillManager.get_player_speed_modifier()
	return base_speed * (1.0 + modifier)

func get_current_scale() -> Vector2:
	"""获取当前缩放（包含技能修饰）"""
	var modifier = SkillManager.get_player_scale_modifier()
	return base_scale * modifier

func set_shield(count: int):
	"""设置护盾数量"""
	current_shield = count
	# 更新护盾显示
	if has_node("ShieldLabel"):
		if count > 0:
			$ShieldLabel.text = "🛡️ x" + str(count)
			$ShieldLabel.show()
		else:
			$ShieldLabel.hide()

func _on_skill_acquired(skill_id: String):
	"""当获得技能时"""
	# 更新玩家大小
	scale = get_current_scale()

	# 应用盲视模式
	if skill_id == "blind_mode":
		apply_blind_mode()

	# 应用反向控制
	if skill_id == "reverse_controls":
		reverse_controls_active = true

func _on_skill_removed(skill_id: String):
	"""当移除技能时"""
	# 恢复玩家大小
	scale = get_current_scale()

	# 恢复盲视模式
	if skill_id == "blind_mode":
		remove_blind_mode()

	# 恢复反向控制
	if skill_id == "reverse_controls":
		reverse_controls_active = false

func apply_blind_mode():
	"""应用盲视效果"""
	$ColorRect.modulate = Color(0.5, 0.5, 0.5, 0.7)

func remove_blind_mode():
	"""移除盲视效果"""
	$ColorRect.modulate = Color.WHITE

func _on_detection_area_body_entered(body):
	"""当球进入检测区域时开始跟踪"""
	if body.is_in_group("balls"):
		tracked_balls[body] = true

func _on_detection_area_body_exited(body):
	"""当球离开检测区域时，视为成功躲避"""
	if tracked_balls.has(body):
		tracked_balls.erase(body)
		ball_dodged.emit()

func _on_detection_area_area_entered(area):
	"""当其他 Area2D 进入检测区域时（如问号块）"""
	# 这个方法用于检测问号块等 Area2D 对象
	# 问号块会自己处理 area_entered 信号
	pass
