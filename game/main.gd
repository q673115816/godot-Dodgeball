extends Node2D

@export var ball_scene: PackedScene # 在编辑器中拖入 ball.tscn
var score: float = 0.0 # 改为浮点数以支持毫秒
var game_running = false
var game_over_state = false

# 难度控制变量
var difficulty_level = 1
var max_difficulty = 10
var time_since_last_difficulty_increase = 0.0
var difficulty_interval = 5.0 # 每5秒增加一次难度

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

func _process(delta):
	# 游戏未开始且未结束时，检测输入以开始游戏
	if not game_running and not game_over_state:
		# 键盘开始
		if Input.is_action_pressed("ui_up") or Input.is_action_pressed("ui_down") or \
		   Input.is_action_pressed("ui_left") or Input.is_action_pressed("ui_right"):
			start_game()
		# 触摸/鼠标点击开始
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			start_game()
	
	# 游戏进行中，更新时间与难度
	if game_running:
		score += delta
		$HUD/ScoreLabel.text = "Time: %.3f s" % score
		
		# 难度提升逻辑
		if difficulty_level < max_difficulty:
			time_since_last_difficulty_increase += delta
			if time_since_last_difficulty_increase >= difficulty_interval:
				increase_difficulty()
				time_since_last_difficulty_increase = 0.0

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
	
	# 初始生成间隔 0.5秒
	$BallTimer.wait_time = 0.5
	$BallTimer.start()

func increase_difficulty():
	difficulty_level += 1
	$HUD/DifficultyLabel.text = "Level: " + str(difficulty_level)
	
	# 随着难度增加，缩短生成间隔
	# 难度1: 0.5s -> 难度10: 0.05s (线性递减，或者你可以用其他曲线)
	# 简单算法：每升一级减少 0.05s
	var new_wait_time = max(0.05, 0.5 - (difficulty_level - 1) * 0.05)
	$BallTimer.wait_time = new_wait_time
	
	# 可选：如果你想更疯狂，可以同时增加单次生成的数量，或者让球速更快
	# 目前只通过加快频率来实现“更多球”

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

func spawn_ball():
	var ball = ball_scene.instantiate()
	
	# 决定生成球的边 (0:上, 1:下, 2:左, 3:右)
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
	var speed_multiplier = 1.0 + (difficulty_level * 0.05) # 每级增加 5% 速度
	var speed = randf_range(200, 400) * speed_multiplier
	ball.linear_velocity = direction * speed
	
	ball.contact_monitor = true
	ball.max_contacts_reported = 1
	ball.body_entered.connect(_on_ball_body_entered)
	
	add_child(ball)

# 该函数不再用于计分
func _on_score_timer_timeout():
	pass

func _on_ball_body_entered(body):
	if body.name == "Player":
		game_over()

func game_over():
	game_running = false
	game_over_state = true
	$BallTimer.stop()
	$HUD/MessageLabel.text = "GAME OVER\nSurvived: %.3f s\nMax Level: %d\nPress R or Touch" % [score, difficulty_level]
	$HUD/MessageLabel.show()

func restart_game():
	get_tree().reload_current_scene()
