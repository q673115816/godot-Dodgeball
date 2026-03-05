# 8bit 音效和音乐生成指南

## 如何生成音效

1. 在 Godot 编辑器中打开项目
2. 创建一个新场景，添加一个 Node 节点
3. 将 `sfx_generator.gd` 脚本附加到该节点
4. 运行场景

音效将自动生成到 `audio/sfx/` 目录。

## 如何生成背景音乐

1. 在 Godot 编辑器中打开项目
2. 创建一个新场景，添加一个 Node 节点
3. 将 `music_generator.gd` 脚本附加到该节点
4. 运行场景

音乐将自动生成到 `audio/music/` 目录。

## 手动创建音频文件

如果自动生成不起作用，可以：

1. 使用在线 8bit 音乐生成器：
   - https://sfxr.me/
   - https://www.bfxr.net/

2. 下载免费的 8bit 音乐资源：
   - https://opengameart.org/

3. 将音频文件保存为以下格式：
   - 音乐：`audio/music/game_music.ogg` 或 `.wav`
   - 音效：`audio/sfx/*.wav`

## 需要的音效文件列表

- `level_up.wav` - 升级音效
- `question_block.wav` - 问号块出现音效
- `shield_break.wav` - 护盾破碎音效
- `bomb.wav` - 炸弹音效
- `clearance.wav` - 清除横条音效
- `game_over.wav` - 游戏结束音效
- `start_game.wav` - 游戏开始音效

## 需要的音乐文件

- `game_music.ogg` - 8bit 背景音乐（循环）
