<p align="center">
  <img src="Resources/AppIcon.png" alt="EasyRec" width="112">
</p>

<h1 align="center">EasyRec</h1>
<p align="center">小小工具栏，轻松录下来。</p>
<p align="center">macOS 原生录屏 · Swift · MIT 开源</p>
<p align="center"><a href="README.md">English</a></p>

EasyRec 是一个轻巧的 macOS 录屏工具。选好屏幕或窗口，打开需要的声音，视频就会保存到你指定的文件夹。

## 能做什么

- 明亮的玻璃工具栏，小巧、可拖动。
- 通过 macOS 系统选择器录制屏幕或窗口。
- 独立开关系统声音和麦克风。
- 30 / 60 fps，可选择是否录入鼠标指针。
- 输出 H.264 / MP4，保持画面比例，最长边限制为 3840 像素。
- 记住保存位置，自动命名，保存后快速播放或在 Finder 中定位。
- 隐藏工具栏后，仍可从菜单栏停止录制。

视频保存在你的 Mac 上。应用没有账户服务、分析统计或上传功能。

## 下载安装

**[下载 EasyRec 0.1.0 安装包](https://github.com/OHHHHHHei/EasyRec/releases/download/v0.1.0/EasyRec-0.1.0-universal.dmg)**，适用于 macOS 15 及以上的 Apple 芯片和 Intel Mac。

打开 DMG，将 `EasyRec.app` 拖入 **Applications（应用程序）**，再从应用程序中启动。安装后可推出磁盘映像。

本版本采用临时签名，尚未经过 Apple 公证，首次启动可能被 macOS 阻止。如果你信任此发布来源，可参照 [Apple 官方说明](https://support.apple.com/102445)确认打开。Intel 版本通过交叉编译生成，目前的运行验证在 Apple 芯片上完成。

## 构建与运行

运行需要 **macOS 15 或更新版本**。开发环境需要 **Xcode 26 或对应的 Command Line Tools**，包含 macOS 26 或更新的 SDK。项目使用 Swift Package Manager，没有第三方运行依赖。

```sh
git clone https://github.com/OHHHHHHei/EasyRec.git
cd EasyRec
zsh scripts/build-app.sh
open build/EasyRec.app
```

请运行脚本生成的 `.app`，以便 macOS 读取麦克风权限用途说明。开发时也可以用 Xcode 打开 `Package.swift`。

本地开发构建没有 Developer ID 签名或公证。通用 DMG 的打包步骤见[发布说明](docs/RELEASING.md)。

## 开始录制

1. 点击「屏幕」或「窗口」，在系统选择器中确认录制内容。
2. 按需开启「系统音」和「麦克风」，蓝色表示已开启。
3. 点击红色「录制」。结束时点击「停止」，等待保存完成。
4. 点击「播放」查看视频，或点击「文件」在 Finder 中定位。

齿轮中可以调整保存位置、帧率和鼠标指针。首次运行默认保存到 `~/Movies/EasyRec`，之后会记住你选择的文件夹。右侧叉号用于隐藏工具栏；通过菜单栏或 Dock 图标可以重新显示，录制期间也能从菜单栏停止。

开启麦克风并开始录制时，应用会请求麦克风权限。屏幕共享选择与所需权限由 macOS 处理。设置更改用于下一次录制。

界面目前使用简体中文，英文界面尚未实现。

## 参与开发

```sh
zsh scripts/test.sh
zsh scripts/build-app.sh
```

离线检查覆盖录制尺寸计算，不依赖 XCTest。实际采集、音画同步及权限交互需要在 macOS 上手动验证。

- [代码结构](docs/ARCHITECTURE.md)
- [测试说明](docs/TESTING.md)
- [贡献指南](CONTRIBUTING.md)
- [发布说明](docs/RELEASING.md)
- [更新记录](CHANGELOG.md)
- [图标资源](Resources/README.md)

项目处于早期开发阶段，暂不支持区域框选、暂停、相机浮窗、剪辑或自动缩放。

## 许可证

源代码、文档和仓库中的 EasyRec 图标均采用 [MIT 许可证](LICENSE)。
