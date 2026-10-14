#!/bin/zsh
set -euo pipefail
cd "${0:A:h:h}"
swift build -c release
easyrec_bin_dir="$(swift build -c release --show-bin-path)"
easyrec_bundle="$PWD/build/EasyRec.app"
mkdir -p "$easyrec_bundle/Contents/MacOS" "$easyrec_bundle/Contents/Resources"
cp "$easyrec_bin_dir/EasyRec" "$easyrec_bundle/Contents/MacOS/EasyRec"
cp Resources/Info.plist "$easyrec_bundle/Contents/Info.plist"
cp Resources/EasyRec.icns "$easyrec_bundle/Contents/Resources/EasyRec.icns"
print "已构建：$easyrec_bundle"
print "运行：open '$easyrec_bundle'"
