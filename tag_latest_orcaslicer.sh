#!/bin/bash
set -eu

# ** start of configurable variables **
GH_ACTION="y"
# ** end of configurable variables **

# Get the latest tagged version (from your helper script)
LATEST_VERSION=$(./get_latest_orcalslicer_release.sh version)

if [[ -z "${LATEST_VERSION}" ]]; then
  echo "Could not determine the latest version."
  exit 1
fi

# Ensure we are running in the repository directory
cd "$(dirname "$0")";

# Fetch tags from the remote repository so that our local tag list is updated
git fetch --tags

# Check if the tag already exists
if git rev-parse "$LATEST_VERSION" >/dev/null 2>&1; then
  echo "Tag ${LATEST_VERSION} already exists in remote. No update needed."
  exit 0
fi

echo "Update needed. Creating tag ${LATEST_VERSION}..."
git tag "${LATEST_VERSION}"

if [[ "$GH_ACTION" != "" ]]; then
  echo "${LATEST_VERSION}" > "${GITHUB_WORKSPACE}/VERSION"
  git push https://$GITHUB_ACTOR:$GITHUB_TOKEN@github.com/$GITHUB_REPOSITORY --tags
else
  git push --tags
fi
