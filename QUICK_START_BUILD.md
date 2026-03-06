# 快速开始：构建和导出游戏

## ✅ 脚本已修复

构建脚本 `build.sh` 现在已在 Windows 上正常工作。

## 🚀 使用方法

### 导出 Web 版本（推荐测试）
```bash
./build.sh Web
```

### 导出其他平台
```bash
./build.sh "Windows Desktop"  # Windows 可执行文件
./build.sh macOS             # macOS 应用
./build.sh "Linux/X11"       # Linux 可执行文件
./build.sh Android           # Android APK
```

### 导出所有平台
```bash
./build.sh
```

## ⚠️ 当前问题：需要安装导出模板

构建脚本运行正常，但导出失败，原因是缺少 Godot 导出模板。

### 解决方案（两种方式）

#### 方式 1：通过 Godot 编辑器安装（最简单）

1. **启动 Godot 编辑器**
   ```
   godot.exe
   ```

2. **打开导出模板管理器**
   - 菜单：`Editor` → `Manage Export Templates`
   - 或：`Project` → `Export` → `Install Export Templates`

3. **下载模板**
   - 选择版本：**4.6.1.stable**
   - 点击 `Download` → `Install`

4. **重新构建**
   ```bash
   ./build.sh Web
   ```

#### 方式 2：查看详细指南
阅读 `INSTALL_TEMPLATES.md` 文件获取完整的安装步骤。

## 📁 构建输出位置

构建完成后，文件将保存在：

```
builds/
├── web/          # Web 版本 (HTML + WASM)
├── windows/      # Windows 可执行文件
├── macos/        # macOS 应用
├── linux/        # Linux 可执行文件
└── android/      # Android APK
```

## 🔧 常见问题

### Q: 提示 "Cannot find file at ...godot_console.exe"
**A:** Godot console 版本不存在。可以：
- 使用 WinGet 重新安装：`winget install godot`
- 或修改 `build.sh` 中的 `GODOT_BIN` 路径

### Q: 提示 "指定路径不存在导出模板"
**A:** 需要安装导出模板（见上方解决方案）

### Q: 想直接在编辑器中测试游戏
**A:** 直接在 Godot 编辑器中打开 `game/project.godot` 项目，按 F5 运行。

## 📚 更多信息

- `BUILD_FIX_SUMMARY.md` - 详细的修复说明
- `INSTALL_TEMPLATES.md` - 导出模板安装指南
- `README.md` - 项目完整文档
