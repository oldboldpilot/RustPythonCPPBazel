#!/usr/bin/env bash
# NAS backup per config/update_policy.txt:
#   - Host: oluwasanmi-fedora-server (passwordless SSH)
#   - Path: /home/muyiwa/PrimaryNAS/DataFolder/PycharmProjects/RustPythonCPPBazel
# Override via config/.env: NAS_BACKUP_HOST, NAS_BACKUP_PATH, NAS_SSH_USER
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

if [[ -f config/.env ]]; then
  set -a
  # shellcheck disable=SC1091
  source config/.env
  set +a
fi

NAS_BACKUP_HOST="${NAS_BACKUP_HOST:-oluwasanmi-fedora-server}"
NAS_BACKUP_PATH="${NAS_BACKUP_PATH:-/home/muyiwa/PrimaryNAS/DataFolder/PycharmProjects/RustPythonCPPBazel}"
NAS_SSH_USER="${NAS_SSH_USER:-${USER}}"

DEST="${NAS_SSH_USER}@${NAS_BACKUP_HOST}:${NAS_BACKUP_PATH}/"

echo "NAS backup → ${NAS_SSH_USER}@${NAS_BACKUP_HOST}:${NAS_BACKUP_PATH}/"
echo "(defaults match config/update_policy.txt; override with NAS_* in config/.env)"

rsync -az --delete \
  -e 'ssh -o BatchMode=yes -o ConnectTimeout=30' \
  --exclude 'bazel-*' \
  --exclude '.cache' \
  "${ROOT}/" "${DEST}"

echo "NAS backup finished."
