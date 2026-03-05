extends Node2D

@export var ball_scene: PackedScene
@export var question_block_scene: PackedScene
@export var pause_menu_scene: PackedScene
var score: float = 0.0
var game_running = false
var game_over_state = false
var game_paused = false

# 问号块生成
var question_block_timer = 0.0
var question_block_interval_min = 10.0
var question_block_interval_max = 30.0
var current_question_block_interval = 15.0

# 难度控制变量
var difficulty_level = 1
var max_difficulty = 8
var time_since_last_difficulty_increase = 0.0
var difficulty_interval = 8.0

# 技能系统变量
var base_spawn_interval = 0.5
var skills_dodged_count = 0
var ghost_revive_used = false
var bomb_timer = 0.0
var revive_timer = 0.0
var awaiting_revive = false

# 输入检测
var player_uses_mouse = false
var input_sample_timer = 0.0
var keyboard_input_count = 0
var mouse_input_count = 0
var input_sample_complete = false

# 清除横条功能
var clearance_bar_timer = 0.0
var clearance_bar_interval = 20.0
var clearance_bar_warning_time = 3.0
var clearance_bar_sweep_time = 1.5
var clearance_bar_active = false
var clearance_bar_warning = false
var clearance_bar_direction = 0  # 0=水平从上到下，1=垂直从左到右
var clearance_bar_position = 0.0  # 0.0 到 1.0
var clearance_bar_thickness = 15.0  # 横条厚度（碰撞区域）
var clearance_bar_length_ratio = 0.5  # 横条长度占屏幕比例（半屏）

# 主菜单背景渐变
var menu_bg_timer = 0.0
var menu_bg_colors = [Color(0.1, 0.1, 0.3), Color(0.2, 0.1, 0.2), Color(0.1, 0.2, 0.2)]
var current_bg_color_index = 0

# 暂停菜单
var pause_menu = null

# 游戏内容容器
var game_content = null

func _ready():
	# 创建游戏内容容器节点
	game_content = Node2D.new()
	game_content.name = "GameContent"
	add_child(game_content)

	# 将 Player 移动到游戏内容容器
	if has_node("Player"):
		$Player.reparent(game_content)

	$BallTimer.timeout.connect(_on_ball_timer_timeout)
	$HUD/ScoreLabel.text = "Time: 0.000 s"
	$HUD/DifficultyLabel.text = "Level: 1"
	if game_content.has_node("Player"):
		game_content.get_node("Player").position = Vector2(400, 300)
	$HUD/MessageLabel.hide()
	$BallTimer.stop()

	# 初始隐藏游戏内容
	_hide_game_content()

	if has_node("/root/SkillManager"):
		SkillManager.skill_acquired.connect(_on_skill_acquired)
		SkillManager.skill_removed.connect(_on_skill_removed)
		if game_content.has_node("Player"):
			game_content.get_node("Player").connect("ball_dodged", _on_ball_dodged)

	# 初始化清除横条 UI（半透明红色）
	if not $HUD.has_node("ClearanceBar"):
		var bar = ColorRect.new()
		bar.name = "ClearanceBar"
		bar.color = Color(1, 0, 0, 0.5)
		$HUD.add_child(bar)

	# 加载暂停菜单（也用作主菜单和游戏结束菜单）
	if pause_menu_scene:
		pause_menu = pause_menu_scene.instantiate()
		add_child(pause_menu)
		pause_menu.resume_game.connect(_on_resume_game)
		pause_menu.restart_game.connect(_on_restart_game)
		pause_menu.open_settings.connect(_on_open_settings)
		pause_menu.quit_game.connect(_on_quit_game)
		pause_menu.start_game.connect(_on_start_game_from_menu)

	# 连接设置管理器的语言变化信号
	if has_node("/root/SettingsManager"):
		SettingsManager.language_changed.connect(_on_language_changed)
		_update_texts()

func _hide_game_content():
	"""隐藏游戏内容（玩家、球等）"""
	if game_content:
		game_content.visible = false

func _show_game_content():
	"""显示游戏内容"""
	if game_content:
		game_content.visible = true

