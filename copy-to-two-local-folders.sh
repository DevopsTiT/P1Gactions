#!/usr/bin/env bash
set -euo pipefail
DATE="${1:-$(date +%Y-%m-%d)}"
REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
ADOCS_DST="${REPO_ROOT}/app/Adocs/${DATE}"
FILES_DST="${HOME}/Work/AIProjects/Files/${DATE}"
TAR="${REPO_ROOT}/mobile-answers-${DATE}.tar.gz"

if [[ ! -d "${ADOCS_DST}" ]] || [[ -z "$(ls -A "${ADOCS_DST}" 2>/dev/null)" ]]; then
  [[ -f "${TAR}" ]] || { echo "ERROR: missing ${TAR}"; exit 1; }
  mkdir -p "${REPO_ROOT}/app/Adocs"
  tar xzf "${TAR}" -C "${REPO_ROOT}/app/Adocs"
fi

mkdir -p "${FILES_DST}"
cp -R "${ADOCS_DST}/." "${FILES_DST}/"
echo "DONE"
echo "  [1] Adocs: ${ADOCS_DST}"
echo "  [2] Files: ${FILES_DST}"
ls "${ADOCS_DST}"
