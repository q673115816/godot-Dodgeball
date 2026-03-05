extends Area2D

## 问号块 - 随机时间生成，玩家接触后获得随机技能

@export var float_speed: float = 30.0  # 漂浮速度
@export var float_amplitude: float = 10.0  # 漂浮幅度

var base_position: Vector2
var time_elapsed: float = 0.0
var collected: bool = false

# 信号
signal block_collected()

func _ready():
	# 连接身体进入信号
	body_entered.connect(_on_body_entered)

	# 记录初始位置
	base_position = position

	# 确保在正确的组中
	add_to_group("question_blocks")

	# 开始闪烁效果
	start_blink_effect()

func start_blink_effect():
	"""启动闪烁效果，让玩家更容易注意到"""
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property($ColorRect, "modulate", Color(1, 1, 0.5, 1), 0.5)
	tween.tween_property($ColorRect, "modulate", Color(1, 0.85, 0, 1), 0.5)

func _process(delta):
	if collected:
		return

	# 漂浮动画
	time_elapsed += delta
	var float_offset = Vector2(
		0,
		sin(time_elapsed * float_speed) * float_amplitude
	)
	position = base_position + float_offset

	# 自动消失计时（30 秒后消失）
	if time_elapsed > 30.0:
		queue_free()

func _on_body_entered(body):
	if collected:
		return

	if body.name == "Player":
		collected = true

		# 获取随机技能
		if has_node("/root/SkillManager"):
			var skill = SkillManager.generate_random_skill(1)
			if skill != "":
				SkillManager.acquire_skill(skill)
				show_skill_message(skill)

		# 发射信号
		block_collected.emit()

		# 播放收集动画
		animate_collection()

func show_skill_message(skill_id: String):
	var info = SkillManager.get_skill_info(skill_id)
	var type_indicator = ""
	match info.type:
		"positive":
			type_indicator = "🟢 "
		"negative":
			type_indicator = "🔴 "
		"special":
			type_indicator = "⚡ "

	# 在主场景中显示消息
	var main = get_tree().current_scene
	if main and main.has_node("HUD/MessageLabel"):
		main.get_node("HUD/MessageLabel").text = "📦 QUESTION BLOCK!\n%s%s\n%s" % [type_indicator, info.name, info.description]
		main.get_node("HUD/MessageLabel").show()

		# 1.5 秒后隐藏
		var timer = main.get_tree().create_timer(1.5)
		timer.timeout.connect(func():
			if main and main.has_node("HUD/MessageLabel") and main.game_running:
				main.get_node("HUD/MessageLabel").hide()
		)

func animate_collection():
	# 缩小并淡出动画
	var tween = create_tween()
	tween.tween_property($ColorRect, "scale", Vector2(0.1, 0.1), 0.3)
	tween.tween_property($ColorRect, "modulate", Color(1, 1, 1, 0), 0.3)
	tween.tween_callback(queue_free)
