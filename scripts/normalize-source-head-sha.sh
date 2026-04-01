#!/usr/bin/env bash
set -euo pipefail

REQUESTED_SHA=""
RESOLVED_SHA=""

fail() {
  echo "error: $*" >&2
  exit 1
}

normalize_sha() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --requested-sha)
      REQUESTED_SHA="${2:-}"
      shift 2
      ;;
    --resolved-sha)
      RESOLVED_SHA="${2:-}"
      shift 2
      ;;
    --help|-h)
      cat <<'EOF'
Usage:
  scripts/normalize-source-head-sha.sh --resolved-sha <full_sha> [--requested-sha <full_or_prefix_sha>]
EOF
      exit 0
      ;;
    *)
      fail "unknown option: $1"
      ;;
  esac
done

RESOLVED_SHA="$(normalize_sha "$RESOLVED_SHA")"
REQUESTED_SHA="$(normalize_sha "$REQUESTED_SHA")"

[[ "$RESOLVED_SHA" =~ ^[0-9a-f]{40}$ ]] || fail "resolved SHA must be a full 40-character commit SHA"

if [[ -z "$REQUESTED_SHA" ]]; then
  printf '%s\n' "$RESOLVED_SHA"
  exit 0
fi

[[ "$REQUESTED_SHA" =~ ^[0-9a-f]{7,40}$ ]] || fail "requested SHA must be a 7-40 character hex SHA prefix"

if [[ "$RESOLVED_SHA" != "$REQUESTED_SHA" && "$RESOLVED_SHA" != "$REQUESTED_SHA"* ]]; then
  fail "requested SHA $REQUESTED_SHA does not match resolved source ref SHA $RESOLVED_SHA"
fi

printf '%s\n' "$RESOLVED_SHA"
