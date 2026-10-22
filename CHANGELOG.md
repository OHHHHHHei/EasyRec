# Changelog

## 0.2.0 — 2026-10-23

- Remember audio switches, input device, cursor, frame rate and countdown settings.
- Add global start/stop, toolbar visibility and pause/resume shortcuts.
- Add a cancellable 0/3/5-second recording countdown.
- Select a screen region after the macOS sharing picker (macOS 15.2+).
- Select a microphone and test its input level without saving audio.
- Pause capture and join completed segments into one MP4 on stop; retain segments if saving fails.

## 0.1.0 — 2026-10-14

- Organize the application into app lifecycle, capture, and interface modules.
- Introduce a new light EasyRec icon.
- Publish English and Chinese project documentation, a contribution guide, and the MIT license.
- Screen and window recording with ScreenCaptureKit.
- System audio, microphone, mouse pointer, and 30/60 fps options.
- H.264 / MP4 output with proportional resolution limits.
- Remembered output directory and automatic recording filenames.
- Compact white toolbar, settings popover, and menu bar recording controls.
- Restore the toolbar after system content selection.

- Provide a universal DMG for Apple Silicon and Intel, with an Applications shortcut and installation instructions.
- Include a reusable DMG packaging script and build the installer in CI.

The download has an ad-hoc signature and is not notarized by Apple. Runtime verification is currently limited to Apple Silicon; Intel is cross-compiled.
