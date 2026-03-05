extends Node

## 8bit 背景音乐生成器
## 生成一个简单的 8bit 风格的循环背景音乐

func _ready():
    print("Music Generator")
    print("---------------")
    generate_and_save_music()
    queue_free()

func generate_and_save_music():
    """生成并保存 8bit 背景音乐"""
    var sample_rate = 44100
    var duration = 60.0  # 60 秒循环
    var total_samples = int(sample_rate * duration)
    var samples = PackedVector2Array()
    samples.resize(total_samples)

    # 简单的 8bit 音乐序列（C 大调琶音）
    var notes = [261.63, 329.63, 392.00, 523.25, 392.00, 329.63]  # C-E-G-C-G-E
    var note_duration = 0.25  # 每个音符 0.25 秒
    var samples_per_note = int(sample_rate * note_duration)

    var current_sample = 0
    while current_sample < total_samples:
        for note_freq in notes:
            if current_sample >= total_samples:
                break

            # 生成方波
            var period = sample_rate / note_freq
            for i in range(samples_per_note):
                if current_sample + i >= total_samples:
                    break
                var phase = fmod(float(i), period) / period
                var sample = 0.3 if phase < 0.5 else -0.3

                # 添加简单的包络
                if i < 100:
                    sample *= float(i) / 100.0

                samples[current_sample + i] = Vector2(sample, sample)

            current_sample += samples_per_note

    # 保存为 WAV 文件
    _save_wav("user://audio/music/game_music.wav", samples)
    print("Generated: game_music.wav")

func _save_wav(file_path: String, samples: PackedVector2Array):
    """保存为 WAV 文件"""
    var file = FileAccess.open(file_path, FileAccess.WRITE)

    if not file:
        print("Error: Cannot create file: %s" % file_path)
        return

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
    file.store_32(16)
    file.store_16(1)
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
        left = clamp(left, -32768, 32767)
        right = clamp(right, -32768, 32767)
        file.store_16(left)
        file.store_16(right)

    file.close()
