<p align="center">
  <img src="Resources/AppIcon.png" alt="EasyRec" width="112">
</p>

<h1 align="center">EasyRec</h1>
<p align="center">A little toolbar. A clear recording.</p>
<p align="center">Native screen recording for macOS · Swift · MIT</p>
<p align="center"><a href="README.zh-CN.md">简体中文</a></p>

EasyRec keeps everyday screen recording close at hand. Choose a screen or window, turn on the audio you need, and save a video straight to your folder.

## Features

- A compact, movable toolbar with a bright glass surface.
- Screen and window capture through the macOS sharing picker.
- Independent system audio and microphone switches.
- 30 or 60 fps, with an optional mouse pointer.
- H.264 / MP4 output, scaled proportionally to a maximum long edge of 3840 pixels.
- A remembered save folder, automatic filenames, and quick playback or Finder access.
- Menu bar controls that remain available when the toolbar is hidden.

Recordings stay on your Mac. The app has no account service, analytics, or upload feature.

## Build and run

Runtime: **macOS 15 or later**. Building requires **Xcode 26 or its Command Line Tools**, including the macOS 26 SDK or newer. The project uses Swift Package Manager and has no third-party runtime dependencies.

```sh
git clone https://github.com/OHHHHHHei/EasyRec.git
cd EasyRec
zsh scripts/build-app.sh
open build/EasyRec.app
```

Run the `.app` bundle so macOS can read its microphone permission description. You can also open `Package.swift` in Xcode to work on the source.

The local build is not Developer ID signed or notarized. There is currently no prebuilt release download.

## Record something

1. Click **屏幕** (Screen) or **窗口** (Window), then confirm your selection in the system picker.
2. Choose **系统音** (System Audio) and **麦克风** (Microphone). Blue means enabled.
3. Click the red **录制** (Record) button. Click **停止** (Stop) to finish saving.
4. Use **播放** (Play) or **文件** (File) to open the result.

The gear opens the save folder, frame rate, and pointer settings. New installations save to `~/Movies/EasyRec`; your chosen folder is remembered. The × hides the toolbar. Reopen it from the menu bar or Dock, and use the menu bar to stop a recording while it is hidden.

Microphone access is requested when you enable microphone recording and start a capture. macOS handles screen-sharing selection and any required permissions. Settings apply to the next recording.

The interface is currently in Simplified Chinese. English UI localization is not yet implemented.

## Development

```sh
zsh scripts/test.sh
zsh scripts/build-app.sh
```

The standalone checks cover capture dimensions and do not need XCTest. Actual video, audio, and permission behavior need an interactive check on macOS.

- [Architecture](docs/ARCHITECTURE.md)
- [Testing](docs/TESTING.md)
- [Contributing](CONTRIBUTING.md)
- [Changelog](CHANGELOG.md)
- [Icon assets](Resources/README.md)

EasyRec is in early development. Region selection, pause/resume, camera overlays, editing, and automatic zoom are not available yet.

## License

Source code, documentation, and the included EasyRec icon are provided under the [MIT License](LICENSE).
