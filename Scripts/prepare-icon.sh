#!/bin/zsh
set -euo pipefail

source_svg="${SRCROOT}/GoogleYuepinForMac/Resources/InputSourceIcon.svg"
output_directory="${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
output_png="${output_directory}/InputSourceIcon.png"

if [[ ! -f "${source_svg}" ]]; then
  echo "error: Missing ${source_svg}"
  exit 1
fi

/bin/mkdir -p "${output_directory}"
/usr/bin/qlmanage -t -s 256 -o "${TMPDIR}" "${source_svg}" >/dev/null 2>&1
generated="${TMPDIR}/InputSourceIcon.svg.png"
if [[ ! -f "${generated}" ]]; then
  echo "error: macOS could not render InputSourceIcon.svg"
  exit 1
fi
/bin/mv "${generated}" "${output_png}"
