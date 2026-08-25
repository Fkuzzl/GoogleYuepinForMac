#!/bin/zsh
set -euo pipefail

project_root="${0:A:h:h}"
user_temp="${TMPDIR:-/private/tmp}"
derived_data="${GOOGLE_YUEPIN_DERIVED_DATA:-${user_temp%/}/GoogleYuepinForMacDerivedData}"
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

# Sign only the derived build product. DerivedData defaults outside the project
# so iCloud/File Provider cannot continuously reattach metadata while codesign
# seals the app. The cleanup remains as a final defense before signing.
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
