extends Node2D

@export var ball_scene: PackedScene  # 在编辑器中拖入 ball.tscn
var score: float = 0.0  # 改为浮点数以支持毫秒
var game_running = false
var game_over_state = false

# 难度控制变量
var difficulty_level = 1
var max_difficulty = 10
var time_since_last_difficulty_increase = 0.0
var difficulty_interval = 5.0  # 每 5 秒增加一次难度

# 技能系统变量
var base_spawn_interval = 0.5  # 基础生成间隔
var skills_dodged_count = 0  # 躲避的球数量（用于吸血技能）
var ghost_revive_used = false  # 幽灵复活是否已使用
var bomb_timer = 0.0  # 炸弹计时器
var revive_timer = 0.0  # 复活计时器（幽灵技能）
var awaiting_revive = false  # 是否等待复活

func _ready():
	# 使用代码连接计时器信号
	$BallTimer.timeout.connect(_on_ball_timer_timeout)

	# 初始化分数
	$HUD/ScoreLabel.text = "Time: 0.000 s"
	$HUD/DifficultyLabel.text = "Level: 1"

	# 设置玩家初始位置到屏幕中央
	$Player.position = Vector2(400, 300)

	# 显示开始提示
	$HUD/MessageLabel.text = "Press Arrow Keys\nor Touch to Start"
	$HUD/MessageLabel.show()

	# 确保计时器初始是停止的
	$BallTimer.stop()

	# 初始化 SkillManager 回调
	if has_node("/root/SkillManager"):
		SkillManager.skill_acquired.connect(_on_skill_acquired)
		SkillManager.skill_removed.connect(_on_skill_removed)
		$Player.connect("ball_dodged", _on_ball_dodged)

func _process(delta):
	# 游戏暂停时不处理其他逻辑
	if game_paused:
		return

	# 游戏未开始且未结束时，检测输入以开始游戏
	if not game_running and not game_over_state and not awaiting_revive:
		# 键盘开始
		if Input.is_action_pressed("ui_up") or Input.is_action_pressed("ui_down") or \
		   Input.is_action_pressed("ui_left") or Input.is_action_pressed("ui_right"):
			start_game()
		# 触摸/鼠标点击开始
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			start_game()

	# 游戏进行中，更新时间与难度
	if game_running:
		# 应用时间流逝修饰
		var time_slow = SkillManager.get_time_slow_modifier()
		var actual_delta = delta * (1.0 - time_slow)

		score += actual_delta
		$HUD/ScoreLabel.text = "Time: %.3f s" % score

		# 难度提升逻辑
		if difficulty_level < max_difficulty:
			time_since_last_difficulty_increase += actual_delta
			if time_since_last_difficulty_increase >= difficulty_interval:
				increase_difficulty()
				time_since_last_difficulty_increase = 0.0

		# 炸弹技能计时器
		if SkillManager.has_skill("bomb"):
			bomb_timer += delta
			if bomb_timer >= 10.0:
				activate_bomb()
				bomb_timer = 0.0

		# 幽灵复活计时器
		if awaiting_revive:
			revive_timer += delta
			if revive_timer >= 3.0:
				# 超时未复活，正常死亡
				awaiting_revive = false
				game_over_state = true
				$HUD/MessageLabel.text = "GAME OVER\nSurvived: %.3f s\nMax Level: %d\nPress R or Touch" % [score, difficulty_level]
				$HUD/MessageLabel.show()

	# 游戏结束状态下，按 R 重启
	if game_over_state:
		if Input.is_key_pressed(KEY_R):
			restart_game()
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			restart_game()

func start_game():
	game_running = true
	$HUD/MessageLabel.hide()

	# 重置难度
	difficulty_level = 1
	time_since_last_difficulty_increase = 0.0
	$HUD/DifficultyLabel.text = "Level: 1"

	# 重置技能相关
	skills_dodged_count = 0
	ghost_revive_used = false
	bomb_timer = 0.0
	SkillManager.clear_all_skills()

	# 应用初始生成间隔
	update_spawn_interval()
	$BallTimer.start()

