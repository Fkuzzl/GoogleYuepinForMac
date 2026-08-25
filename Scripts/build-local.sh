#!/bin/zsh
set -euo pipefail

project_root="${0:A:h:h}"
user_temp="${TMPDIR:-/private/tmp}"
derived_data="${GOOGLE_YUEPIN_DERIVED_DATA:-${user_temp%/}/GoogleYuepinForMacDerivedData}"
app="${derived_data}/Build/Products/Release/GoogleYuepinForMac.app"
entitlements="${project_root}/GoogleYuepinForMac/GoogleYuepinForMac.entitlements"

cd "${project_root}"

development_team="${GOOGLE_YUEPIN_DEVELOPMENT_TEAM:-}"
if [[ -z "${development_team}" ]]; then
  development_team="$(
    /usr/bin/xcodebuild \
      -project GoogleYuepinForMac.xcodeproj \
      -scheme GoogleYuepinForMac \
      -configuration Release \
      -showBuildSettings 2>/dev/null | \
      /usr/bin/awk '$1 == "DEVELOPMENT_TEAM" { print $3; exit }'
  )"
fi

if [[ -z "${development_team}" ]]; then
  certificate_teams="$(
    /usr/bin/security find-identity -v -p codesigning 2>/dev/null | \
      /usr/bin/sed -nE 's/.*"Apple Development:.*\(([A-Z0-9]{10})\)".*/\1/p' | \
      /usr/bin/sort -u
  )"
  certificate_team_count="$(/usr/bin/printf '%s\n' "${certificate_teams}" | /usr/bin/awk 'NF { count++ } END { print count + 0 }')"
  if [[ "${certificate_team_count}" == "1" ]]; then
    development_team="${certificate_teams}"
  elif (( certificate_team_count > 1 )); then
    echo "error: Multiple Apple Development teams were found."
    echo "Set GOOGLE_YUEPIN_DEVELOPMENT_TEAM to the 10-character Team ID to use."
    exit 1
  fi
fi

if [[ -z "${development_team}" ]]; then
  echo "error: No Xcode development team could be resolved."
  echo "In Xcode, add your Apple ID and create an Apple Development certificate,"
  echo "or set GOOGLE_YUEPIN_DEVELOPMENT_TEAM to your 10-character Team ID."
  exit 1
fi

if [[ ! "${development_team}" =~ ^[A-Z0-9]{10}$ ]]; then
  echo "error: Invalid development Team ID: ${development_team}"
  exit 1
fi

build_number="$(/bin/date +%s)"

echo "Building and signing the Release input source with Xcode team ${development_team}..."
/usr/bin/xcodebuild \
  -project GoogleYuepinForMac.xcodeproj \
  -scheme GoogleYuepinForMac \
  -configuration Release \
  -derivedDataPath "${derived_data}" \
  -allowProvisioningUpdates \
  AD_HOC_CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_ALLOWED=YES \
  CODE_SIGN_IDENTITY="Apple Development" \
  CODE_SIGN_STYLE=Automatic \
  CURRENT_PROJECT_VERSION="${build_number}" \
  DEVELOPMENT_TEAM="${development_team}" \
  GENERATE_PKGINFO_FILE=YES \
  build

if [[ ! -d "${app}" ]]; then
  echo "error: Build succeeded but ${app} was not found."
  exit 1
fi

/usr/bin/plutil -lint "${entitlements}" >/dev/null

/usr/bin/codesign --verify --deep --strict "${app}"
signature_details="$(/usr/bin/codesign -d --verbose=4 "${app}" 2>&1)"
if /usr/bin/grep -q '^Signature=adhoc$' <<< "${signature_details}"; then
  echo "error: Xcode produced an ad-hoc signature instead of Apple Development signing."
  exit 1
fi
if ! /usr/bin/grep -q '^Authority=Apple Development:' <<< "${signature_details}"; then
  echo "error: The built app is not signed by an Apple Development certificate."
  /usr/bin/printf '%s\n' "${signature_details}"
  exit 1
fi

echo "Xcode Apple Development signing: PASS"
echo "Built app: ${app}"
