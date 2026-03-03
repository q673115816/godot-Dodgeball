extends RigidBody2D

var player_reference = null

func _process(delta):
	# 获取视口矩形
	var viewport_rect = get_viewport_rect()
	# 扩大矩形范围作为销毁边界（例如各方向扩大 100 像素）
	var kill_rect = viewport_rect.grow(100)

	# 如果球跑出了这个扩大的范围，就销毁
	if not kill_rect.has_point(position):
		queue_free()

	# 应用磁力偏转效果
	if SkillManager.has_magnet_deflect() and player_reference:
		apply_magnet_deflect()

	# 应用减速力场效果
	var slowdown = SkillManager.get_ball_slowdown_field()
	if slowdown > 0 and player_reference:
		apply_ball_slowdown(slowdown)

func apply_magnet_deflect():
	"""应用磁力偏转效果"""
	var player_pos = player_reference.position
	var direction = position - player_pos
	var distance = direction.length()

	# 在 150 像素范围内开始偏转
	if distance < 150:
		var force = direction.normalized() * 50 * (1.0 - distance / 150)
		apply_central_force(force)

func apply_ball_slowdown(slowdown_factor: float):
	"""应用减速力场效果"""
	var player_pos = player_reference.position
	var direction = position - player_pos
	var distance = direction.length()

	# 在 100 像素范围内减速
	if distance < 100:
		var slowdown = linear_velocity.length() * slowdown_factor * (1.0 - distance / 100)
		linear_velocity = linear_velocity.normalized() * max(50, linear_velocity.length() - slowdown)

func _on_body_entered(body):
	if body.name == "Player":
		player_reference = body
