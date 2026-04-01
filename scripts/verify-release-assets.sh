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
  ruby -r yaml -r json - "$yaml_path" <<'RUBY'
    require "json"
    require "yaml"

    def normalize_candidate(raw)
      return nil unless raw.is_a?(String)

      value = raw.strip
      return nil if value.empty?

      if (value.start_with?("\"") && value.end_with?("\"")) ||
         (value.start_with?("'") && value.end_with?("'"))
        value = value[1...-1]
      end

      value = value.split("?").first if value.include?("://")
      value = File.basename(value) if value.include?("/")
      value = value.strip
      value.empty? ? nil : value
    end

    def collect_refs(payload)
      refs = []
      return refs unless payload.is_a?(Hash)

      if payload["path"].is_a?(String)
        refs << {
          path: normalize_candidate(payload["path"]),
          sha512: payload["sha512"],
          size: payload["size"],
        }
      end

      if payload["files"].is_a?(Array)
        payload["files"].each do |entry|
          next unless entry.is_a?(Hash)
          candidate = entry["path"] || entry["url"]
          refs << {
            path: normalize_candidate(candidate),
            sha512: entry["sha512"],
            size: entry["size"],
          }
        end
      end

      refs.reject { |entry| entry[:path].nil? }
    end

    yaml_path = ARGV.fetch(0)
    payload = YAML.load_file(yaml_path)
    puts JSON.generate(collect_refs(payload))
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
  MAC_REFS_JSON="$(parse_yaml_asset "$MAC_YML")"
  [[ -n "$MAC_REFS_JSON" ]] || fail "latest-mac.yml does not reference any assets"
fi

if [[ -f "$WIN_YML" ]]; then
  WIN_REFS_JSON="$(parse_yaml_asset "$WIN_YML")"
  [[ -n "$WIN_REFS_JSON" ]] || fail "latest.yml does not reference any assets"
fi

ruby - "$METADATA_PATH" "$RELEASE_DIR" "${MAC_REFS_JSON:-[]}" "${WIN_REFS_JSON:-[]}" <<'RUBY'
require 'json'
require 'yaml'
require 'digest'
require 'base64'
require 'tmpdir'

metadata_path = ARGV.fetch(0)
release_dir = ARGV.fetch(1)
mac_refs = JSON.parse(ARGV.fetch(2))
win_refs = JSON.parse(ARGV.fetch(3))
metadata = JSON.parse(File.read(metadata_path))
files = metadata.fetch('files')
raise 'release metadata files must be an array' unless files.is_a?(Array)
raise 'release metadata files array is empty' if files.empty?

def sha256_hex(path)
  Digest::SHA256.file(path).hexdigest
end

def sha512_b64(path)
  Base64.strict_encode64(Digest::SHA512.file(path).digest)
end

def ensure_file_exists!(release_dir, relative_path, label)
  full_path = File.join(release_dir, relative_path)
  raise "#{label} references missing file: #{relative_path}" unless File.file?(full_path)
  full_path
end

missing = []
invalid_sha256 = []

files.each do |entry|
  path = entry['path']
  raise 'release metadata entry path must be a non-empty string' unless path.is_a?(String) && !path.empty?
  sha256 = entry['sha256']
  unless sha256.is_a?(String) && !sha256.empty?
    invalid_sha256 << path
    next
  end
  full = File.join(release_dir, path)
  unless File.file?(full)
    missing << path
    next
  end
  actual = sha256_hex(full)
  raise "release metadata sha256 mismatch for #{path}" unless actual == sha256
end

raise "release metadata references missing files: #{missing.join(', ')}" unless missing.empty?
raise "release metadata has null/empty sha256 for: #{invalid_sha256.join(', ')}" unless invalid_sha256.empty?

checksum_path = File.join(release_dir, 'SHA256SUMS.txt')
checksum_entries = File.readlines(checksum_path, chomp: true).reject { |line| line.strip.empty? }
raise 'SHA256SUMS.txt is empty' if checksum_entries.empty?

checksum_map = {}
checksum_entries.each do |line|
  match = line.match(/\A([0-9a-fA-F]{64})\s+\*?(.+)\z/)
  raise "invalid checksum line: #{line}" unless match
  checksum_map[File.basename(match[2])] = match[1].downcase
end

top_level_files = Dir.children(release_dir)
  .map { |name| File.join(release_dir, name) }
  .select { |path| File.file?(path) }
  .map { |path| File.basename(path) }
  .reject { |name| ['SHA256SUMS.txt', 'release-metadata.json'].include?(name) }
  .sort

missing_checksums = top_level_files.reject { |name| checksum_map.key?(name) }
raise "SHA256SUMS.txt is missing entries for: #{missing_checksums.join(', ')}" unless missing_checksums.empty?

checksum_map.each do |name, expected_sha|
  full = ensure_file_exists!(release_dir, name, 'SHA256SUMS.txt')
  actual_sha = sha256_hex(full)
  raise "SHA256SUMS.txt mismatch for #{name}" unless actual_sha == expected_sha
end

def verify_updater_refs!(release_dir, label, refs)
  raise "#{label} does not reference any assets" if refs.empty?
  refs.each do |entry|
    path = entry.fetch('path')
    full = ensure_file_exists!(release_dir, path, label)

    if entry['size']
      expected_size = Integer(entry['size'])
      actual_size = File.size(full)
      raise "#{label} size mismatch for #{path}: expected #{expected_size}, got #{actual_size}" unless expected_size == actual_size
    end

    if entry['sha512'].is_a?(String) && !entry['sha512'].empty?
      actual_sha512 = sha512_b64(full)
      raise "#{label} sha512 mismatch for #{path}" unless actual_sha512 == entry['sha512']
    end
  end
end

verify_updater_refs!(release_dir, 'latest-mac.yml', mac_refs) unless mac_refs.empty?
verify_updater_refs!(release_dir, 'latest.yml', win_refs) unless win_refs.empty?

raise "release metadata references missing files: #{missing.join(', ')}" unless missing.empty?
RUBY

echo "verified release assets in $RELEASE_DIR"
