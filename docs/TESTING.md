# Testing

## Automated checks

```sh
zsh scripts/test.sh
zsh scripts/build-app.sh
```

The standalone Swift runner checks Retina pixel conversion, the 3840-pixel limit for a 6K display, proportional even dimensions for portrait content, and invalid inputs. It works with Command Line Tools and does not depend on XCTest.

Preferences checks use an isolated defaults domain to verify first-launch values, persistence, and supported frame-rate/countdown options. For controls, check that Escape or the record button cancels the countdown without creating a recording, and that Command-Shift-R and Command-Shift-E work while another app is active. The settings panel reports hot-key registration conflicts.

Region checks cover reverse drags and clipping to screen-local bounds. Manually check region selection on Retina and secondary displays, including Escape cancellation. Region capture uses the system sharing picker followed by a crop overlay on the selected display, and requires macOS 15.2 or newer. In microphone settings, test the default and an external input, close the popover to stop metering, then disconnect the selected device: the app should ask for a new device rather than silently recording another input.

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


## Feature-branch media checks

With FFmpeg installed, run `zsh scripts/test-media.sh`. It generates non-personal video/audio fixtures, concatenates three one-second segments (including a silent middle segment), checks both audio tracks and the final duration, checks strictly ordered video decode timestamps including trimmed H.264 joins, decodes the result, and verifies single-segment saving and source retention on a destination collision. Generated media stays under ignored `build/` for inspection.

Interactive coverage still needs repeated pause/resume with actual system audio and microphone, stop while paused, countdown cancellation, and global shortcuts from another foreground app. A successful synthetic media check does not certify live audio synchronization or device hot-unplug recovery.


On the integrated feature branch, the app was opened and the microphone input meter showed live values and returned to zero when stopped. A real window session passed countdown cancellation, recording, pause, resume, a second pause and stopping while paused. The resulting 46.08-second H.264 MP4 decoded successfully; this run had both audio inputs disabled. The region overlay opened through the system picker and Escape restored the toolbar. A cross-app shortcut injected by automation reached TextEdit's Page Setup command instead of the recorder, so physical global-hotkey behavior remains unverified. Multi-display crop accuracy and live audio synchronization across pauses remain manual checks.

![Paused compact toolbar](images/paused-toolbar.jpg)

The initial live export exposed overlapping compressed timestamps at a join. Multi-segment saving now applies an AVVideoComposition during export to force re-encoding; synthetic GOP-trim and ordered-timestamp checks pass after that fix. The final re-encoding path has not yet been repeated with live audio capture.
