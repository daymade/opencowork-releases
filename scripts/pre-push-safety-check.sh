#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

bash tests/release-scripts.sh

rg -q 'assert-public-artifact-safety\.sh' .github/workflows/release.yml \
  || { echo "FAIL: release workflow must run assert-public-artifact-safety.sh before uploading artifacts" >&2; exit 1; }

if rg -q 'echo "  source_repository=' .github/workflows/release.yml; then
  echo "FAIL: public release workflow must not log source_repository" >&2
  exit 1
fi

if rg -q 'echo "  head_sha=' .github/workflows/release.yml; then
  echo "FAIL: public release workflow must not log source head_sha" >&2
  exit 1
fi
