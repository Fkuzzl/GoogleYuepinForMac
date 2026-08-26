#!/bin/zsh
set -euo pipefail

project_root="${0:A:h:h}"
user_temp="${TMPDIR:-/private/tmp}"
derived_data="${GOOGLE_YUEPIN_DERIVED_DATA:-${user_temp%/}/GoogleYuepinForMacDerivedData}"
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
input_source_identifier="$(/usr/libexec/PlistBuddy -c 'Print :ComponentInputModeDict:tsInputModeListKey:local.googleyuepinformac.inputmethod.GoogleYuepinIM:TISInputSourceID' "${info_plist}")"
ui_element="$(/usr/libexec/PlistBuddy -c 'Print :LSUIElement' "${info_plist}")"
background_only="$(/usr/libexec/PlistBuddy -c 'Print :LSBackgroundOnly' "${info_plist}")"
controller_class="$(/usr/libexec/PlistBuddy -c 'Print :InputMethodServerControllerClass' "${info_plist}")"

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
[[ "${input_source_identifier}" == "local.googleyuepinformac.inputmethod.GoogleYuepinIM" ]] || {
  echo "error: Unexpected component input-mode identifier: ${input_source_identifier}"
  exit 1
}
[[ "${ui_element}" == "true" ]] || {
  echo "error: Input method must run as a UI agent."
  exit 1
}
[[ "${background_only}" == "false" ]] || {
  echo "error: Input method must run as a UI agent rather than a background-only app."
  exit 1
}
[[ "${controller_class}" == "GoogleYuepinInputController" ]] || {
  echo "error: Unexpected InputMethodKit controller class: ${controller_class}"
  exit 1
}
[[ -f "${app}/Contents/Resources/InputSourceIcon.png" ]] || {
  echo "error: Input-source icon is missing from the built app."
  exit 1
}
for locale in en zh-Hant; do
  localized_info="${app}/Contents/Resources/${locale}.lproj/InfoPlist.strings"
  [[ -f "${localized_info}" ]] || {
    echo "error: ${locale} input-source localization is missing."
    exit 1
  }
  localized_mode_name="$(/usr/libexec/PlistBuddy -c 'Print :local.googleyuepinformac.inputmethod.GoogleYuepinIM' "${localized_info}")"
  [[ "${localized_mode_name}" == "Google粵拼forMac" ]] || {
    echo "error: Unexpected ${locale} input-mode name: ${localized_mode_name}"
    exit 1
  }
done
[[ -f "${app}/Contents/PkgInfo" ]] || {
  echo "error: PkgInfo is missing from the built app."
  exit 1
}

signature_details="$(/usr/bin/codesign -d --verbose=4 "${app}" 2>&1)"
if /usr/bin/grep -q '^Signature=adhoc$' <<< "${signature_details}"; then
  echo "error: Mac preflight found an ad-hoc signature."
  exit 1
fi
if ! /usr/bin/grep -Eq '^Authority=(Apple Development|Developer ID Application|Apple Distribution):' <<< "${signature_details}"; then
  echo "error: Mac preflight did not find a supported Apple signing identity."
  exit 1
fi
signed_entitlements="$(/usr/bin/codesign -d --entitlements :- "${app}" 2>&1)"
if /usr/bin/grep -q 'com.apple.security.get-task-allow' <<< "${signed_entitlements}"; then
  echo "error: Release input method contains the development-only get-task-allow entitlement."
  exit 1
fi

echo "Mac preflight: PASS"
echo "Built app: ${app}"
if /usr/bin/grep -q '^Authority=Apple Development:' <<< "${signature_details}"; then
  echo "Warning: this Personal Team build can run core tests, but macOS may reject it"
  echo "when scanning system-wide InputMethodKit apps. The installer reports that case explicitly."
fi
echo "Next: /bin/zsh Scripts/install-local.sh"
