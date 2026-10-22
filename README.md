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
- Independent system audio and microphone switches, input-device selection and an opt-in level test.
- Region capture (macOS 15.2+) using the system sharing picker before cropping.
- Pause/resume with a single final MP4 that excludes paused time.
- A cancellable 0/3/5-second countdown and remembered recording options.
- 30 or 60 fps, with an optional mouse pointer.
- H.264 / MP4 output, scaled proportionally to a maximum long edge of 3840 pixels.
- A remembered save folder, automatic filenames, and quick playback or Finder access.
- Menu bar controls that remain available when the toolbar is hidden.

Recordings stay on your Mac. The app has no account service, analytics, or upload feature.

## Download and install

**[Download EasyRec 0.2.0](https://github.com/OHHHHHHei/EasyRec/releases/download/v0.2.0/EasyRec-0.2.0-universal.dmg)** — macOS 15+, Apple Silicon and Intel.

Open the DMG, drag `EasyRec.app` into **Applications**, then launch it from Applications. You can eject the disk image afterward.

This release is ad-hoc signed and has not been notarized by Apple. macOS may block the first launch. If you trust the release, follow [Apple's instructions for opening the app](https://support.apple.com/102445). Intel is cross-compiled; runtime testing so far has been on Apple Silicon.

## Build and run

Runtime: **macOS 15 or later**. Building requires **Xcode 26 or its Command Line Tools**, including the macOS 26 SDK or newer. The project uses Swift Package Manager and has no third-party runtime dependencies.

```sh
git clone https://github.com/OHHHHHHei/EasyRec.git
cd EasyRec
zsh scripts/build-app.sh
open build/EasyRec.app
```

Run the `.app` bundle so macOS can read its microphone permission description. You can also open `Package.swift` in Xcode to work on the source.

The local development build is not Developer ID signed or notarized. For universal DMG packaging, see [Releasing](docs/RELEASING.md).

## Record something

1. Click **屏幕** (Screen) or **窗口** (Window), then confirm your selection in the system picker.
2. Choose **系统音** (System Audio) and **麦克风** (Microphone). Blue means enabled.
3. Click the red **录制** (Record) button. Click **停止** (Stop) to finish saving.
4. Use **播放** (Play) or **文件** (File) to open the result.

The gear opens the save folder, frame rate, and pointer settings. New installations save to `~/Movies/EasyRec`; your chosen folder is remembered. The × hides the toolbar. Reopen it from the menu bar or Dock, and use the menu bar to stop a recording while it is hidden.

Right-click **屏幕** or choose region capture in Settings. Confirm a display in the system picker, then drag a rectangle on it; release to confirm or press Escape to cancel.

Global hotkeys: **Command-Shift-R** starts/stops recording or cancels a countdown; **Command-Shift-E** shows/hides the toolbar; **Command-Shift-P** pauses/resumes. These shortcuts are fixed; settings report conflicts.

Microphone settings are also available by right-clicking the microphone tile. The level test starts only after you request it, never saves or plays audio, and stops when its popover closes. Microphone access is requested for recording or an explicit input test. macOS handles screen-sharing selection and any required permissions. Settings apply to the next recording.

The interface is currently in Simplified Chinese. English UI localization is not yet implemented.

## Development

```sh
zsh scripts/test.sh
zsh scripts/build-app.sh
```

The standalone checks cover capture dimensions, region coordinates and preference persistence without XCTest. With FFmpeg installed, run `zsh scripts/test-media.sh` for segment concatenation, two-track audio and failed-save preservation checks. Actual video, audio, and permission behavior need an interactive check on macOS.

- [Architecture](docs/ARCHITECTURE.md)
- [Testing](docs/TESTING.md)
- [Contributing](CONTRIBUTING.md)
- [Releasing](docs/RELEASING.md)
- [Changelog](CHANGELOG.md)
- [Icon assets](Resources/README.md)

EasyRec is in early development. Camera overlays, editing and automatic zoom are not available yet. Pausing stops capture and closes the current segment; resuming creates another. Stop joins them locally. On export failure, source recordings remain in a `.segments` directory beside the destination, with a button to open it.

## License

Source code, documentation, and the included EasyRec icon are provided under the [MIT License](LICENSE).
