#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
DEVICE_ID="${1:-}"
if [ -z "$DEVICE_ID" ]; then
  DEVICE_ID="$(xcrun simctl list devices available --json | python3 -c 'import json,sys; d=json.load(sys.stdin)["devices"]; print(next(x["udid"] for devices in d.values() for x in devices if "iPhone" in x["name"]))')"
fi
xcodebuild -workspace Articles.xcworkspace -scheme Articles \
  -destination "platform=iOS Simulator,id=$DEVICE_ID" \
  -derivedDataPath build CODE_SIGNING_ALLOWED=NO test
