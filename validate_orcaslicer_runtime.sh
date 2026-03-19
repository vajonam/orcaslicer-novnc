#!/bin/bash
set -euo pipefail

root="${1:-/slic3r/squashfs-root}"

if [ ! -d "${root}" ]; then
  echo "Expected extracted AppImage directory at ${root}" >&2
  exit 1
fi

missing="$(mktemp)"
targets=("${root}/AppRun" "${root}/bin/orca-slicer")

while IFS= read -r -d '' candidate; do
  if file -L "${candidate}" | grep -q "ELF"; then
    targets+=("${candidate}")
  fi
done < <(find "${root}/lib" "${root}/usr/lib" -type f \( -name '*.so' -o -name '*.so.*' \) -print0 2>/dev/null)

for target in "${targets[@]}"; do
  if [ ! -e "${target}" ]; then
    continue
  fi

  ldd "${target}" 2>/dev/null | awk '/not found/ { print FILENAME ": " $1 " => " $3 }' FILENAME="${target}" >> "${missing}" || true
done

if [ -s "${missing}" ]; then
  echo "Missing shared libraries detected in extracted OrcaSlicer AppImage:" >&2
  sort -u "${missing}" >&2
  rm -f "${missing}"
  exit 1
fi

rm -f "${missing}"
echo "OrcaSlicer AppImage runtime dependency check passed."
