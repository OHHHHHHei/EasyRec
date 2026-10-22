#!/bin/zsh
set -euo pipefail
cd "${0:A:h:h}"
if ! command -v ffmpeg >/dev/null; then
    print -u2 "This media integration check requires ffmpeg."
    exit 1
fi
mkdir -p build
easyrec_fixture_dir="$(mktemp -d "$PWD/build/media-check.XXXXXX")"
ffmpeg -v error -f lavfi -i color=c=red:s=320x180:r=30:d=1 \
    -f lavfi -i sine=frequency=440:duration=1 -f lavfi -i sine=frequency=660:duration=1 \
    -map 0:v -map 1:a -map 2:a -c:v libx264 -pix_fmt yuv420p -c:a aac -t 1 "$easyrec_fixture_dir/first.mp4"
ffmpeg -v error -f lavfi -i color=c=green:s=320x180:r=30:d=1 \
    -c:v libx264 -pix_fmt yuv420p "$easyrec_fixture_dir/silent.mp4"
ffmpeg -v error -f lavfi -i color=c=blue:s=320x180:r=30:d=1 \
    -f lavfi -i sine=frequency=880:duration=1 -f lavfi -i sine=frequency=220:duration=1 \
    -map 0:v -map 1:a -map 2:a -c:v libx264 -pix_fmt yuv420p -c:a aac -t 1 "$easyrec_fixture_dir/second.mp4"
swiftc -parse-as-library Sources/EasyRec/Capture/RecordingSegments.swift \
    Tests/SegmentChecks.swift -o build/segment-checks
build/segment-checks "$easyrec_fixture_dir"
ffmpeg -v error -xerror -i "$easyrec_fixture_dir/joined.mp4" -map 0 -fps_mode passthrough -enc_time_base demux -f null -
python3 - "$easyrec_fixture_dir" <<'PY'
import json
import pathlib
import subprocess
import sys

for name in ("joined.mp4", "trimmed-joined.mp4"):
    path = pathlib.Path(sys.argv[1]) / name
    result = subprocess.check_output([
        "ffprobe", "-v", "error", "-select_streams", "v:0", "-show_packets",
        "-show_entries", "packet=pts_time,dts_time", "-of", "json", str(path),
    ])
    packets = json.loads(result)["packets"]
    decode_times = [float(packet["dts_time"]) for packet in packets]
    presentation_times = [packet["pts_time"] for packet in packets]
    assert all(a < b for a, b in zip(decode_times, decode_times[1:])), name
    assert len(set(presentation_times)) == len(presentation_times), name
print("PASS: Exported MP4 timestamps remain ordered across trimmed H.264 boundaries")
PY
print "Media fixtures: $easyrec_fixture_dir"
