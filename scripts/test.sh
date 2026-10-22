#!/bin/zsh
set -euo pipefail
cd "${0:A:h:h}"
mkdir -p build
swiftc Sources/EasyRec/Capture/CaptureGeometry.swift \
    Sources/EasyRec/Capture/RecordingState.swift \
    Tests/CaptureGeometryChecks.swift -o build/capture-geometry-checks
build/capture-geometry-checks
swiftc Sources/EasyRec/Capture/RecorderPreferences.swift \
    Tests/PreferencesChecks.swift -o build/preferences-checks
build/preferences-checks
swiftc Sources/EasyRec/Capture/CaptureRegion.swift \
    Tests/RegionChecks.swift -o build/region-checks
build/region-checks
