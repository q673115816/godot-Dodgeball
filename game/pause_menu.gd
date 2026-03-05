extends CanvasLayer

## 暂停菜单
## 处理游戏暂停和菜单显示

signal resume_game
signal restart_game
signal open_settings
signal quit_game

@onready var pause_panel = $PausePanel
@onready var resume_button = $PausePanel/VBoxContainer/ResumeButton
@onready var restart_button = $PausePanel/VBoxContainer/RestartButton
@onready var settings_button = $PausePanel/VBoxContainer/SettingsButton
@onready var quit_button = $PausePanel/VBoxContainer/QuitButton

var is_paused = false

func _ready():
    # 连接按钮信号
    resume_button.pressed.connect(_on_resume_pressed)
    restart_button.pressed.connect(_on_restart_pressed)
    settings_button.pressed.connect(_on_settings_pressed)
    quit_button.pressed.connect(_on_quit_pressed)

    # 初始隐藏
    hide()

    # 连接设置管理器进行文本更新
    if has_node("/root/SettingsManager"):
        SettingsManager.language_changed.connect(_update_texts)
        _update_texts()

func _input(event):
    if event.is_action_pressed("ui_cancel"):
        toggle_pause()

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

func _on_resume_pressed():
    resume()
    resume_game.emit()

func _on_restart_pressed():
    resume()
    restart_game.emit()

func _on_settings_pressed():
    open_settings.emit()

func _on_quit_pressed():
    quit_game.emit()

func _update_texts():
    if not has_node("/root/SettingsManager"):
        return

    $PausePanel/VBoxContainer/TitleLabel.text = SettingsManager.get_text("paused")
    resume_button.text = SettingsManager.get_text("resume")
    restart_button.text = SettingsManager.get_text("restart")
    settings_button.text = SettingsManager.get_text("settings")
    quit_button.text = SettingsManager.get_text("quit")
