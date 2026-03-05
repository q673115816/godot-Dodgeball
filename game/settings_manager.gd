extends Node

## 设置管理器 (Autoload Singleton)
## 负责管理游戏设置，支持中英文切换和音量控制

signal language_changed(locale: String)
signal music_volume_changed(volume: float)
signal sfx_volume_changed(volume: float)

# 当前设置
var current_language: String = "zh_CN"  # zh_CN 或 en_US
var music_volume: float = 0.5
var sfx_volume: float = 0.5

# 语言文本字典
var translations = {
    "zh_CN": {
        "paused": "已暂停",
        "resume": "继续",
        "restart": "重新开始",
        "settings": "设置",
        "quit": "退出",
        "start": "开始游戏",
        "settings_title": "设置",
        "language": "语言",
        "music_volume": "音乐音量",
        "sfx_volume": "音效音量",
        "back": "返回",
        "game_over": "游戏结束",
        "survived_time": "生存时间",
        "max_level": "最高等级",
        "press_to_start": "按方向键\n或触摸开始",
        "level_up": "升级!",
        "shield_broke": "护盾破碎!",
        "bomb": "炸弹!\n所有球已清除!",
        "vampire": "吸血!\n等级降低!",
        "ghost": "幽灵!\n你有 3 秒复活时间!",
        "cleared": "已清除!",
        "question_block": "❓ 问号块出现!\n找到它!",
        "clearance_warning": "⚠️ 清除横条!\n准备好!",
        "main_menu_title": "躲避球",
    },
    "en_US": {
        "paused": "PAUSED",
        "resume": "RESUME",
        "restart": "RESTART",
        "settings": "SETTINGS",
        "quit": "QUIT",
        "start": "START GAME",
        "settings_title": "SETTINGS",
        "language": "Language",
        "music_volume": "Music Volume",
        "sfx_volume": "SFX Volume",
        "back": "BACK",
        "game_over": "GAME OVER",
        "survived_time": "Survived",
        "max_level": "Max Level",
        "press_to_start": "Press Arrow Keys\nor Touch to Start",
        "level_up": "LEVEL UP!",
        "shield_broke": "SHIELD BROKE!",
        "bomb": "BOMB!\nAll balls cleared!",
        "vampire": "VAMPIRE!\nLevel decreased!",
        "ghost": "GHOST!\n3 seconds to revive!",
        "cleared": "CLEARED!",
        "question_block": "❓ QUESTION BLOCK!\nFind it!",
        "clearance_warning": "⚠️ CLEARANCE BAR!\nGet ready!",
        "main_menu_title": "DODGEBALL",
    }
}

func _ready():
    _load_settings()
    _apply_audio_buses()

func _load_settings():
    """从配置文件加载设置"""
    var config = ConfigFile.new()
    var err = config.load("user://settings.cfg")

    if err == OK:
        current_language = config.get_value("game", "language", "zh_CN")
        music_volume = config.get_value("audio", "music_volume", 0.5)
        sfx_volume = config.get_value("audio", "sfx_volume", 0.5)
    else:
        # 使用默认设置
        _save_settings()

func _save_settings():
    """保存设置到配置文件"""
    var config = ConfigFile.new()
    config.set_value("game", "language", current_language)
    config.set_value("audio", "music_volume", music_volume)
    config.set_value("audio", "sfx_volume", sfx_volume)
    config.save("user://settings.cfg")

func _apply_audio_buses():
    """应用音频总线音量"""
    AudioServer.set_bus_volume_db(0, linear_to_db(music_volume))
    AudioServer.set_bus_volume_db(1, linear_to_db(sfx_volume))

func get_text(key: String) -> String:
    """获取翻译文本"""
    if translations.has(current_language):
        return translations[current_language].get(key, key)
    return key

func set_language(lang: String):
    """设置语言"""
    current_language = lang
    _save_settings()
    language_changed.emit(lang)

func set_music_volume(volume: float):
    """设置音乐音量 (0.0 - 1.0)"""
    music_volume = clamp(volume, 0.0, 1.0)
    _apply_audio_buses()
    _save_settings()
    music_volume_changed.emit(music_volume)

func set_sfx_volume(volume: float):
    """设置音效音量 (0.0 - 1.0)"""
    sfx_volume = clamp(volume, 0.0, 1.0)
    _apply_audio_buses()
    _save_settings()
    sfx_volume_changed.emit(sfx_volume)

func get_available_languages() -> Array:
    """获取可用语言列表"""
    return ["zh_CN", "en_US"]

func get_language_name(lang: String) -> String:
    """获取语言名称"""
    match lang:
        "zh_CN":
            return "中文"
        "en_US":
            return "English"
    return lang
