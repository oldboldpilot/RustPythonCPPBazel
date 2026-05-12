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

SSH="${NAS_SSH_USER}@${NAS_BACKUP_HOST}"
RSYNC_SSH=(rsync -az -e 'ssh -o BatchMode=yes -o ConnectTimeout=30')

echo "NAS backup → ${SSH}:${NAS_BACKUP_PATH}/"
echo "(defaults match config/update_policy.txt; override with NAS_* in config/.env)"

"${RSYNC_SSH[@]}" --delete \
  --exclude 'bazel-*' \
  --exclude '.cache' \
  "${ROOT}/" "${DEST}"

# Gitignored policy files are not on GitHub but should exist on the NAS mirror.
POLICY_FILES=(config/update_policy.txt config/cpp_details.txt)
existing=()
for f in "${POLICY_FILES[@]}"; do
  if [[ -f "${ROOT}/${f}" ]]; then
    existing+=("${ROOT}/${f}")
  else
    echo "warning: missing local file (not on NAS): ${f}" >&2
  fi
done
if ((${#existing[@]} > 0)); then
  echo "Copying policy files to NAS → ${DEST}config/ …"
  "${RSYNC_SSH[@]}" "${existing[@]}" "${SSH}:${NAS_BACKUP_PATH}/config/"
fi

echo "NAS backup finished."
