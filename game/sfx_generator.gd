extends Node

## 8bit 音效生成器
## 在 Godot 中运行此脚本生成简单的 8bit 风格音效
## 使用方法：在 Godot 编辑器中打开项目，将此节点添加到场景树并运行

# 音效配置
var sfx_configs = {
    "level_up": {
        "type": "square",
        "start_freq": 440,
        "end_freq": 880,
        "duration": 0.3,
        "volume": 0.5
    },
    "question_block": {
        "type": "square",
        "start_freq": 880,
        "end_freq": 1100,
        "duration": 0.2,
        "volume": 0.4
    },
    "shield_break": {
        "type": "noise",
        "start_freq": 200,
        "end_freq": 100,
        "duration": 0.4,
        "volume": 0.6
    },
    "bomb": {
        "type": "noise",
        "start_freq": 150,
        "end_freq": 50,
        "duration": 0.8,
        "volume": 0.8
    },
    "clearance": {
        "type": "saw",
        "start_freq": 600,
        "end_freq": 300,
        "duration": 0.5,
        "volume": 0.5
    },
    "game_over": {
        "type": "square",
        "start_freq": 400,
        "end_freq": 100,
        "duration": 1.0,
        "volume": 0.6
    },
    "start_game": {
        "type": "square",
        "start_freq": 440,
        "end_freq": 880,
        "duration": 0.4,
        "volume": 0.5
    },
    "powerup": {
        "type": "sine",
        "start_freq": 523,
        "end_freq": 1047,
        "duration": 0.5,
        "volume": 0.4
    }
}

func _ready():
    print("8bit SFX Generator")
    print("------------------")
    print("Generating sounds...")

    # 生成所有音效
    for sfx_name in sfx_configs:
        generate_and_save_sfx(sfx_name, sfx_configs[sfx_name])

    print("Done! Check audio/sfx/ folder")
    queue_free()

func generate_and_save_sfx(name: String, config: Dictionary):
    """生成并保存音效"""
    var audio_buffer = _generate_sfx_buffer(config)

    # 保存为 WAV 文件
    var file_path = "user://audio/sfx/%s.wav" % name
    _save_wav(file_path, audio_buffer)

    print("Generated: %s" % name)

func _generate_sfx_buffer(config: Dictionary) -> PackedVector2Array:
    """生成音效数据"""
    var sample_rate = 44100
    var duration = config.duration
    var total_samples = int(sample_rate * duration)
    var samples = PackedVector2Array()
    samples.resize(total_samples)

    var start_freq = config.start_freq
    var end_freq = config.end_freq
    var freq_step = (end_freq - start_freq) / total_samples
    var volume = config.volume

    var phase = 0.0
    var current_freq = start_freq

    for i in range(total_samples):
        var t = float(i) / sample_rate
        current_freq = start_freq + freq_step * i

        var sample = 0.0

        match config.type:
            "square":
                # 方波
                var period = 1.0 / current_freq
                var phase_in_period = fmod(t, period) / period
                sample = 1.0 if phase_in_period < 0.5 else -1.0

            "saw":
                # 锯齿波
                var period = 1.0 / current_freq
                sample = 2.0 * (fmod(t, period) / period) - 1.0

            "sine":
                # 正弦波
                sample = sin(2 * PI * current_freq * t)

            "noise":
                # 噪声
                sample = randf_range(-1.0, 1.0)

        # 应用包络（避免爆音）
        var envelope = 1.0
        var attack = int(sample_rate * 0.01)  # 10ms 攻击
        var release = int(sample_rate * 0.05)  # 50ms 释放

        if i < attack:
            envelope = float(i) / attack
        elif i > total_samples - release:
            envelope = float(total_samples - i) / release

        sample *= envelope * volume

        samples[i] = Vector2(sample, sample)

    return samples

func _save_wav(file_path: String, samples: PackedVector2Array):
    """保存为 WAV 文件"""
    var file = FileAccess.open(file_path, FileAccess.WRITE)

    if not file:
        print("Error: Cannot create file: %s" % file_path)
        return

    # WAV 文件头参数
    var sample_rate = 44100
    var num_channels = 2
    var bits_per_sample = 16
    var byte_rate = sample_rate * num_channels * bits_per_sample / 8
    var block_align = num_channels * bits_per_sample / 8
    var data_size = samples.size() * num_channels * bits_per_sample / 8

    # RIFF 头
    file.store_string("RIFF")
    file.store_32(int(data_size) + 36)
    file.store_string("WAVE")

    # fmt 子块
    file.store_string("fmt ")
    file.store_32(16)  # 子块大小（PCM 为 16）
    file.store_16(1)   # 音频格式（1 = PCM）
    file.store_16(num_channels)
    file.store_32(sample_rate)
    file.store_32(byte_rate)
    file.store_16(block_align)
    file.store_16(bits_per_sample)

    # data 子块
    file.store_string("data")
    file.store_32(int(data_size))

    # 写入样本数据
    for sample in samples:
        var left = int(sample.x * 32767)
        var right = int(sample.y * 32767)
        # 限制范围
        left = clamp(left, -32768, 32767)
        right = clamp(right, -32768, 32767)
        file.store_16(left)
        file.store_16(right)

    file.close()
    print("Saved: %s" % file_path)
