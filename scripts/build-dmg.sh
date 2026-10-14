#!/bin/zsh
set -euo pipefail
cd "${0:A:h:h}"

zsh scripts/build-app.sh --universal
easyrec_version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Resources/Info.plist)"
easyrec_stage="$(mktemp -d "$PWD/build/dmg-root.XXXXXX")"
trap 'rm -rf "$easyrec_stage"' EXIT

ditto build/EasyRec.app "$easyrec_stage/EasyRec.app"
codesign --force --sign - --timestamp=none "$easyrec_stage/EasyRec.app"
codesign --verify --strict "$easyrec_stage/EasyRec.app"
ln -s /Applications "$easyrec_stage/Applications"
cp Resources/Install.txt "$easyrec_stage/Install.txt"
cp LICENSE "$easyrec_stage/LICENSE.txt"

mkdir -p dist
easyrec_dmg="$PWD/dist/EasyRec-${easyrec_version}-universal.dmg"
hdiutil create -volname EasyRec -srcfolder "$easyrec_stage" -format UDZO -ov "$easyrec_dmg"
print "已生成安装包：$easyrec_dmg"
