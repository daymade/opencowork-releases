#!/usr/bin/env bash
set -euo pipefail

RELEASE_DIR=""
METADATA_PATH=""

fail() {
  echo "error: $*" >&2
  exit 1
}

parse_yaml_asset() {
  local yaml_path="$1"
  ruby <<'RUBY' "$yaml_path"
yaml_path = ARGV.fetch(0)
content = File.read(yaml_path)
path_match = content.match(/^path:\s*(.+)$/)
url_match = content.match(/^[ \t]*-?[ \t]*url:\s*(.+)$/)
value = path_match && path_match[1] || url_match && url_match[1] || ''
value = value.strip
if (value.start_with?('"') && value.end_with?('"')) || (value.start_with?("'") && value.end_with?("'"))
  value = value[1..-2]
end
print value
RUBY
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --release-dir)
      RELEASE_DIR="${2:-}"
      shift 2
      ;;
    --metadata)
      METADATA_PATH="${2:-}"
      shift 2
      ;;
    --help|-h)
      cat <<'EOF'
Usage:
  scripts/verify-release-assets.sh --release-dir <dir> [--metadata <path>]
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
[[ -n "$METADATA_PATH" ]] || METADATA_PATH="$RELEASE_DIR/release-metadata.json"
[[ -f "$METADATA_PATH" ]] || fail "release metadata not found: $METADATA_PATH"
[[ -f "$RELEASE_DIR/SHA256SUMS.txt" ]] || fail "SHA256SUMS.txt not found in $RELEASE_DIR"

MAC_DMG="$(find "$RELEASE_DIR" -maxdepth 1 -type f -name 'OpenCoWork-*.dmg' | head -1 || true)"
MAC_ZIP="$(find "$RELEASE_DIR" -maxdepth 1 -type f -name 'OpenCoWork-*.zip' | grep 'arm64' | head -1 || true)"
WIN_EXE="$(find "$RELEASE_DIR" -maxdepth 1 -type f -name 'OpenCoWork-*.exe' | head -1 || true)"
WIN_ZIP="$(find "$RELEASE_DIR" -maxdepth 1 -type f -name 'OpenCoWork-*.zip' | grep 'x64' | head -1 || true)"
MAC_YML="$RELEASE_DIR/latest-mac.yml"
WIN_YML="$RELEASE_DIR/latest.yml"

if [[ -n "$MAC_DMG" ]]; then
  [[ -f "$MAC_YML" ]] || fail "macOS DMG present but latest-mac.yml missing"
  [[ -n "$MAC_ZIP" ]] || fail "macOS DMG present but macOS ZIP missing"
fi

if [[ -n "$WIN_EXE" ]]; then
  [[ -f "$WIN_YML" ]] || fail "Windows installer present but latest.yml missing"
  [[ -n "$WIN_ZIP" ]] || fail "Windows installer present but Windows ZIP missing"
fi

if [[ -f "$MAC_YML" ]]; then
  MAC_REF="$(parse_yaml_asset "$MAC_YML")"
  [[ -n "$MAC_REF" ]] || fail "latest-mac.yml does not reference an asset"
  [[ -f "$RELEASE_DIR/$MAC_REF" ]] || fail "latest-mac.yml references missing asset: $MAC_REF"
fi

if [[ -f "$WIN_YML" ]]; then
  WIN_REF="$(parse_yaml_asset "$WIN_YML")"
  [[ -n "$WIN_REF" ]] || fail "latest.yml does not reference an asset"
  [[ -f "$RELEASE_DIR/$WIN_REF" ]] || fail "latest.yml references missing asset: $WIN_REF"
fi

ruby <<'RUBY' "$METADATA_PATH" "$RELEASE_DIR"
require 'json'

metadata_path = ARGV.fetch(0)
release_dir = ARGV.fetch(1)
metadata = JSON.parse(File.read(metadata_path))
files = metadata.fetch('files')
raise 'release metadata files must be an array' unless files.is_a?(Array)
raise 'release metadata files array is empty' if files.empty?

missing = files.filter_map do |entry|
  path = entry['path']
  next unless path.is_a?(String) && !path.empty?
  full = File.join(release_dir, path)
  path unless File.file?(full)
end

raise "release metadata references missing files: #{missing.join(', ')}" unless missing.empty?
RUBY

while read -r sha file; do
  file="${file#\*}"
  [[ -n "$sha" ]] || continue
  [[ -f "$RELEASE_DIR/$file" ]] || fail "checksum references missing file: $file"
done < "$RELEASE_DIR/SHA256SUMS.txt"

echo "verified release assets in $RELEASE_DIR"
