#!/usr/bin/env bash
set -euo pipefail

RELEASE_DIR=""
PLATFORM=""

fail() {
  echo "error: $*" >&2
  exit 1
}

collect_top_level() {
  local pattern="$1"
  find "$RELEASE_DIR" -maxdepth 1 -type f -name "$pattern" | sort
}

require_match() {
  local pattern="$1"
  local label="$2"
  local matches

  matches="$(collect_top_level "$pattern")"
  [[ -n "$matches" ]] || fail "missing $label in $RELEASE_DIR"
  printf '%s\n' "$matches"
}

require_file() {
  local file_path="$1"
  local label="$2"
  [[ -f "$file_path" ]] || fail "missing $label: $file_path"
  printf '%s\n' "$file_path"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --release-dir)
      RELEASE_DIR="${2:-}"
      shift 2
      ;;
    --platform)
      PLATFORM="${2:-}"
      shift 2
      ;;
    --help|-h)
      cat <<'EOF'
Usage:
  scripts/collect-release-files.sh --release-dir <dir> --platform windows|macos
EOF
      exit 0
      ;;
    *)
      fail "unknown option: $1"
      ;;
  esac
done

[[ -n "$RELEASE_DIR" ]] || fail "missing --release-dir"
[[ -d "$RELEASE_DIR" ]] || fail "release directory not found: $RELEASE_DIR"
[[ "$PLATFORM" == "windows" || "$PLATFORM" == "macos" ]] || fail "invalid --platform: $PLATFORM"

case "$PLATFORM" in
  windows)
    require_match 'OpenCoWork-*-x64.exe' 'Windows installer'
    require_match 'OpenCoWork-*-x64.zip' 'Windows ZIP artifact'
    collect_top_level 'OpenCoWork-*.blockmap'
    require_match 'latest.yml' 'Windows updater metadata'
    ;;
  macos)
    require_match 'OpenCoWork-*-arm64.dmg' 'macOS DMG artifact'
    require_match 'OpenCoWork-*-arm64.zip' 'macOS ZIP artifact'
    collect_top_level 'OpenCoWork-*.blockmap'
    require_match 'latest-mac.yml' 'macOS updater metadata'
    ;;
esac

require_file "$RELEASE_DIR/_internal/release-metadata.json" 'release metadata'
require_file "$RELEASE_DIR/_internal/release-notes.md" 'release notes'