func update_spawn_interval():
	"""根据难度和技能更新生成间隔"""
	# 基础间隔随难度变化
	var difficulty_factor = max(0.05, 0.5 - (difficulty_level - 1) * 0.05)

	# 应用技能修饰
	var spawn_modifier = SkillManager.get_spawn_interval_modifier()

	# 计算最终间隔
	var final_interval = difficulty_factor * (1.0 + spawn_modifier)
	$BallTimer.wait_time = max(0.02, final_interval)

func increase_difficulty():
	difficulty_level += 1
	$HUD/DifficultyLabel.text = "Level: " + str(difficulty_level)

	# === Roguelike 技能获取 ===
	var new_skill = SkillManager.generate_random_skill(difficulty_level)
	if new_skill != "":
		SkillManager.acquire_skill(new_skill)
		show_skill_notification(new_skill)

		# 检查是否有生命恢复技能
		if SkillManager.has_skill("regen"):
			var current_shields = SkillManager.get_shield_count()
			$Player.set_shield(current_shields)

	# 更新生成间隔
	update_spawn_interval()

func show_skill_notification(skill_id: String):
	"""显示技能获取通知"""
	var info = SkillManager.get_skill_info(skill_id)
	var type_indicator = ""
	match info.type:
		"positive":
			type_indicator = "🟢 "
		"negative":
			type_indicator = "🔴 "
		"special":
			type_indicator = "⚡ "

	$HUD/MessageLabel.text = "LEVEL UP!\n%s%s\n%s" % [type_indicator, info.name, info.description]
	$HUD/MessageLabel.show()

	# 1.5 秒后隐藏通知
	await get_tree().create_timer(1.5).timeout
	if game_running:
		$HUD/MessageLabel.hide()

func activate_bomb():
	"""激活炸弹技能，清除屏幕上所有球"""
	# 获取所有球节点
	var balls = get_tree().get_nodes_in_group("balls")
	for ball in balls:
		ball.queue_free()

	# 显示特效
	$HUD/MessageLabel.text = "BOMB!\nAll balls cleared!"
	$HUD/MessageLabel.show()
	await get_tree().create_timer(1.0).timeout
	if game_running:
		$HUD/MessageLabel.hide()

func _on_ball_timer_timeout():
	if not game_running: return

	# 实例化球
	spawn_ball()

	# 高难度下，偶尔一次生成多个球 (例如 Level 5 以上，每次有概率额外生成一个)
	if difficulty_level >= 5 and randf() > 0.5:
		spawn_ball()

	# Level 8 以上，必定额外生成，甚至可能三个
	if difficulty_level >= 8:
		spawn_ball()

	# 技能：多重生成
	var extra_spawn = SkillManager.get_extra_spawn_count()
	for i in range(extra_spawn):
		spawn_ball()

func spawn_ball():
	var ball = ball_scene.instantiate()

	# 决定生成球的边 (0:上，1:下，2:左，3:右)
	var side = randi() % 4
	var spawn_pos = Vector2.ZERO
	var screen_size = get_viewport_rect().size
	var buffer = 50

	match side:
		0: spawn_pos = Vector2(randf_range(0, screen_size.x), -buffer)
		1: spawn_pos = Vector2(randf_range(0, screen_size.x), screen_size.y + buffer)
		2: spawn_pos = Vector2(-buffer, randf_range(0, screen_size.y))
		3: spawn_pos = Vector2(screen_size.x + buffer, randf_range(0, screen_size.y))

	ball.position = spawn_pos

	# 计算朝向
	var player_pos = $Player.position
	var direction = (player_pos - spawn_pos).normalized()

	# 难度也会轻微影响球速
	var speed_multiplier = 1.0 + (difficulty_level * 0.05)  # 每级增加 5% 速度

	# 应用技能修饰
	var ball_speed_mod = SkillManager.get_ball_speed_modifier()
	speed_multiplier *= (1.0 + ball_speed_mod)

	var speed = randf_range(200, 400) * speed_multiplier
	ball.linear_velocity = direction * speed

	# 应用龙卷风轨迹
	if SkillManager.has_tornado_trajectory():
		ball.angular_velocity = randf_range(200, 400) * (1 if randf() > 0.5 else -1)

	ball.contact_monitor = true
	ball.max_contacts_reported = 1
	ball.body_entered.connect(_on_ball_body_entered)
	ball.add_to_group("balls")

	# 设置玩家引用（用于技能效果）
	ball.player_reference = $Player

	add_child(ball)