func _process(delta):
	# 主菜单背景渐变动画
	if not game_running:
		_update_menu_background(delta)

	if game_paused or (pause_menu and pause_menu.is_paused):
		return

	if not game_running and not game_over_state and not awaiting_revive:
		# 主菜单模式下，不处理键盘/鼠标输入开始游戏
		return

	if game_running:
		var time_slow = SkillManager.get_time_slow_modifier()
		var actual_delta = delta * (1.0 - time_slow)
		score += actual_delta
		$HUD/ScoreLabel.text = "Time: %.3f s" % score

		# 输入采样（前 5 秒检测玩家偏好）
		if score < 5.0 and not input_sample_complete:
			input_sample_timer += delta
			if input_sample_timer >= 0.1:
				input_sample_timer = 0.0
				_sample_input()
		elif score >= 5.0 and not input_sample_complete:
			_determine_input_preference()

		if difficulty_level < max_difficulty:
			time_since_last_difficulty_increase += actual_delta
			if time_since_last_difficulty_increase >= difficulty_interval:
				increase_difficulty()
				time_since_last_difficulty_increase = 0.0

		if SkillManager.has_skill("bomb"):
			bomb_timer += delta
			if bomb_timer >= 10.0:
				activate_bomb()
				bomb_timer = 0.0

		# 清除横条逻辑
		if not clearance_bar_active and not clearance_bar_warning:
			clearance_bar_timer += delta
			if clearance_bar_timer >= clearance_bar_interval:
				clearance_bar_warning = true
				clearance_bar_direction = randi() % 2
				_start_clearance_warning()
		elif clearance_bar_active:
			_update_clearance_bar(delta)

		# 问号块生成计时器（清除横条期间不生成）
		if not clearance_bar_active and not clearance_bar_warning:
			question_block_timer += delta
			if question_block_timer >= current_question_block_interval:
				spawn_question_block()
				question_block_timer = 0.0
				current_question_block_interval = randf_range(question_block_interval_min, question_block_interval_max)

		if awaiting_revive:
			revive_timer += delta
			if revive_timer >= 3.0:
				awaiting_revive = false
				game_over_state = true
				pause_menu.show_game_over_menu()

	if game_over_state:
		# 游戏结束后由菜单处理重启
		pass

func _update_menu_background(delta):
	"""更新主菜单背景渐变"""
	menu_bg_timer += delta
	if menu_bg_timer >= 2.0:  # 每 2 秒切换一次颜色
		menu_bg_timer = 0.0
		current_bg_color_index = (current_bg_color_index + 1) % menu_bg_colors.size()

func toggle_pause():
	if pause_menu:
		pause_menu.toggle_pause()
		game_paused = pause_menu.is_paused

func _on_resume_game():
	game_paused = false

func _on_restart_game():
	restart_game()

func _on_start_game_from_menu():
	start_game()

func _on_open_settings():
	var settings_menu = load("res://settings_menu.tscn").instantiate()
	add_child(settings_menu)
	settings_menu.show_settings()
	settings_menu.back_to_game.connect(func():
		settings_menu.queue_free()
		# 如果是从主菜单打开设置，返回后仍然显示主菜单
		if not game_running and not game_over_state:
			pause_menu.show_main_menu()
		# 如果是从游戏结束菜单打开设置，返回后显示游戏结束菜单
		elif game_over_state:
			pause_menu.show_game_over_menu()
		# 如果是从暂停菜单打开设置，返回后继续显示暂停菜单
		elif game_paused:
			pause_menu.show_pause_menu()
	)

func _on_quit_game():
	get_tree().quit()

func _on_language_changed():
	_update_texts()

func _update_texts():
	if not has_node("/root/SettingsManager"):
		return

	if not game_running and not game_over_state:
		$HUD/MessageLabel.hide()

func _sample_input():
	if Input.is_action_pressed("ui_up") or Input.is_action_pressed("ui_down") or \
	   Input.is_action_pressed("ui_left") or Input.is_action_pressed("ui_right"):
		keyboard_input_count += 1
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		mouse_input_count += 1

func _determine_input_preference():
	input_sample_complete = true
	player_uses_mouse = mouse_input_count > keyboard_input_count
	print("Input preference: mouse=", mouse_input_count, " keyboard=", keyboard_input_count, " uses_mouse=", player_uses_mouse)

