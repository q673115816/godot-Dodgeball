extends CanvasLayer

## 设置菜单
## 处理设置显示和修改

signal back_to_game

@onready var settings_panel = $SettingsPanel
@onready var language_button = $SettingsPanel/VBoxContainer/LanguageHBox/LanguageButton
@onready var music_slider = $SettingsPanel/VBoxContainer/MusicHBox/MusicSlider
@onready var sfx_slider = $SettingsPanel/VBoxContainer/SFXHBox/SFXSlider
@onready var back_button = $SettingsPanel/VBoxContainer/BackButton

func _ready():
    # 连接按钮信号
    back_button.pressed.connect(_on_back_pressed)

    # 初始化语言选项
    _setup_language_button()

    # 初始化滑块
    music_slider.value = SettingsManager.music_volume * 100
    sfx_slider.value = SettingsManager.sfx_volume * 100

    # 连接滑块信号
    music_slider.value_changed.connect(_on_music_value_changed)
    sfx_slider.value_changed.connect(_on_sfx_value_changed)

    # 初始隐藏
    hide()

    # 连接设置管理器进行文本更新
    SettingsManager.language_changed.connect(_update_texts)
    _update_texts()

func _setup_language_button():
    """设置语言选择按钮"""
    # 清除现有选项
    language_button.clear()

    # 添加语言选项
    var languages = SettingsManager.get_available_languages()
    for i in range(languages.size()):
        var lang = languages[i]
        var lang_name = SettingsManager.get_language_name(lang)
        language_button.add_item(lang_name, i)

    # 设置当前语言
    var current_lang = SettingsManager.current_language
    for i in range(languages.size()):
        if languages[i] == current_lang:
            language_button.selected = i
            break

    # 连接选择信号
    language_button.item_selected.connect(_on_language_selected)

func _update_texts():
    """更新界面文本"""
    $SettingsPanel/VBoxContainer/TitleLabel.text = SettingsManager.get_text("settings_title")
    $SettingsPanel/VBoxContainer/LanguageHBox/Label.text = SettingsManager.get_text("language")
    $SettingsPanel/VBoxContainer/MusicHBox/Label.text = SettingsManager.get_text("music_volume")
    $SettingsPanel/VBoxContainer/SFXHBox/Label.text = SettingsManager.get_text("sfx_volume")
    back_button.text = SettingsManager.get_text("back")

func show_settings():
    show()
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func hide_settings():
    hide()
    Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

func _on_language_selected(index):
    """处理语言选择"""
    var languages = SettingsManager.get_available_languages()
    if index >= 0 and index < languages.size():
        SettingsManager.set_language(languages[index])
        _update_texts()

func _on_music_value_changed(value):
    """处理音乐滑块变化"""
    SettingsManager.set_music_volume(value / 100.0)

func _on_sfx_value_changed(value):
    """处理音效滑块变化"""
    SettingsManager.set_sfx_volume(value / 100.0)

func _on_back_pressed():
    back_to_game.emit()
    hide_settings()