func _on_ball_dodged():
	"""当球被成功躲避时调用"""
	skills_dodged_count += 1

	# 吸血技能：每躲避 50 个球，Level -1
	if SkillManager.has_skill("vampire") and skills_dodged_count % 50 == 0:
		difficulty_level = max(1, difficulty_level - 1)
		$HUD/DifficultyLabel.text = "Level: " + str(difficulty_level)

		$HUD/MessageLabel.text = "VAMPIRE!\nLevel decreased!"
		$HUD/MessageLabel.show()
		await get_tree().create_timer(1.0).timeout
		if game_running:
			$HUD/MessageLabel.hide()

func _on_ball_body_entered(body):
	if body.name == "Player":
		# 检查护盾
		var shield_count = SkillManager.get_shield_count()
		if shield_count > 0 and not awaiting_revive:
			# 消耗一层护盾
			SkillManager.active_skills["shield"] = shield_count - 1
			if SkillManager.active_skills["shield"] <= 0:
				SkillManager.active_skills.erase("shield")

			# 显示护盾破碎提示
			$HUD/MessageLabel.text = "SHIELD BROKE!"
			$HUD/MessageLabel.show()
			await get_tree().create_timer(1.0).timeout
			if game_running:
				$HUD/MessageLabel.hide()

			# 更新玩家护盾显示
			$Player.set_shield(SkillManager.active_skills.get("shield", 0))
			return

		# 检查幽灵技能
		if SkillManager.has_skill("ghost") and not ghost_revive_used and not awaiting_revive:
			ghost_revive_used = true
			awaiting_revive = true
			revive_timer = 0.0

			$HUD/MessageLabel.text = "GHOST!\nYou have 3 seconds to revive!"
			$HUD/MessageLabel.show()

			# 清除屏幕上所有球，给玩家机会
			var balls = get_tree().get_nodes_in_group("balls")
			for ball in balls:
				ball.queue_free()
			return

		# 如果正在等待复活且碰到球，视为成功复活
		if awaiting_revive:
			awaiting_revive = false
			$HUD/MessageLabel.hide()
			return

		game_over()

func game_over():
	game_running = false
	game_over_state = true
	$BallTimer.stop()
	$HUD/MessageLabel.text = "GAME OVER\nSurvived: %.3f s\nMax Level: %d\nPress R or Touch" % [score, difficulty_level]
	$HUD/MessageLabel.show()

func restart_game():
	get_tree().reload_current_scene()

func _on_skill_acquired(skill_id: String):
	"""当获得技能时更新 UI"""
	update_skill_ui()

func _on_skill_removed(skill_id: String):
	"""当失去技能时更新 UI"""
	update_skill_ui()

func update_skill_ui():
	"""更新技能 UI 显示"""
	# 清除现有技能图标
	for child in $HUD/SkillContainer.get_children():
		child.queue_free()

	# 添加新技能图标
	for skill_id in SkillManager.get_all_active_skills():
		var info = SkillManager.get_skill_info(skill_id)
		var stack = SkillManager.get_skill_stack(skill_id)

		var label = Label.new()
		label.theme_override_font_sizes.font_size = 16

		# 根据技能类型设置颜色
		var color = Color.WHITE
		match info.type:
			"positive":
				color = Color(0.2, 1.0, 0.2)  # 绿色
			"negative":
				color = Color(1.0, 0.2, 0.2)  # 红色
			"special":
				color = Color(0.8, 0.2, 1.0)  # 紫色

		# 显示技能图标和层数
		var icon = ""
		match info.type:
			"positive":
				icon = "🟢"
			"negative":
				icon = "🔴"
			"special":
				icon = "⚡"

		if stack > 1:
			label.text = "%s %sx%d" % [icon, info.name.substr(0, 8), stack]
		else:
			label.text = "%s %s" % [icon, info.name.substr(0, 10)]

		label.modulate = color
		$HUD/SkillContainer.add_child(label)
