#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

set_github_output() {
  if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
    printf '%s=%s\n' "$1" "$2" >> "${GITHUB_OUTPUT}"
  fi
}

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
  set_github_output "tag_created" "false"
  set_github_output "tag_name" "${normalized_tag}"
  exit 0
fi

git_user_name="$(git config user.name || true)"
git_user_email="$(git config user.email || true)"

if [[ -z "${git_user_name}" || -z "${git_user_email}" ]]; then
  fallback_name="${GIT_TAGGER_NAME:-GitHub Actions}"
  fallback_email="${GIT_TAGGER_EMAIL:-github-actions[bot]@users.noreply.github.com}"
  echo "Git committer identity is not configured. Using ${fallback_name} <${fallback_email}> for tag creation."
  git config user.name "${fallback_name}"
  git config user.email "${fallback_email}"
fi

echo "New stable release found. Creating annotated tag ${normalized_tag} on current HEAD..."
git tag -a "${normalized_tag}" -m "OrcaSlicer container release ${normalized_tag}"

echo "Pushing tag ${normalized_tag}..."
git push origin "${normalized_tag}"
echo "Tag push complete."
set_github_output "tag_created" "true"
set_github_output "tag_name" "${normalized_tag}"
