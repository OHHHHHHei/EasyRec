#!/bin/zsh
set -euo pipefail
cd "${0:A:h:h}"
easyrec_master="$PWD/Resources/AppIcon.png"
easyrec_iconset="$PWD/build/EasyRec.iconset"
mkdir -p "$easyrec_iconset"

create_icon() {
    sips -z "$1" "$1" "$easyrec_master" --out "$easyrec_iconset/$2" >/dev/null
}

create_icon 16 icon_16x16.png
create_icon 32 icon_16x16@2x.png
create_icon 32 icon_32x32.png
create_icon 64 icon_32x32@2x.png
create_icon 128 icon_128x128.png
create_icon 256 icon_128x128@2x.png
create_icon 256 icon_256x256.png
create_icon 512 icon_256x256@2x.png
create_icon 512 icon_512x512.png
create_icon 1024 icon_512x512@2x.png

iconutil --convert icns --output Resources/EasyRec.icns "$easyrec_iconset"
print "已生成 Resources/EasyRec.icns"
