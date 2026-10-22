# Testing

## Automated checks

```sh
zsh scripts/test.sh
zsh scripts/build-app.sh
```

The standalone Swift runner checks Retina pixel conversion, the 3840-pixel limit for a 6K display, proportional even dimensions for portrait content, and invalid inputs. It works with Command Line Tools and does not depend on XCTest.

Preferences checks use an isolated defaults domain to verify first-launch values, persistence, and supported frame-rate/countdown options. For controls, check that Escape or the record button cancels the countdown without creating a recording, and that Command-Shift-R and Command-Shift-E work while another app is active. The settings panel reports hot-key registration conflicts.

Region checks cover reverse drags and clipping to screen-local bounds. Manually check region selection on Retina and secondary displays, including Escape cancellation. Region capture requires macOS screen-recording permission. In microphone settings, test the default and an external input, close the popover to stop metering, then disconnect the selected device: the app should ask for a new device rather than silently recording another input.

The application build checks compilation and bundle packaging. Neither command proves that macOS permissions, recorded audio, or file playback work.

GitHub Actions runs the dimension checks and universal DMG packaging on a macOS runner for pushes and pull requests.

For installer changes, run `zsh scripts/build-dmg.sh`, mount the resulting DMG, and check the included app and Applications shortcut. Confirm the two executable architectures and the minimum macOS version. Launch a copy of the packaged app on the available hardware; cross-compilation alone does not verify Intel runtime behavior.

## Interactive recording check

Use a short recording with non-personal content. Confirm the selected source, start, stop, then play the resulting file.

| Scenario | Expected result |
| --- | --- |
| Screen capture | The chosen screen is recorded and the toolbar returns after selection |
| Window capture | The chosen window is recorded |
| Audio combinations | No audio, system audio, microphone, and both inputs behave as selected |
| 30 / 60 fps | The chosen setting is applied to the next recording |
| Cursor disabled | The pointer is omitted from the recording |
| Custom save folder | The file appears in the chosen folder; the setting survives a restart |
| Repeated recording | A second recording starts after the first file finishes saving |
| Hidden toolbar | The menu bar can stop recording and reopen the toolbar |
| Cancel selection | The app returns to a usable idle state |

Long recordings, device changes, low disk space, and capture interruptions need separate manual checks when changes affect those paths.

## Current verification scope

The initial implementation has been built and opened on Apple Silicon with macOS 26. Screen recording, system audio, and microphone capture have been confirmed through interactive user testing. The standalone dimension checks also pass.

For the 0.1.0 download, the universal DMG was mounted, both executable architectures and the macOS 15 minimum were inspected, and the packaged application was copied out and launched successfully on Apple Silicon. Its ad-hoc bundle signature was valid. This packaging check did not repeat a full recording or simulate a fresh download's Gatekeeper prompts.

This is not a compatibility or performance certification. Audio synchronization, long sessions, failure recovery, Intel hardware, and macOS 15 still need broader coverage. Interface-only changes are checked by building and opening the affected controls rather than claiming a new recording test.
