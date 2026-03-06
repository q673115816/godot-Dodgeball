# Godot 导出模板安装指南

## 问题

在尝试导出游戏时，可能会遇到以下错误：

```
指定路径不存在导出模板：
C:/Users/Administrator/AppData/Roaming/Godot/export_templates/4.6.1.stable/web_nothreads_debug.zip
指定路径不存在导出模板：
C:/Users/Administrator/AppData/Roaming/Godot/export_templates/4.6.1.stable/web_nothreads_release.zip
```

## 解决方案

### 方法 1：通过 Godot 编辑器安装（推荐）

1. **打开 Godot 编辑器**
   - 双击 `godot.exe` 启动 Godot 编辑器

2. **进入导出模板管理**
   - 点击菜单栏：`编辑器 (Editor)` → `导出模板管理器 (Manage Export Templates)`
   - 或者点击：`项目 (Project)` → `导出 (Export)`，然后点击 `安装导出模板 (Install Export Templates)`

3. **下载并安装模板**
   - 在弹出的窗口中，找到与您当前引擎版本匹配的模板（当前版本：**4.6.1.stable**）
   - 点击 `下载 (Download)` 按钮
   - 下载完成后点击 `安装 (Install)` 按钮

4. **验证安装**
   - 安装成功后，返回导出界面查看模板是否已正确安装
   - 模板应安装在：`C:\Users\Administrator\AppData\Roaming\Godot\export_templates\4.6.1.stable\`

### 方法 2：手动下载模板

1. **访问 Godot 官网**
   - 打开：[https://godotengine.org/download/](https://godotengine.org/download/)

2. **找到导出模板**
   - 在下载页面找到 "Export Templates" 部分
   - 选择与您引擎版本匹配的模板（4.6.1）

3. **下载并解压**
   - 下载后解压到：`C:\Users\Administrator\AppData\Roaming\Godot\export_templates\4.6.1.stable\`

### 支持的导出平台

根据项目的导出预设，需要安装以下平台的导出模板：

- ✅ **Web** - 导出为 HTML5/WebAssembly
- ✅ **Windows Desktop** - 导出为 Windows 可执行文件
- ✅ **macOS** - 导出为 macOS 应用
- ✅ **Linux/X11** - 导出为 Linux 可执行文件
- ✅ **Android** - 导出为 Android APK

## 安装完成后

安装导出模板后，重新运行构建脚本：

```bash
./build.sh "Web"
```

构建应该会成功执行！

## 注意事项

- 确保导出模板版本与引擎版本完全匹配（当前：4.6.1.stable）
- 导出模板文件较大，请确保有足够的磁盘空间
- 首次下载可能需要较长时间，取决于网络速度
