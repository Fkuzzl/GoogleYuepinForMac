#!/bin/zsh
set -euo pipefail

project_root="${0:A:h:h}"
user_temp="${TMPDIR:-/private/tmp}"
derived_data="${GOOGLE_YUEPIN_DERIVED_DATA:-${user_temp%/}/GoogleYuepinForMacDerivedData}"
source_app="${derived_data}/Build/Products/Release/GoogleYuepinForMac.app"
destination_directory="${HOME}/Library/Input Methods"
destination_app="${destination_directory}/GoogleYuepinForMac.app"
legacy_system_app="/Library/Input Methods/GoogleYuepinForMac.app"
lsregister="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"

cd "${project_root}"

/bin/zsh "${project_root}/Scripts/build-local.sh"

if [[ ! -d "${source_app}" ]]; then
  echo "error: Build succeeded but ${source_app} was not found."
  exit 1
fi

if [[ -d "${legacy_system_app}" || -d "${destination_app}" ]]; then
  /usr/bin/osascript -e 'tell application id "local.googleyuepinformac.inputmethod" to quit' >/dev/null 2>&1 || true
fi

if [[ -d "${legacy_system_app}" ]]; then
  echo "Removing the earlier system-wide development copy..."
  "${lsregister}" -u "${legacy_system_app}" >/dev/null 2>&1 || true
  /usr/bin/sudo /bin/rm -rf "${legacy_system_app}"
fi

if [[ -d "${destination_app}" ]]; then
  "${lsregister}" -u "${destination_app}" >/dev/null 2>&1 || true
  /bin/rm -rf "${destination_app}"
fi

/bin/mkdir -p "${destination_directory}"
/usr/bin/ditto "${source_app}" "${destination_app}"
/usr/bin/xattr -cr "${destination_app}"
/usr/bin/codesign --verify --deep --strict --verbose=2 "${destination_app}"
"${lsregister}" -f "${destination_app}"

if ! "${destination_app}/Contents/MacOS/GoogleYuepinForMac" --register; then
  echo "error: macOS rejected input-source registration."
  exit 1
fi

/usr/bin/killall imklaunchagent >/dev/null 2>&1 || true
/usr/bin/killall TextInputMenuAgent >/dev/null 2>&1 || true
/bin/sleep 1

enabled=false
for attempt in {1..10}; do
  if "${destination_app}/Contents/MacOS/GoogleYuepinForMac" --enable; then
    enabled=true
    break
  fi
  /bin/sleep 0.5
done

if [[ "${enabled}" != true ]]; then
  echo "error: macOS registered the app but did not expose its input source after 10 attempts."
  exit 1
fi

/usr/bin/open "${destination_app}" >/dev/null 2>&1 || true

echo "Installed ${destination_app}"
echo "Registered and enabled Google粵拼forMac for the current user."
echo "If the input menu does not refresh immediately, log out and back in once."
