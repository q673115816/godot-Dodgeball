extends RigidBody2D

func _process(delta):
	# 获取视口矩形
	var viewport_rect = get_viewport_rect()
	# 扩大矩形范围作为销毁边界（例如各方向扩大100像素）
	var kill_rect = viewport_rect.grow(100)
	
	# 如果球跑出了这个扩大的范围，就销毁
	if not kill_rect.has_point(position):
		queue_free()
