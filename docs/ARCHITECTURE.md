# Architecture

EasyRec is a native macOS application built with SwiftUI, AppKit, and ScreenCaptureKit. The executable is a single Swift package target; the directories separate responsibilities rather than creating extra package dependencies.

## Source layout

| Directory | Responsibility |
| --- | --- |
| `Sources/EasyRec/App` | Application entry, menu bar, termination handling, and the floating window |
| `Sources/EasyRec/Capture` | Recording state, content selection, capture configuration, output lifecycle, and dimensions |
| `Sources/EasyRec/UI` | Toolbar, settings, reusable controls, and shared appearance |
| `Resources` | Bundle metadata, icon artwork, and ICNS |
| `scripts` | Local application packaging, icon conversion, and standalone checks |
| `Tests` | Capture dimension checks |

`RecorderModel` owns the capture session. SwiftUI observes it, while `RecorderWindowController` owns the borderless AppKit panel. The window and SwiftUI background share their size and corner radius through `RecorderAppearance`.

## Recording flow

1. A toolbar action opens `SCContentSharingPicker` for one display or window.
2. The selected `SCContentFilter` is retained and the toolbar returns to the foreground.
3. Record creates an `SCStreamConfiguration`, an `SCRecordingOutput`, and an `SCStream`.
4. `SCRecordingOutput` handles H.264 encoding and MP4 writing. Its start callback enables the recording state and progress updates.
5. Pause stops the current stream and waits for the output to finish its segment. Resume starts another stream using the same selection and recording options.
6. Stop finishes the active segment, or saves directly from the paused state. `RecordingSegments` moves a single segment or concatenates several with AVMutableComposition/AVAssetExportSession export. Multi-segment exports re-encode to avoid compressed-sample overlap at edit boundaries. Source audio offsets are retained, and paused wall-clock time is excluded. Only a successful final save removes the segment directory.

`RecorderPreferences` stores user options in UserDefaults. `RecordingShortcuts` registers fixed Carbon hotkeys without an event monitor. `RegionSelectionController` draws a crop overlay on the display authorized by the system picker; `CaptureRegion` supplies screen-local point coordinates. `MicrophoneMonitor` uses a short-lived AVCaptureSession only while the input test is explicitly enabled.

`CaptureGeometry` converts the selected content's point dimensions and Retina scale to even pixel dimensions. It preserves the aspect ratio and caps the longest edge at 3840 pixels.

## State and callbacks

The normal session follows `idle → starting → countdown (optional) → starting → recording → finishing → idle`. Pause uses `recording → pausing → paused → starting → recording`. Content and folder selection have separate temporary states. A failed stop exposes a retry action and prevents a new recording from starting over an unresolved session.

The model is main-actor isolated. System delegates enter the main actor and compare the callback's stream or output identity with the current session. This prevents a delayed callback from clearing another session. Capture handles remain alive while the recording output finishes the file.

## Storage and permissions

Recordings are saved directly in the chosen directory, with timestamp-based names and a numeric suffix if a filename already exists. The chosen directory is stored in UserDefaults. Existing preferences and the bundle identity remain stable across this cleanup.

The macOS picker manages screen-sharing selection. Microphone permission is requested only when microphone capture is enabled and a recording starts. There is no network client, account layer, or telemetry pipeline in the application.

## Appearance and compatibility

The deployment target is macOS 15. The toolbar uses the macOS 26 glass API when available, with an AppKit visual-effect fallback on earlier systems. A nearly white surface keeps the toolbar bright; the settings content has an explicit white background. Building therefore requires the macOS 26 SDK or newer even though the app can run on macOS 15.
