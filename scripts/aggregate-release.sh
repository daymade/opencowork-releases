#!/usr/bin/env bash
set -euo pipefail

ARTIFACTS_DIR=""
RELEASE_DIR=""
INTERNAL_DIR=""
VERSION=""
SOURCE_REPOSITORY=""
SOURCE_REF=""
SOURCE_HEAD_SHA=""

fail() {
  echo "error: $*" >&2
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --artifacts-dir)
      ARTIFACTS_DIR="${2:-}"
      shift 2
      ;;
    --release-dir)
      RELEASE_DIR="${2:-}"
      shift 2
      ;;
    --internal-dir)
      INTERNAL_DIR="${2:-}"
      shift 2
      ;;
    --version)
      VERSION="${2:-}"
      shift 2
      ;;
    --source-repository)
      SOURCE_REPOSITORY="${2:-}"
      shift 2
      ;;
    --source-ref)
      SOURCE_REF="${2:-}"
      shift 2
      ;;
    --source-head-sha)
      SOURCE_HEAD_SHA="${2:-}"
      shift 2
      ;;
    --help|-h)
      cat <<'EOF'
Usage:
  scripts/aggregate-release.sh \
    --artifacts-dir <dir> \
    --release-dir <dir> \
    --internal-dir <dir> \
    --version <version> \
    --source-repository <repo> \
    --source-ref <ref> \
    --source-head-sha <sha>
EOF
      exit 0
      ;;
    *)
      fail "unknown option: $1"
      ;;
  esac
done

[[ -n "$ARTIFACTS_DIR" ]] || fail "missing --artifacts-dir"
[[ -n "$RELEASE_DIR" ]] || fail "missing --release-dir"
[[ -n "$INTERNAL_DIR" ]] || fail "missing --internal-dir"
[[ -n "$VERSION" ]] || fail "missing --version"
[[ -n "$SOURCE_REPOSITORY" ]] || fail "missing --source-repository"
[[ -n "$SOURCE_REF" ]] || fail "missing --source-ref"
[[ -n "$SOURCE_HEAD_SHA" ]] || fail "missing --source-head-sha"

mkdir -p "$RELEASE_DIR" "$INTERNAL_DIR"

find "$ARTIFACTS_DIR" -type f \( \
  -name 'OpenCoWork-*.dmg' -o \
  -name 'OpenCoWork-*.zip' -o \
  -name 'OpenCoWork-*.blockmap' -o \
  -name 'OpenCoWork-*.exe' -o \
  -name '*.yml' \
\) -exec cp {} "$RELEASE_DIR"/ \;

find "$RELEASE_DIR" -maxdepth 1 -type f -print0 | sort -z | xargs -0 shasum -a 256 > "$RELEASE_DIR/SHA256SUMS.txt"

ruby <<'RUBY'
require 'json'
require 'time'

release_dir = ENV.fetch('RELEASE_DIR')
internal_dir = ENV.fetch('INTERNAL_DIR')
version = ENV.fetch('RELEASE_VERSION')
source_repository = ENV.fetch('SOURCE_REPOSITORY')
source_ref = ENV.fetch('SOURCE_REF')
source_head_sha = ENV.fetch('SOURCE_HEAD_SHA')

files = Dir.glob(File.join(release_dir, '*'))
  .select { |path| File.file?(path) }
  .map { |path| File.basename(path) }
  .reject { |name| name == 'SHA256SUMS.txt' }
  .sort

raise 'no release artifacts were aggregated' if files.empty?

checksum_map = {}
checksum_path = File.join(release_dir, 'SHA256SUMS.txt')
File.readlines(checksum_path, chomp: true).each do |line|
  next if line.strip.empty?
  sha, file = line.split(/\s+/, 2)
  checksum_map[file.sub(/\A\*/, '')] = sha
end

metadata = {
  product_name: 'OpenCoWork',
  version: version,
  tag_name: "v#{version}",
  source_repository: source_repository,
  source_ref: source_ref,
  source_head_sha: source_head_sha,
  generated_at: Time.now.utc.iso8601,
  files: files.map { |name| { path: name, sha256: checksum_map[name] } }
}

metadata_json = JSON.pretty_generate(metadata) + "\n"
File.write(File.join(internal_dir, 'release-metadata.json'), metadata_json)
File.write(File.join(release_dir, 'release-metadata.json'), metadata_json)

lines = []
lines << "## OpenCoWork v#{version}"
lines << ''
lines << '### Install'
lines << ''
if files.any? { |name| name.end_with?('.dmg') }
  lines << "- macOS: download `OpenCoWork-#{version}-arm64.dmg` and drag OpenCoWork into `Applications`"
end
if files.any? { |name| name.end_with?('.exe') }
  lines << "- Windows: run `OpenCoWork-#{version}-x64.exe`"
end
lines << ''
lines << '### Update'
lines << ''
mac_update_metadata = files.select { |name| name == 'latest-mac.yml' }.sort
windows_update_metadata = files.select { |name| name == 'latest.yml' }.sort
mac_zip_assets = files.select { |name| name.match?(/^OpenCoWork-.*\.zip$/) && name.include?('-arm64') }.sort
windows_zip_assets = files.select { |name| name.match?(/^OpenCoWork-.*\.zip$/) && name.include?('-x64') }.sort
windows_installers = files.select { |name| name.end_with?('.exe') }.sort
mac_installers = files.select { |name| name.end_with?('.dmg') }.sort

errors = []
if !mac_installers.empty? && mac_update_metadata.empty?
  errors << 'macOS distributables are present but no *-mac.yml metadata was aggregated'
end
if !mac_installers.empty? && mac_zip_assets.empty?
  errors << 'macOS DMG is present but no macOS ZIP artifact was aggregated'
end
if !windows_installers.empty? && windows_update_metadata.empty?
  errors << 'Windows installer is present but no Windows updater metadata (*.yml) was aggregated'
end
if !windows_installers.empty? && windows_zip_assets.empty?
  errors << 'Windows installer is present but no Windows ZIP artifact was aggregated'
end
raise errors.join("\n") unless errors.empty?

if !mac_update_metadata.empty?
  lines << "- macOS updater metadata: #{mac_update_metadata.map { |name| "`#{name}`" }.join(', ')}"
end
if !windows_update_metadata.empty?
  lines << "- Windows updater metadata: #{windows_update_metadata.map { |name| "`#{name}`" }.join(', ')} (NSIS installer feed)"
end
notes = lines.join("\n") + "\n"
File.write(File.join(internal_dir, 'release-notes.md'), notes)
RUBY
