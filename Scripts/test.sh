#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
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
        candidates.extend((version,d["udid"]) for d in devices if "iPhone" in d["name"] and d.get("isAvailable",True))
if not candidates:
    sys.exit("Install an iOS 18+ simulator compatible with the selected Xcode SDK.")
print(sorted(candidates,key=lambda item:item[0],reverse=True)[0][1])
' "$SDK_VERSION")"
fi
xcodebuild -workspace Articles.xcworkspace -scheme Articles \
  -destination "platform=iOS Simulator,id=$DEVICE_ID" \
  -parallel-testing-enabled NO \
  -derivedDataPath build COMPILER_INDEX_STORE_ENABLE=NO CODE_SIGNING_ALLOWED=NO test
