#!/bin/zsh
set -euo pipefail

project_root="${0:A:h:h}"
derived_data="${project_root}/.build/xcode"
app="${derived_data}/Build/Products/Release/GoogleYuepinForMac.app"
entitlements="${project_root}/GoogleYuepinForMac/GoogleYuepinForMac.entitlements"

cd "${project_root}"

echo "Building the Release input source without Xcode-managed signing..."
/usr/bin/xcodebuild \
  -project GoogleYuepinForMac.xcodeproj \
  -scheme GoogleYuepinForMac \
  -configuration Release \
  -derivedDataPath "${derived_data}" \
  CODE_SIGNING_ALLOWED=NO \
  build

if [[ ! -d "${app}" ]]; then
  echo "error: Build succeeded but ${app} was not found."
  exit 1
fi

/usr/bin/plutil -lint "${entitlements}" >/dev/null

# Sign only the derived build product. This avoids requiring an Apple Developer
# certificate for a personal, local installation and removes metadata that
# macOS rejects when sealing an app bundle.
/usr/bin/xattr -cr "${app}"
/usr/bin/codesign \
  --force \
  --sign - \
  --options runtime \
  --entitlements "${entitlements}" \
  "${app}"
/usr/bin/codesign --verify --deep --strict "${app}"

echo "Local ad-hoc signing: PASS"
echo "Built app: ${app}"
