#!/bin/bash

set -euo pipefail

TMPDIR="$(mktemp -d)"
trap 'rm -rf "${TMPDIR}"' EXIT

requested_version="${2:-latest}"
api_root="https://api.github.com/repos/SoftFever/OrcaSlicer"
api_headers=(
  -H "Accept: application/vnd.github+json"
  -H "User-Agent: orcaslicer-novnc-build"
)

if [ -n "${GITHUB_TOKEN:-}" ]; then
  api_headers+=(-H "Authorization: Bearer ${GITHUB_TOKEN}")
fi

if [ $# -lt 1 ] || [ $# -gt 2 ]; then
  echo "Wrong number of params"
  exit 1
else
  request=$1
fi

fetch_json() {
  local url="$1"
  local out="$2"
  curl -fsSL --retry 5 --retry-delay 2 --retry-all-errors "${api_headers[@]}" "${url}" -o "${out}"
}

if [ "${requested_version}" = "latest" ]; then
  fetch_json "${api_root}/releases/latest" "${TMPDIR}/release.json"
else
  fetch_json "${api_root}/releases/tags/${requested_version}" "${TMPDIR}/release.json"
fi

if ! jq -e 'type == "object" and has("tag_name")' "${TMPDIR}/release.json" >/dev/null; then
  echo "Unexpected GitHub API response while resolving OrcaSlicer release '${requested_version}'." >&2
  jq -r '.message // "No API error message provided."' "${TMPDIR}/release.json" >&2 || true
  exit 1
fi

# Prefer explicit x86_64/amd64 AppImage naming, fallback to any AppImage.
url=$(jq -r '
  (
    [.assets[]? | select(((.name // "") | test("(?i)(x86_64|amd64).*\\.AppImage$")) or ((.browser_download_url // "") | test("(?i)(x86_64|amd64).*\\.AppImage$")))] |
    .[0]
  ) // (
    [.assets[]? | select(((.name // "") | test("(?i)\\.AppImage$")) or ((.browser_download_url // "") | test("(?i)\\.AppImage$")))] |
    .[0]
  ) | .browser_download_url // "null"
' "${TMPDIR}/release.json")

name=$(jq -r '
  (
    [.assets[]? | select(((.name // "") | test("(?i)(x86_64|amd64).*\\.AppImage$")) or ((.browser_download_url // "") | test("(?i)(x86_64|amd64).*\\.AppImage$")))] |
    .[0]
  ) // (
    [.assets[]? | select(((.name // "") | test("(?i)\\.AppImage$")) or ((.browser_download_url // "") | test("(?i)\\.AppImage$")))] |
    .[0]
  ) | .name // "null"
' "${TMPDIR}/release.json")

version=$(jq -r '.tag_name // "null"' "${TMPDIR}/release.json")

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
