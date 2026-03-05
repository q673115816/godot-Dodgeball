extends CanvasLayer

## 通用菜单（主菜单/暂停菜单/游戏结束菜单）
## 处理游戏暂停和菜单显示

signal resume_game
signal restart_game
signal open_settings
signal quit_game
signal start_game

# 菜单模式：main_menu, paused, game_over
enum MenuMode { MAIN_MENU, PAUSED, GAME_OVER }
var current_mode: MenuMode = MenuMode.MAIN_MENU

# 主菜单背景渐变动画
var bg_timer = 0.0
var bg_colors = [
	Color(0.15, 0.1, 0.3, 0.9),   # 紫蓝色
	Color(0.2, 0.1, 0.2, 0.9),   # 紫红色
	Color(0.1, 0.2, 0.25, 0.9),  # 青蓝色
	Color(0.25, 0.15, 0.15, 0.9) # 红棕色
]
var current_color_index = 0
var color_transition = 0.0

@onready var pause_panel = $PausePanel
@onready var title_label = $PausePanel/VBoxContainer/TitleLabel
@onready var start_button = $PausePanel/VBoxContainer/StartButton
@onready var resume_button = $PausePanel/VBoxContainer/ResumeButton
@onready var restart_button = $PausePanel/VBoxContainer/RestartButton
@onready var settings_button = $PausePanel/VBoxContainer/SettingsButton
@onready var quit_button = $PausePanel/VBoxContainer/QuitButton
@onready var bg_color_rect = $ColorRect

var is_paused = false

func _ready():
	# 连接按钮信号
	if start_button:
		start_button.pressed.connect(_on_start_pressed)
	if resume_button:
		resume_button.pressed.connect(_on_resume_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	# 初始显示主菜单
	show_main_menu()

	# 连接设置管理器进行文本更新
	if has_node("/root/SettingsManager"):
		SettingsManager.language_changed.connect(_update_texts)
		_update_texts()

func _process(delta):
	# 只在主菜单模式下更新背景动画
	if current_mode == MenuMode.MAIN_MENU:
		_update_background(delta)

func _update_background(delta):
	"""更新主菜单背景渐变动画"""
	bg_timer += delta
	color_transition += delta * 0.5  # 过渡速度

	if color_transition >= 1.0:
		color_transition = 0.0
		current_color_index = (current_color_index + 1) % bg_colors.size()

	# 平滑过渡颜色
	var next_color_index = (current_color_index + 1) % bg_colors.size()
	var from_color = bg_colors[current_color_index]
	var to_color = bg_colors[next_color_index]
	bg_color_rect.color = from_color.lerp(to_color, color_transition)

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		if current_mode == MenuMode.MAIN_MENU:
			return  # 主菜单不处理 ESC
		elif current_mode == MenuMode.GAME_OVER:
			return  # 游戏结束菜单不处理 ESC
		else:
			toggle_pause()

func show_main_menu():
	"""显示主菜单"""
	current_mode = MenuMode.MAIN_MENU
	is_paused = false
	get_tree().paused = false

	# 更新按钮显示
	if start_button:
		start_button.show()
	if resume_button:
		resume_button.hide()
	if restart_button:
		restart_button.hide()
	if settings_button:
		settings_button.show()
	if quit_button:
		quit_button.show()

	# 背景设为半透明渐变色
	if bg_color_rect:
		bg_color_rect.color = bg_colors[0]

	# 更新文本
	_update_texts()

	show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func show_pause_menu():
	"""显示暂停菜单"""
	current_mode = MenuMode.PAUSED
	is_paused = true
	get_tree().paused = true

	# 更新按钮显示
	if start_button:
		start_button.hide()
	if resume_button:
		resume_button.show()
	if restart_button:
		restart_button.show()
	if settings_button:
		settings_button.show()
	if quit_button:
		quit_button.show()

	# 背景设为半透明黑色
	if bg_color_rect:
		bg_color_rect.color = Color(0, 0, 0, 0.7)

	# 更新文本
	_update_texts()

	show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func show_game_over_menu():
	"""显示游戏结束菜单"""
	current_mode = MenuMode.GAME_OVER
	is_paused = true
	get_tree().paused = true

	# 更新按钮显示
	if start_button:
		start_button.hide()
	if resume_button:
		resume_button.hide()
	if restart_button:
		restart_button.show()
	if settings_button:
		settings_button.hide()
	if quit_button:
		quit_button.show()

	# 背景设为灰色（游戏结束）
	if bg_color_rect:
		bg_color_rect.color = Color(0.2, 0.2, 0.2, 0.85)

	# 更新文本
	_update_texts()

	show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func toggle_pause():
	if is_paused:
		resume()
	else:
		pause()

func pause():
	is_paused = true
	get_tree().paused = true
	show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func resume():
	is_paused = false
	get_tree().paused = false
	hide()
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

func _on_start_pressed():
	hide()
	start_game.emit()

func _on_resume_pressed():
	resume()
	resume_game.emit()

func _on_restart_pressed():
	resume()
	restart_game.emit()

func _on_settings_pressed():
	# 隐藏当前菜单背景
	hide()
	open_settings.emit()

func _on_quit_pressed():
	quit_game.emit()

func _update_texts():
	if not has_node("/root/SettingsManager"):
		return

	# 根据模式更新标题
	match current_mode:
		MenuMode.MAIN_MENU:
			title_label.text = SettingsManager.get_text("main_menu_title")
		MenuMode.PAUSED:
			title_label.text = SettingsManager.get_text("paused")
		MenuMode.GAME_OVER:
			title_label.text = SettingsManager.get_text("game_over")

	if start_button:
		start_button.text = SettingsManager.get_text("start")
	if resume_button:
		resume_button.text = SettingsManager.get_text("resume")
	restart_button.text = SettingsManager.get_text("restart")
	settings_button.text = SettingsManager.get_text("settings")
	quit_button.text = SettingsManager.get_text("quit")
