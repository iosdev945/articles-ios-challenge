#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

if [ ! -f Pods/Manifest.lock ] || ! cmp -s Podfile.lock Pods/Manifest.lock; then
  echo "Install the locked dependencies first: bundle install && bundle exec pod install --deployment" >&2
  exit 1
fi

DEVICE_ID="${1:-}"
if [ -z "$DEVICE_ID" ]; then
  SDK_VERSION="$(xcrun --sdk iphonesimulator --show-sdk-version)"
  DEVICE_ID="$(xcrun simctl list devices available --json | python3 -c '
import json,re,sys
sdk=tuple(int(x) for x in sys.argv[1].split(".")[:2])
sdk=(sdk+(0,))[:2]
candidates=[]
for runtime,devices in json.load(sys.stdin)["devices"].items():
    match=re.search(r"iOS-(\d+)-(\d+)", runtime)
    if not match: continue
    version=tuple(map(int,match.groups()))
    if (18,0) <= version <= sdk:
        for device in devices:
            if "iPhone" in device["name"] and device.get("isAvailable",True):
                candidates.append((device["state"] == "Booted",version,device["udid"]))
if not candidates:
    sys.exit("Install an iOS 18+ simulator in Xcode Settings → Components.")
print(sorted(candidates,reverse=True)[0][2])
' "$SDK_VERSION")"
fi

STATE="$(xcrun simctl list devices --json | python3 -c '
import json,sys
for devices in json.load(sys.stdin)["devices"].values():
    for device in devices:
        if device["udid"] == sys.argv[1]:
            print(device["state"])
            sys.exit(0)
sys.exit("Unknown simulator UDID.")
' "$DEVICE_ID")"
if [ "$STATE" != "Booted" ]; then
  xcrun simctl boot "$DEVICE_ID"
fi
xcrun simctl bootstatus "$DEVICE_ID" -b
xcodebuild -workspace Articles.xcworkspace -scheme Articles -configuration Debug \
  -destination "platform=iOS Simulator,id=$DEVICE_ID" \
  -derivedDataPath build COMPILER_INDEX_STORE_ENABLE=NO CODE_SIGNING_ALLOWED=NO build
xcrun simctl install "$DEVICE_ID" build/Build/Products/Debug-iphonesimulator/Articles.app
open -a Simulator
xcrun simctl launch --terminate-running-process "$DEVICE_ID" com.rajvi.articles
