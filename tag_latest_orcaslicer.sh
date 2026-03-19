#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

echo "Checking latest stable OrcaSlicer release..."
latest_version="$(./get_latest_orcalslicer_release.sh version latest)"

if [[ -z "${latest_version}" ]]; then
  echo "Could not determine latest stable OrcaSlicer version."
  exit 1
fi

if [[ "${latest_version}" =~ ^v ]]; then
  normalized_tag="${latest_version}"
else
  normalized_tag="v${latest_version}"
fi

echo "Latest stable release resolved to: ${latest_version} (repo tag: ${normalized_tag})"

git fetch --tags origin

if git show-ref --tags --verify --quiet "refs/tags/${normalized_tag}"; then
  echo "No update: tag ${normalized_tag} already exists."
  exit 0
fi

echo "New stable release found. Creating annotated tag ${normalized_tag} on current HEAD..."
git tag -a "${normalized_tag}" -m "OrcaSlicer container release ${normalized_tag}"

echo "Pushing tag ${normalized_tag}..."
git push origin "${normalized_tag}"
echo "Tag push complete."
