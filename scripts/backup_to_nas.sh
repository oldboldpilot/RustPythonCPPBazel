#!/usr/bin/env bash
# NAS backup defaults align with local policy notes (host/path). Override with environment variables:
#   NAS_BACKUP_HOST, NAS_BACKUP_PATH, NAS_SSH_USER
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

NAS_BACKUP_HOST="${NAS_BACKUP_HOST:-oluwasanmi-fedora-server}"
NAS_BACKUP_PATH="${NAS_BACKUP_PATH:-/home/muyiwa/PrimaryNAS/DataFolder/PycharmProjects/RustPythonCPPBazel}"
NAS_SSH_USER="${NAS_SSH_USER:-${USER}}"

DEST="${NAS_SSH_USER}@${NAS_BACKUP_HOST}:${NAS_BACKUP_PATH}/"

SSH="${NAS_SSH_USER}@${NAS_BACKUP_HOST}"
RSYNC_SSH=(rsync -az -e 'ssh -o BatchMode=yes -o ConnectTimeout=30')

echo "NAS backup → ${SSH}:${NAS_BACKUP_PATH}/"
echo "(override defaults with NAS_BACKUP_HOST, NAS_BACKUP_PATH, NAS_SSH_USER)"

"${RSYNC_SSH[@]}" --delete \
  --exclude 'bazel-*' \
  --exclude '.cache' \
  "${ROOT}/" "${DEST}"

# Gitignored policy files are not in the public Git tree; copy them when present so the NAS mirror has them.
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
