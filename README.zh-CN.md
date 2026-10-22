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
- 独立开关系统声音和麦克风，选择输入设备，并在录制前测试音量。
- 区域框选（macOS 15.2+），沿用系统共享选择器授权。
- 暂停／继续，结束后合成一个不含暂停时间的 MP4。
- 关闭／3 秒／5 秒倒计时，支持取消。
- 记住音频、帧率、鼠标指针和倒计时设置。
- 30 / 60 fps，可选择是否录入鼠标指针。
- 输出 H.264 / MP4，保持画面比例，最长边限制为 3840 像素。
- 记住保存位置，自动命名，保存后快速播放或在 Finder 中定位。
- 隐藏工具栏后，仍可从菜单栏停止录制。

视频保存在你的 Mac 上。应用没有账户服务、分析统计或上传功能。

## 下载安装

**[下载 EasyRec 0.2.1 安装包](https://github.com/OHHHHHHei/EasyRec/releases/download/v0.2.1/EasyRec-0.2.1-universal.dmg)**，适用于 macOS 15 及以上的 Apple 芯片和 Intel Mac。

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
3. 点击红色「录制」，等待倒计时；倒计时期间可按 Esc 或点击「取消」。录制中可点击状态栏的「暂停／继续」，结束时点击「停止」。
4. 点击「播放」查看视频，或点击「文件」在 Finder 中定位。

齿轮中可以调整保存位置、帧率和鼠标指针。首次运行默认保存到 `~/Movies/EasyRec`，之后会记住你选择的文件夹。右侧叉号用于隐藏工具栏；通过菜单栏或 Dock 图标可以重新显示，录制期间也能从菜单栏停止。

右键「屏幕」或在设置中选择「框选录制区域」，先确认要共享的屏幕，再拖动框选；松开确认，Esc 取消。框选范围限制在所选显示器内。

全局快捷键：**⌘⇧R** 开始／停止（倒计时期间取消），**⌘⇧E** 显示／隐藏工具栏，**⌘⇧P** 暂停／继续。快捷键固定，若被其他应用占用，设置中会提示。

麦克风设备与音量测试位于设置，也可右键「麦克风」打开。只有点击「测试麦克风」后才开始预听计量，不保存、不回放声音，关闭面板即停止。开启麦克风录制或主动测试时，应用会请求麦克风权限。屏幕共享选择与所需权限由 macOS 处理。设置更改用于下一次录制。

界面目前使用简体中文，英文界面尚未实现。

## 参与开发

```sh
zsh scripts/test.sh
zsh scripts/build-app.sh
```

离线检查覆盖录制尺寸、区域坐标和设置持久化，不依赖 XCTest。安装 FFmpeg 后还可运行 `zsh scripts/test-media.sh` 验证分段合成、双音轨和失败保留。实际采集、音画同步及权限交互需要在 macOS 上手动验证。

- [代码结构](docs/ARCHITECTURE.md)
- [测试说明](docs/TESTING.md)
- [贡献指南](CONTRIBUTING.md)
- [发布说明](docs/RELEASING.md)
- [更新记录](CHANGELOG.md)
- [图标资源](Resources/README.md)

项目处于早期开发阶段，暂不支持相机浮窗、剪辑或自动缩放。暂停会关闭当前采集，继续时创建新片段；停止后在本地拼接。若导出失败，原始片段会保留在保存目录内的 `.segments` 文件夹，并提供打开入口。

## 许可证

源代码、文档和仓库中的 EasyRec 图标均采用 [MIT 许可证](LICENSE)。