func start_game():
	game_running = true
	$HUD/MessageLabel.hide()
	difficulty_level = 1
	time_since_last_difficulty_increase = 0.0
	$HUD/DifficultyLabel.text = "Level: 1"
	skills_dodged_count = 0
	ghost_revive_used = false
	bomb_timer = 0.0
	question_block_timer = 0.0
	clearance_bar_timer = 0.0
	clearance_bar_active = false
	clearance_bar_warning = false
	clearance_bar_position = 0.0
	current_question_block_interval = randf_range(question_block_interval_min, question_block_interval_max)
	SkillManager.clear_all_skills()

	player_uses_mouse = false
	keyboard_input_count = 0
	mouse_input_count = 0
	input_sample_complete = false

	if $HUD.has_node("ClearanceBar"):
		$HUD/ClearanceBar.hide()

	# 显示游戏内容
	_show_game_content()

	# 重置玩家
	if game_content.has_node("Player"):
		game_content.get_node("Player").position = Vector2(400, 300)
		game_content.get_node("Player").scale = Vector2.ONE
		game_content.get_node("Player").set_shield(0)

	if has_node("/root/AudioManager"):
		AudioManager.play_start_game()

	update_spawn_interval()
	$BallTimer.start()

func _start_clearance_warning():
	$HUD/MessageLabel.text = SettingsManager.get_text("clearance_warning")
	$HUD/MessageLabel.show()

	await get_tree().create_timer(clearance_bar_warning_time).timeout
	if game_running:
		clearance_bar_warning = false
		clearance_bar_active = true
		clearance_bar_timer = 0.0
		clearance_bar_position = 0.0
		$HUD/MessageLabel.hide()

func _update_clearance_bar(delta):
	var screen_size = get_viewport_rect().size
	var bar = $HUD/ClearanceBar

	clearance_bar_position += delta / clearance_bar_sweep_time

	if clearance_bar_position >= 1.0:
		clearance_bar_active = false
		clearance_bar_position = 0.0
		bar.hide()
		_show_clearance_complete()
		return

	var sweep_distance = clearance_bar_position * screen_size.y if clearance_bar_direction == 0 else clearance_bar_position * screen_size.x

	if clearance_bar_direction == 0:
		bar.position = Vector2((screen_size.x - screen_size.x * clearance_bar_length_ratio) / 2, sweep_distance)
		bar.size = Vector2(screen_size.x * clearance_bar_length_ratio, clearance_bar_thickness)
	else:
		bar.position = Vector2(sweep_distance, (screen_size.y - screen_size.y * clearance_bar_length_ratio) / 2)
		bar.size = Vector2(clearance_bar_thickness, screen_size.y * clearance_bar_length_ratio)

	bar.show()
	_push_balls_in_bar(sweep_distance)

func _push_balls_in_bar(sweep_distance: float):
	var half_thickness = clearance_bar_thickness / 2.0
	var push_force = 1500.0  # 增加推力
	var balls = get_tree().get_nodes_in_group("balls")

	for ball in balls:
		var should_push = false
		if clearance_bar_direction == 0:
			# 水平方向，检查 Y 坐标
			if ball.position.y >= sweep_distance - half_thickness and ball.position.y <= sweep_distance + half_thickness:
				should_push = true
		else:
			# 垂直方向，检查 X 坐标
			if ball.position.x >= sweep_distance - half_thickness and ball.position.x <= sweep_distance + half_thickness:
				should_push = true

		if should_push:
			var push_direction = Vector2(0, 1) if clearance_bar_direction == 0 else Vector2(1, 0)
			# 直接修改速度，确保球被推开
			ball.linear_velocity = push_direction * push_force
			# 同时施加冲量增加效果
			ball.apply_central_impulse(push_direction * push_force * 0.5)

func _show_clearance_complete():
	$HUD/MessageLabel.text = SettingsManager.get_text("cleared")
	$HUD/MessageLabel.show()
	await get_tree().create_timer(1.0).timeout
	if game_running:
		$HUD/MessageLabel.hide()

func update_spawn_interval():
	var difficulty_factor = max(0.05, 0.5 - (difficulty_level - 1) * 0.05)
	var spawn_modifier = SkillManager.get_spawn_interval_modifier()
	var final_interval = difficulty_factor * (1.0 + spawn_modifier)
	$BallTimer.wait_time = max(0.02, final_interval)

