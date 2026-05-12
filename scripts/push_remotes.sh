#!/usr/bin/env bash
# Push current branch to GitHub (origin), then to Gitea if GITEA_PUSH_URL is set in the environment.
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

branch="$(git branch --show-current)"
if ! git remote get-url origin &>/dev/null; then
  echo "error: git remote 'origin' is not configured (GitHub)." >&2
  exit 1
fi

echo "Pushing to origin (${branch})…"
git push origin "${branch}"

if [[ -n "${GITEA_PUSH_URL:-}" ]]; then
  if git remote get-url gitea &>/dev/null; then
    current="$(git remote get-url gitea)"
    if [[ "${current}" != "${GITEA_PUSH_URL}" ]]; then
      git remote set-url gitea "${GITEA_PUSH_URL}"
    fi
  else
    git remote add gitea "${GITEA_PUSH_URL}"
  fi
  echo "Pushing to gitea (${branch})…"
  git push gitea "${branch}"
else
  echo "Skipping Gitea (export GITEA_PUSH_URL to enable)."
fi
