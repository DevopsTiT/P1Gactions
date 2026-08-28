#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "${REPO_ROOT}"

MSG="${1:-docs: auto-push Adocs $(date +%Y-%m-%d)}"

git add app/Adocs/ .cursor/rules/ sync-adocs-to-files.sh auto-push-adocs.sh 2>/dev/null || true

if git diff --cached --quiet; then
  echo "Nothing to commit."
else
  git commit -m "${MSG}"
fi

git push -u origin main

if [[ -x "${REPO_ROOT}/sync-adocs-to-files.sh" ]] && [[ -d "/Users/ts-shuge.kui/Work/AIProjects/Files" ]]; then
  "${REPO_ROOT}/sync-adocs-to-files.sh" "$(date +%Y-%m-%d)"
fi