func increase_difficulty():
	difficulty_level += 1
	$HUD/DifficultyLabel.text = "Level: " + str(difficulty_level)

	var excluded_skills = []
	if player_uses_mouse:
		excluded_skills.append("reverse_controls")

	var new_skill = SkillManager.generate_random_skill_with_exclusions(difficulty_level, excluded_skills)
	if new_skill != "":
		SkillManager.acquire_skill(new_skill)
		show_skill_notification(new_skill)

		if has_node("/root/AudioManager"):
			AudioManager.play_level_up()

		if SkillManager.has_skill("regen"):
			if SkillManager.has_skill("shield"):
				SkillManager.active_skills["shield"] = SkillManager.get_skill_stack("shield") + 1
			if game_content.has_node("Player"):
				game_content.get_node("Player").set_shield(SkillManager.get_shield_count())

	update_spawn_interval()

func show_skill_notification(skill_id: String):
	var info = SkillManager.get_skill_info(skill_id)
	var type_indicator = ""
	match info.type:
		"positive":
			type_indicator = "🟢 "
		"negative":
			type_indicator = "🔴 "
		"special":
			type_indicator = "⚡ "

	$HUD/MessageLabel.text = SettingsManager.get_text("level_up") + "\n" + type_indicator + info.name + "\n" + info.description
	$HUD/MessageLabel.show()

	await get_tree().create_timer(1.5).timeout
	if game_running:
		$HUD/MessageLabel.hide()

func activate_bomb():
	var balls = get_tree().get_nodes_in_group("balls")
	for ball in balls:
		ball.queue_free()

	if has_node("/root/AudioManager"):
		AudioManager.play_bomb()

	$HUD/MessageLabel.text = SettingsManager.get_text("bomb")
	$HUD/MessageLabel.show()
	await get_tree().create_timer(1.0).timeout
	if game_running:
		$HUD/MessageLabel.hide()

func _on_ball_timer_timeout():
	if not game_running:
		return
	if clearance_bar_active:
		return

	spawn_ball()

	if difficulty_level >= 5 and randf() > 0.5:
		spawn_ball()

	if difficulty_level >= 8:
		spawn_ball()

	var extra_spawn = SkillManager.get_extra_spawn_count()
	for i in range(extra_spawn):
		spawn_ball()

func spawn_ball():
	var ball = ball_scene.instantiate()
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

	var player_pos = Vector2(400, 300)
	if game_content.has_node("Player"):
		player_pos = game_content.get_node("Player").position

	var direction = (player_pos - spawn_pos).normalized()

	var speed_multiplier = 1.0 + (difficulty_level * 0.03)
	var ball_speed_mod = SkillManager.get_ball_speed_modifier()
	speed_multiplier *= (1.0 + ball_speed_mod)

	var speed = randf_range(200, 400) * speed_multiplier
	ball.linear_velocity = direction * speed

	if SkillManager.has_tornado_trajectory():
		ball.angular_velocity = randf_range(200, 400) * (1 if randf() > 0.5 else -1)

	ball.contact_monitor = true
	ball.max_contacts_reported = 1
	ball.body_entered.connect(_on_ball_body_entered)
	ball.add_to_group("balls")
	if game_content.has_node("Player"):
		ball.player_reference = game_content.get_node("Player")

	add_child(ball)

func _on_ball_dodged():
	skills_dodged_count += 1

	if SkillManager.has_skill("vampire") and skills_dodged_count % 50 == 0:
		difficulty_level = max(1, difficulty_level - 1)
		$HUD/DifficultyLabel.text = "Level: " + str(difficulty_level)

		$HUD/MessageLabel.text = SettingsManager.get_text("vampire")
		$HUD/MessageLabel.show()
		await get_tree().create_timer(1.0).timeout
		if game_running:
			$HUD/MessageLabel.hide()

