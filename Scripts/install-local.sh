#!/bin/zsh
set -euo pipefail

project_root="${0:A:h:h}"
user_temp="${TMPDIR:-/private/tmp}"
derived_data="${GOOGLE_YUEPIN_DERIVED_DATA:-${user_temp%/}/GoogleYuepinForMacDerivedData}"
source_app="${derived_data}/Build/Products/Release/GoogleYuepinForMac.app"
destination_app="/Library/Input Methods/GoogleYuepinForMac.app"
lsregister="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"

cd "${project_root}"

/bin/zsh "${project_root}/Scripts/build-local.sh"

if [[ ! -d "${source_app}" ]]; then
  echo "error: Build succeeded but ${source_app} was not found."
  exit 1
fi

if [[ -d "${destination_app}" ]]; then
  /usr/bin/osascript -e 'tell application id "local.googleyuepinformac.inputmethod" to quit' >/dev/null 2>&1 || true
  "${lsregister}" -u "${destination_app}" >/dev/null 2>&1 || true
fi

/usr/bin/sudo /bin/mkdir -p "/Library/Input Methods"
/usr/bin/sudo /bin/rm -rf "${destination_app}"
/usr/bin/sudo /usr/bin/ditto "${source_app}" "${destination_app}"
"${lsregister}" -f "${destination_app}"

if ! "${destination_app}/Contents/MacOS/GoogleYuepinForMac" --register; then
  echo "error: macOS copied the app but did not recognize its input source."
  exit 1
fi

/usr/bin/killall imklaunchagent >/dev/null 2>&1 || true
/usr/bin/killall TextInputMenuAgent >/dev/null 2>&1 || true
/usr/bin/open "${destination_app}" >/dev/null 2>&1 || true

echo "Installed ${destination_app}"
echo "Registered and enabled Google粵拼forMac for the current user."
echo "If the input menu does not refresh immediately, log out and back in once."
