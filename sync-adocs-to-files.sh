#!/usr/bin/env bash
set -euo pipefail

DATE="${1:-$(date +%Y-%m-%d)}"
REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
ADOCS_SRC="${REPO_ROOT}/app/Adocs/${DATE}"
FILES_DST="/Users/ts-shuge.kui/Work/AIProjects/Files/${DATE}"

if [[ ! -d "${ADOCS_SRC}" ]]; then
  echo "ERROR: Adocs folder not found: ${ADOCS_SRC}"
  echo "Check: ls app/Adocs/${DATE}/"
  exit 1
fi

mkdir -p "${FILES_DST}"
cp -R "${ADOCS_SRC}/." "${FILES_DST}/"
echo "Synced: ${ADOCS_SRC}"
echo "     → ${FILES_DST}"
ls -la "${FILES_DST}"
