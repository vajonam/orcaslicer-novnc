#!/bin/bash

set -euo pipefail

TMPDIR="$(mktemp -d)"
trap 'rm -rf "${TMPDIR}"' EXIT

requested_version="${2:-latest}"

# Fetch all releases (both latest stable and pre-releases)
curl -SsL https://api.github.com/repos/OrcaSlicer/OrcaSlicer/releases > "${TMPDIR}/releases.json"

appimage_asset_filter='((.name // "") | test("(?i)\\.AppImage$")) or ((.browser_download_url // "") | test("(?i)\\.AppImage$"))'
stable_release_filter=".[] | select((.draft | not) and (.prerelease | not)) | select(any(.assets[]?; ${appimage_asset_filter}))"
release_filter=".[] | select(.draft | not) | select(any(.assets[]?; ${appimage_asset_filter}))"
asset_selector='([.assets[] | select('"${appimage_asset_filter}"')] | .[0])'

if [ "${requested_version}" = "latest" ]; then
  selector="([${stable_release_filter}][0] // [${release_filter}][0])"
else
  selector="[${release_filter} | select(.tag_name == \$tag)][0]"
fi

url=$(jq -r --arg tag "${requested_version}" "${selector} | ${asset_selector}.browser_download_url" "${TMPDIR}/releases.json")
name=$(jq -r --arg tag "${requested_version}" "${selector} | ${asset_selector}.name" "${TMPDIR}/releases.json")
version=$(jq -r --arg tag "${requested_version}" "${selector}.tag_name" "${TMPDIR}/releases.json")

if [ $# -lt 1 ] || [ $# -gt 2 ]; then
  echo "Wrong number of params"
  exit 1
else
  request=$1
fi

if [ "${url}" = "null" ] || [ "${name}" = "null" ] || [ "${version}" = "null" ]; then
  echo "Unable to find OrcaSlicer AppImage release for version '${requested_version}'" >&2
  exit 1
fi

case $request in

  url)
    echo $url
    ;;

  name)
    echo $name
    ;;

  version)
    echo $version
    ;;

  *)
    echo "Unknown request"
    ;;
esac
