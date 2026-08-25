#!/bin/zsh
set -euo pipefail

project_root="${0:A:h:h}"
derived_data="${project_root}/.build/xcode"
app="${derived_data}/Build/Products/Release/GoogleYuepinForMac.app"
info_plist="${app}/Contents/Info.plist"

if [[ "$(/usr/bin/uname -s)" != "Darwin" ]]; then
  echo "error: This preflight must run on macOS."
  exit 1
fi

if [[ "$(/usr/bin/uname -m)" != "arm64" ]]; then
  echo "error: GoogleYuepinForMac currently requires an Apple Silicon Mac."
  exit 1
fi

if ! /usr/bin/xcode-select -p >/dev/null 2>&1; then
  echo "error: Select Xcode in Xcode Settings > Locations > Command Line Tools."
  exit 1
fi

macos_version="$(/usr/bin/sw_vers -productVersion)"
macos_major="${macos_version%%.*}"
if (( macos_major < 15 )); then
  echo "error: GoogleYuepinForMac requires macOS 15 or newer (found ${macos_version})."
  exit 1
fi

developer_directory="$(/usr/bin/xcode-select -p)"
if [[ "${developer_directory}" != *'.app/Contents/Developer' ]]; then
  echo "error: The full Xcode app is not selected in Xcode Settings > Locations."
  exit 1
fi

xcode_version="$(/usr/bin/xcodebuild -version | /usr/bin/awk 'NR == 1 { print $2 }')"
xcode_major="${xcode_version%%.*}"
if (( xcode_major < 16 )); then
  echo "error: GoogleYuepinForMac requires Xcode 16 or newer (found ${xcode_version})."
  exit 1
fi

cd "${project_root}"

echo "macOS ${macos_version}, $(/usr/bin/uname -m)"
/usr/bin/xcodebuild -version

echo "Running core tests..."
/usr/bin/xcrun swift test

/bin/zsh "${project_root}/Scripts/build-local.sh"

if [[ ! -d "${app}" ]]; then
  echo "error: Build succeeded but ${app} was not found."
  exit 1
fi

echo "Verifying input-source metadata..."

bundle_identifier="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "${info_plist}")"
language="$(/usr/libexec/PlistBuddy -c 'Print :TISIntendedLanguage' "${info_plist}")"
minimum_system="$(/usr/libexec/PlistBuddy -c 'Print :LSMinimumSystemVersion' "${info_plist}")"

[[ "${bundle_identifier}" == "local.googleyuepinformac.inputmethod" ]] || {
  echo "error: Unexpected bundle identifier: ${bundle_identifier}"
  exit 1
}
[[ "${language}" == "yue-Hant" ]] || {
  echo "error: Unexpected intended language: ${language}"
  exit 1
}
[[ "${minimum_system}" == "15.0" ]] || {
  echo "error: Unexpected minimum macOS version: ${minimum_system}"
  exit 1
}
[[ -f "${app}/Contents/Resources/InputSourceIcon.png" ]] || {
  echo "error: Input-source icon is missing from the built app."
  exit 1
}

echo "Mac preflight: PASS"
echo "Built app: ${app}"
echo "Next: /bin/zsh Scripts/install-local.sh"
