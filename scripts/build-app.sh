#!/bin/zsh
set -euo pipefail
cd "${0:A:h:h}"

case "${1:-}" in
    "")
        swift build -c release
        easyrec_bin_dir="$(swift build -c release --show-bin-path)"
        ;;
    --universal)
        easyrec_arm_scratch="$PWD/.build/universal/arm64"
        easyrec_intel_scratch="$PWD/.build/universal/x86_64"
        swift build -c release --arch arm64 --scratch-path "$easyrec_arm_scratch"
        easyrec_arm_dir="$(swift build -c release --arch arm64 --scratch-path "$easyrec_arm_scratch" --show-bin-path)"
        swift build -c release --arch x86_64 --scratch-path "$easyrec_intel_scratch"
        easyrec_intel_dir="$(swift build -c release --arch x86_64 --scratch-path "$easyrec_intel_scratch" --show-bin-path)"
        ;;
    *)
        print -u2 "用法：zsh scripts/build-app.sh [--universal]"
        exit 1
        ;;
esac

easyrec_bundle="$PWD/build/EasyRec.app"
mkdir -p "$easyrec_bundle/Contents/MacOS" "$easyrec_bundle/Contents/Resources"
if [[ "${1:-}" == --universal ]]; then
    lipo -create "$easyrec_arm_dir/EasyRec" "$easyrec_intel_dir/EasyRec" \
        -output "$easyrec_bundle/Contents/MacOS/.EasyRec-new"
else
    cp "$easyrec_bin_dir/EasyRec" "$easyrec_bundle/Contents/MacOS/.EasyRec-new"
fi
mv "$easyrec_bundle/Contents/MacOS/.EasyRec-new" "$easyrec_bundle/Contents/MacOS/EasyRec"
cp Resources/Info.plist "$easyrec_bundle/Contents/Info.plist"
cp Resources/EasyRec.icns "$easyrec_bundle/Contents/Resources/EasyRec.icns"
print "已构建：$easyrec_bundle"
print "运行：open '$easyrec_bundle'"
