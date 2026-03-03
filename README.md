# Godot Dodgeball Game (躲避球)

[中文](#中文) | [English](#english)

---

<a name="中文"></a>
## 🇨🇳 中文说明

一个使用 Godot 4.x 开发的快节奏 2D 躲避球游戏。玩家需要操控方块躲避四面八方飞来的球，坚持时间越久，难度越高。

### 🎮 游戏玩法

*   **目标**：尽可能长时间地存活，避免被红球击中。
*   **机制**：
    *   球会从屏幕上下左右四个方向生成，并直线飞向玩家。
    *   随着时间推移，难度等级 (Level) 会逐渐提升。
    *   高难度下，球的生成频率极快，且会同时生成多个球。

### 🕹️ 操作说明

支持 **PC (键盘/鼠标)** 和 **移动端 (触摸)**。

| 平台 | 操作方式 | 说明 |
| :--- | :--- | :--- |
| **PC (键盘)** | **方向键 (↑ ↓ ← →)** | 控制玩家上下左右移动 |
| **PC (鼠标)** | **左键点击/拖动** | 玩家会跟随鼠标位置移动 |
| **移动端** | **单指触摸/拖动** | 玩家会跟随手指位置移动 |
| **开始游戏** | 按任意方向键 / 点击屏幕 | 在主界面激活游戏 |
| **重新开始** | 按 **R** 键 / 点击屏幕 | 游戏结束后重置 |

### 🚀 游戏特色

1.  **全方位弹幕**：球体从屏幕四周生成，具有追踪玩家初始位置的特性。
2.  **动态难度系统**：
    *   共 10 个难度等级。
    *   每存活 5 秒提升一级。
    *   等级越高，球速越快，生成间隔越短（最快 0.05秒/个）。
    *   Level 5+ 开始出现多重生成。
3.  **Roguelike 技能系统** 🆕：
    *   每提升一个 Level 随机获得一个技能。
    *   技能分为增益、减益、特殊三类。
    *   技能可能提升或降低游戏难度，增加策略性和重复可玩性。
4.  **精准计时**：UI 显示精确到毫秒的生存时间。
5.  **多平台兼容**：一套代码完美适配桌面端和移动端操作。

### 🛠️ 开发环境

*   **引擎版本**：Godot 4.x
*   **语言**：GDScript
*   **项目结构**：
    *   `main.tscn` / `main.gd`：游戏主循环、UI、生成逻辑。
    *   `player.tscn` / `player.gd`：玩家控制、边界限制。
    *   `ball.tscn` / `ball.gd`：球体物理、自动销毁。
    *   `skill_manager.gd`：Roguelike 技能系统管理器（单例）。
    *   `project.godot`：项目配置（包含 Autoload 单例配置）。

### 🏗️ 项目架构 (Monorepo)

本项目采用 Monorepo 架构，将源码与发布产物分离：

*   **`game/`**: 游戏核心源码（GDScript, 场景等）。
*   **`apps/web/`**: Web 版本发布仓库（包含构建后的 HTML/JS/WASM）。
*   **`build.sh`**: 自动化构建脚本，将 `game/` 的内容构建到 `apps/web/`。

这种结构允许将 `apps/web` 作为一个独立的 Git 仓库推送到 Vercel 等平台进行部署，而无需上传庞大的工程源文件。

### 🚀 部署流程 (Web)

1.  **构建**: 运行 `./build.sh "Web"` 生成最新 Web 包。
2.  **提交发布**:
    ```bash
    cd apps/web
    git add .
    git commit -m "Update build"
    git push origin main  # 推送到您的部署仓库
    ```

### 📦 自动打包脚本

本项目提供了一个 Shell 脚本，用于一键导出所有平台的构建版本。

#### 🔧 环境准备
1.  **Godot 命令行工具**：确保 `godot` 在您的环境变量中。
2.  **导出模板**：如果构建失败提示缺失模板，请运行安装脚本：
    ```bash
    chmod +x install_templates.sh
    ./install_templates.sh
    ```

#### 使用方法
运行项目根目录下的 `build.sh`：

```bash
# 赋予执行权限
chmod +x build.sh

# 导出所有平台 (Web, Windows, macOS, Linux, Android)
./build.sh

# 仅导出特定平台
./build.sh "Web"
./build.sh "Android"
```

构建产物将生成在 `builds/` 目录下。

### 📦 如何运行

1.  下载并安装 [Godot Engine 4.x](https://godotengine.org/)。
2.  导入本项目文件夹。
3.  运行主场景 (`main.tscn`) 即可开始游戏。
4.  **导出移动端**：在 `项目 -> 导出` 中添加 Android 或 iOS 预设即可打包。

---

<a name="english"></a>
## 🇺🇸 English Description

A fast-paced 2D dodgeball game developed with Godot 4.x. Players control a block to dodge balls coming from all directions. The longer you survive, the harder it gets.

### 🎮 Gameplay

*   **Goal**: Survive as long as possible and avoid being hit by red balls.
*   **Mechanics**:
    *   Balls spawn from all four sides of the screen and fly straight towards the player.
    *   The Difficulty Level increases over time.
    *   At high levels, balls spawn extremely fast, and multiple balls can spawn at once.

### 🕹️ Controls

Supports **PC (Keyboard/Mouse)** and **Mobile (Touch)**.

| Platform | Controls | Description |
| :--- | :--- | :--- |
| **PC (Keyboard)** | **Arrow Keys (↑ ↓ ← →)** | Move the player up, down, left, or right |
| **PC (Mouse)** | **Left Click / Drag** | Player follows the mouse cursor position |
| **Mobile** | **Touch / Drag** | Player follows your finger position |
| **Start Game** | Any Arrow Key / Tap Screen | Activate the game from the main screen |
| **Restart** | Press **R** / Tap Screen | Reset the game after Game Over |

### 🚀 Features

1.  **Omnidirectional Barrage**: Balls spawn from all screen edges, targeting the player's position.
2.  **Dynamic Difficulty System**:
    *   10 Difficulty Levels in total.
    *   Level increases every 5 seconds survived.
    *   Higher levels mean faster balls and shorter spawn intervals (up to 0.05s/ball).
    *   Multi-spawn events start from Level 5+.
3.  **Precision Timing**: UI displays survival time with millisecond precision.
4.  **Multi-Platform**: One codebase perfectly adapted for both Desktop and Mobile controls.

### 🛠️ Development Environment

*   **Engine Version**: Godot 4.x
*   **Language**: GDScript
*   **Project Structure**:
    *   `main.tscn` / `main.gd`: Game loop, UI, spawning logic.
    *   `player.tscn` / `player.gd`: Player control, boundary clamping.
    *   `ball.tscn` / `ball.gd`: Ball physics, auto-destruction.

### 📦 Automated Build Script

This project includes a shell script for one-click exporting to all platforms.

#### 🔧 Setup
1.  **Godot CLI**: Ensure `godot` is in your PATH.
2.  **Export Templates**: Run the installer script if templates are missing:
    ```bash
    chmod +x install_templates.sh
    ./install_templates.sh
    ```

#### Usage
Run `build.sh` in the project root:

```bash
# Make script executable
chmod +x build.sh

# Export for all platforms (Web, Windows, macOS, Linux, Android)
./build.sh

# Export for a specific platform
./build.sh "Web"
./build.sh "Android"
```

Build artifacts will be generated in the `builds/` directory.

### 📦 How to Run

1.  Download and install [Godot Engine 4.x](https://godotengine.org/).
2.  Import this project folder.
3.  Run the main scene (`main.tscn`) to start playing.
4.  **Mobile Export**: Add Android or iOS presets in `Project -> Export` to build for mobile devices.

---
*Created with ❤️ by Godot & Trae AI*
