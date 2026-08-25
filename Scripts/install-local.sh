#!/bin/zsh
set -euo pipefail

project_root="${0:A:h:h}"
derived_data="${project_root}/.build/xcode"
source_app="${derived_data}/Build/Products/Release/GoogleYuepinForMac.app"
destination_app="/Library/Input Methods/GoogleYuepinForMac.app"

cd "${project_root}"

/usr/bin/xcodebuild \
  -project GoogleYuepinForMac.xcodeproj \
  -scheme GoogleYuepinForMac \
  -configuration Release \
  -derivedDataPath "${derived_data}" \
  build

if [[ ! -d "${source_app}" ]]; then
  echo "error: Build succeeded but ${source_app} was not found."
  exit 1
fi

/usr/bin/codesign --verify --deep --strict "${source_app}"

if [[ -d "${destination_app}" ]]; then
  /usr/bin/osascript -e 'tell application id "local.googleyuepinformac.inputmethod" to quit' >/dev/null 2>&1 || true
fi

/usr/bin/sudo /bin/mkdir -p "/Library/Input Methods"
/usr/bin/sudo /bin/rm -rf "${destination_app}"
/usr/bin/sudo /usr/bin/ditto "${source_app}" "${destination_app}"
"${destination_app}/Contents/MacOS/GoogleYuepinForMac" --register

echo "Installed ${destination_app}"
echo "Log out and back in, then add Google粵拼forMac under Cantonese, Traditional."
