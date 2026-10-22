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

A successful synthetic media check does not certify live audio synchronization or device hot-unplug recovery. The live checks below cover the current integrated branch.


On the integrated feature branch, the app was opened and the microphone input meter showed live values and returned to zero when stopped. A real window session passed countdown cancellation, recording, pause, resume, a second pause and stopping while paused. The resulting 46.08-second H.264 MP4 decoded successfully; this run had both audio inputs disabled. The region overlay opened through the system picker and Escape restored the toolbar. Automated Command-Shift-P injection reached TextEdit's Page Setup command instead of the recorder. On the final build, the user physically confirmed that Command-Shift-E hides and shows EasyRec from another foreground app. Physical start/stop and pause/resume shortcuts remain to be checked. Multi-display crop accuracy still needs a completed drag-and-record check.

![Paused compact toolbar](images/paused-toolbar.jpg)

The initial live export exposed overlapping compressed timestamps at a join. Multi-segment saving now applies an AVVideoComposition during export to force re-encoding; synthetic GOP-trim and ordered-timestamp checks pass after that fix. The final export path was subsequently exercised with live audio capture as described below.


### Live audio follow-up — 2026-10-23

On the final universal build, a generated 180-second grid video with a white flash and 880 Hz tone every second was opened in a local player. Its window title was verified in the system sharing picker before recording. Both system sound and microphone were enabled; the user accepted the renewed macOS microphone authorization prompt.

The session recorded three segments, resumed twice, and stopped while paused. The first segment captured the test player at its end screen; the test clip was restarted before the second segment. The saved 62.776667-second MP4 contains 2164 × 1320 H.264 video and one stereo audio stream with both inputs enabled. It opened through EasyRec's Play button and played in the local player. Full-file FFmpeg decoding succeeded; video DTS values strictly increased and PTS values were unique. The temporary segment directory was removed after the successful save.

Copies of the second and third source segments were retained locally before saving. At 2, 8 and 14 seconds in each segment, two-second audio samples were matched against the final file by waveform cross-correlation. Correlation rounded to 1.0000. Comparing their audio placement against the median placement of the visual flashes estimated an additional audio/video shift of about 19 ms and 25 ms respectively, constant within each segment. Flash timing was sampled at 60 Hz, so these are approximate measurements. This check found no growing offset introduced by the joins. Microphone environmental sound interfered with absolute tone-onset detection; it does not establish separate microphone latency or clean-source absolute synchronization.

The built-in Retina display's region overlay opened through the sharing picker, and Escape returned to a usable toolbar. Two automated drag attempts, including a fresh app binding, failed in the automation tool with `noWindowsAvailable`. No region recording was started. Automated Command-Shift-R from the player did not trigger EasyRec; the tool's injected keys cannot stand in for physical global-hotkey validation. These remain unverified rather than passed.

All standalone and synthetic media checks passed again. Live recordings and analysis files remain local and are not included in the public repository. No recording or microphone preview is left running; microphone recording was restored to its original disabled setting.


### 0.2.0 installer — 2026-10-23

The universal DMG was built from the merged source with version 0.2.0 / build 2. Its mounted contents included EasyRec.app, the Applications shortcut, installation instructions and the license. A copy extracted from the DMG retained a valid ad-hoc signature and contained arm64 and x86_64 executables, both with a macOS 15.0 minimum. That copy launched on Apple Silicon and displayed the new region, countdown, microphone and shortcut settings while retaining the existing save directory. The disk image was then ejected. This packaging check did not repeat a recording or simulate a freshly downloaded app's Gatekeeper prompts.


### Region selection focus fix — 2026-10-23

After a user reported needing to click EasyRec in the Dock after choosing a display, the region panel was changed to remain visible while the app is inactive and to accept input without an application-activation click. The local release configuration compiled successfully. The user then tested the fixed local build and confirmed the extra Dock click was no longer needed. This confirms the reported focus handoff, not pixel-accurate crop output across every display.
