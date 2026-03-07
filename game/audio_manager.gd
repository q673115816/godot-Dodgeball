extends Node

## 音频管理器 (Autoload Singleton) - MVP 版本
## 负责播放游戏音乐和音效

@export var music_volume: float = 0.5
@export var sfx_volume: float = 0.5

# 音效缓存
var sfx_cache: Dictionary = {}

# 当前播放的音乐
var current_music: AudioStreamPlayer = null

func _ready():
    # 预加载音效
    _preload_sfx()

func _preload_sfx():
    """预加载常用音效"""
    var sfx_list = [
        "res://audio/sfx/level_up.wav",
        "res://audio/sfx/question_block.wav",
        "res://audio/sfx/shield_break.wav",
        "res://audio/sfx/bomb.wav",
        "res://audio/sfx/clearance.wav",
        "res://audio/sfx/game_over.wav",
        "res://audio/sfx/start_game.wav",
    ]

    for sfx_path in sfx_list:
        if ResourceLoader.exists(sfx_path):
            var stream = load(sfx_path)
            if stream:
                sfx_cache[sfx_path] = stream

func play_music(music_path: String, loop: bool = true):
    """播放背景音乐"""
    if current_music:
        current_music.stop()
        current_music.queue_free()

    if not ResourceLoader.exists(music_path):
        return

    var stream = load(music_path)
    if not stream:
        return

    current_music = AudioStreamPlayer.new()
    current_music.stream = stream
    current_music.bus = "Music"
    current_music.volume_db = linear_to_db(music_volume)

    if loop:
        current_music.loop = true

    add_child(current_music)
    current_music.play()

func stop_music():
    """停止背景音乐"""
    if current_music:
        current_music.stop()

func play_sfx(sfx_name: String, volume_scale: float = 1.0):
    """播放音效"""
    var sfx_path = "res://audio/sfx/" + sfx_name + ".wav"

    var stream: AudioStream
    if sfx_cache.has(sfx_path):
        stream = sfx_cache[sfx_path]
    elif ResourceLoader.exists(sfx_path):
        stream = load(sfx_path)
        sfx_cache[sfx_path] = stream
    else:
        sfx_path = sfx_path.replace(".wav", ".mp3")
        if ResourceLoader.exists(sfx_path):
            stream = load(sfx_path)
            sfx_cache[sfx_path] = stream

    if not stream:
        return

    var player = AudioStreamPlayer.new()
    player.stream = stream
    player.bus = "SFX"
    player.volume_db = linear_to_db(sfx_volume * volume_scale)

    add_child(player)
    player.play()

    player.finished.connect(func():
        player.queue_free()
    )

# 便捷方法
func play_level_up():
    play_sfx("level_up")

func play_question_block():
    play_sfx("question_block")

func play_shield_break():
    play_sfx("shield_break")

func play_bomb():
    play_sfx("bomb")

func play_clearance():
    play_sfx("clearance")

func play_game_over():
    play_sfx("game_over")

func play_start_game():
    play_sfx("start_game")