func _on_ball_body_entered(body):
	if body.name == "Player":
		var shield_count = SkillManager.get_shield_count()
		if shield_count > 0 and not awaiting_revive:
			SkillManager.active_skills["shield"] = shield_count - 1
			if SkillManager.active_skills["shield"] <= 0:
				SkillManager.active_skills.erase("shield")

			if has_node("/root/AudioManager"):
				AudioManager.play_shield_break()

			$HUD/MessageLabel.text = SettingsManager.get_text("shield_broke")
			$HUD/MessageLabel.show()
			await get_tree().create_timer(1.0).timeout
			if game_running:
				$HUD/MessageLabel.hide()

			if game_content.has_node("Player"):
				game_content.get_node("Player").set_shield(SkillManager.active_skills.get("shield", 0))
			return

		if SkillManager.has_skill("ghost") and not ghost_revive_used and not awaiting_revive:
			ghost_revive_used = true
			awaiting_revive = true
			revive_timer = 0.0

			$HUD/MessageLabel.text = SettingsManager.get_text("ghost")
			$HUD/MessageLabel.show()

			var balls = get_tree().get_nodes_in_group("balls")
			for ball in balls:
				ball.queue_free()
			return

		if awaiting_revive:
			awaiting_revive = false
			$HUD/MessageLabel.hide()
			return

		game_over()

func game_over():
	game_running = false
	game_over_state = true
	$BallTimer.stop()

	if has_node("/root/AudioManager"):
		AudioManager.play_game_over()

	# 显示游戏结束菜单
	if pause_menu:
		pause_menu.show_game_over_menu()

func restart_game():
	# 清除屏幕上的所有球
	var balls = get_tree().get_nodes_in_group("balls")
	for ball in balls:
		ball.queue_free()

	# 清除问号块
	var blocks = get_tree().get_nodes_in_group("question_blocks")
	for block in blocks:
		block.queue_free()

	# 完全重置游戏状态
	game_running = false
	game_over_state = false
	game_paused = false
	score = 0.0
	difficulty_level = 1
	time_since_last_difficulty_increase = 0.0
	skills_dodged_count = 0
	ghost_revive_used = false
	bomb_timer = 0.0
	revive_timer = 0.0
	awaiting_revive = false
	question_block_timer = 0.0
	clearance_bar_timer = 0.0
	clearance_bar_active = false
	clearance_bar_warning = false
	clearance_bar_position = 0.0

	# 清除所有技能
	SkillManager.clear_all_skills()

	# 重置玩家状态
	if game_content.has_node("Player"):
		game_content.get_node("Player").position = Vector2(400, 300)
		game_content.get_node("Player").scale = Vector2.ONE
		game_content.get_node("Player").set_shield(0)

	# 重置 UI
	$HUD/ScoreLabel.text = "Time: 0.000 s"
	$HUD/DifficultyLabel.text = "Level: 1"
	$HUD/MessageLabel.hide()
	$HUD/ClearanceBar.hide()

	# 重置计时器
	$BallTimer.stop()

	# 隐藏游戏内容
	_hide_game_content()

	# 隐藏菜单
	if pause_menu:
		pause_menu.hide()

	# 显示主菜单
	if pause_menu:
		pause_menu.show_main_menu()

func spawn_question_block():
	if question_block_scene == null:
		push_warning("Question block scene not assigned!")
		return

	var existing_blocks = get_tree().get_nodes_in_group("question_blocks")
	if existing_blocks.size() > 0:
		return

	var block = question_block_scene.instantiate()

	var screen_size = get_viewport_rect().size
	var buffer = 100
	var random_pos = Vector2(
		randf_range(buffer, screen_size.x - buffer),
		randf_range(buffer, screen_size.y - buffer)
	)

	block.position = random_pos
	add_child(block)

	if has_node("/root/AudioManager"):
		AudioManager.play_question_block()

	$HUD/MessageLabel.text = SettingsManager.get_text("question_block")
	$HUD/MessageLabel.show()
	await get_tree().create_timer(1.0).timeout
	if game_running:
		$HUD/MessageLabel.hide()

func _on_skill_acquired(skill_id: String):
	update_skill_ui()

func _on_skill_removed(skill_id: String):
	update_skill_ui()

func update_skill_ui():
	for child in $HUD/SkillContainer.get_children():
		child.queue_free()

	for skill_id in SkillManager.get_all_active_skills():
		var info = SkillManager.get_skill_info(skill_id)
		var stack = SkillManager.get_skill_stack(skill_id)

		var label = Label.new()
		label.add_theme_font_size_override("font_size", 16)

		var color = Color.WHITE
		match info.type:
			"positive":
				color = Color(0.2, 1.0, 0.2)
			"negative":
				color = Color(1.0, 0.2, 0.2)
			"special":
				color = Color(0.8, 0.2, 1.0)

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
