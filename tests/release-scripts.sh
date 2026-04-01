#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

write_file() {
  local target_path="$1"
  local content="$2"
  mkdir -p "$(dirname "$target_path")"
  printf '%s' "$content" > "$target_path"
}

append_sha256() {
  local file_name="$1"
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$file_name" >> SHA256SUMS.txt
  elif command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$file_name" >> SHA256SUMS.txt
  else
    fail "missing shasum/sha256sum"
  fi
}

test_aggregate_release_populates_sha256() {
  local tmp_dir artifacts_dir release_dir internal_dir metadata_path
  tmp_dir="$(mktemp -d)"
  artifacts_dir="$tmp_dir/artifacts"
  release_dir="$tmp_dir/release"
  internal_dir="$tmp_dir/internal"

  write_file "$artifacts_dir/OpenCoWork-0.1.4-beta.2-arm64.dmg" "dmg"
  write_file "$artifacts_dir/OpenCoWork-0.1.4-beta.2-arm64.zip" "zip"
  write_file "$artifacts_dir/OpenCoWork-0.1.4-beta.2-arm64.zip.blockmap" "blockmap"
  write_file "$artifacts_dir/OpenCoWork-0.1.4-beta.2-x64.exe" "exe"
  write_file "$artifacts_dir/OpenCoWork-0.1.4-beta.2-x64.zip" "winzip"
  write_file "$artifacts_dir/OpenCoWork-0.1.4-beta.2-x64.exe.blockmap" "winblockmap"
  cat > "$artifacts_dir/latest-mac.yml" <<'EOF'
version: 0.1.4-beta.2
path: OpenCoWork-0.1.4-beta.2-arm64.zip
sha512: dummy
EOF
  cat > "$artifacts_dir/latest.yml" <<'EOF'
version: 0.1.4-beta.2
path: OpenCoWork-0.1.4-beta.2-x64.exe
sha512: dummy
EOF

  bash "$REPO_ROOT/scripts/aggregate-release.sh" \
    --artifacts-dir "$artifacts_dir" \
    --release-dir "$release_dir" \
    --internal-dir "$internal_dir" \
    --version 0.1.4-beta.2 \
    --source-repository daymade/opencowork \
    --source-ref refs/heads/codex/release-drill-20260329 \
    --source-head-sha a3eab03db7a990427b5d6a9596bdfb46866d8790

  metadata_path="$release_dir/release-metadata.json"
  ruby -r json -e '
    metadata = JSON.parse(File.read(ARGV.fetch(0)))
    files = metadata.fetch("files")
    abort("files missing") unless files.is_a?(Array) && !files.empty?
    invalid = files.reject { |entry| entry["sha256"].is_a?(String) && !entry["sha256"].empty? }
    abort("sha256 missing for: #{invalid.map { |entry| entry["path"] }.join(", ")}") unless invalid.empty?
    forbidden = %w[source_repository source_ref source_head_sha] & metadata.keys
    abort("public metadata leaked source fields: #{forbidden.join(", ")}") unless forbidden.empty?
  ' "$metadata_path" || fail "aggregate-release.sh wrote null sha256 values"
}

test_aggregate_release_requires_windows_artifacts() {
  local tmp_dir artifacts_dir release_dir internal_dir
  tmp_dir="$(mktemp -d)"
  artifacts_dir="$tmp_dir/artifacts"
  release_dir="$tmp_dir/release"
  internal_dir="$tmp_dir/internal"

  write_file "$artifacts_dir/OpenCoWork-0.1.4-beta.2-arm64.dmg" "dmg"
  write_file "$artifacts_dir/OpenCoWork-0.1.4-beta.2-arm64.zip" "zip"
  write_file "$artifacts_dir/OpenCoWork-0.1.4-beta.2-arm64.zip.blockmap" "blockmap"
  cat > "$artifacts_dir/latest-mac.yml" <<'EOF'
version: 0.1.4-beta.2
path: OpenCoWork-0.1.4-beta.2-arm64.zip
sha512: dummy
EOF

  if bash "$REPO_ROOT/scripts/aggregate-release.sh" \
    --artifacts-dir "$artifacts_dir" \
    --release-dir "$release_dir" \
    --internal-dir "$internal_dir" \
    --version 0.1.4-beta.2 \
    --source-repository daymade/opencowork \
    --source-ref refs/heads/codex/release-drill-20260329 \
    --source-head-sha a3eab03db7a990427b5d6a9596bdfb46866d8790 >/dev/null 2>&1; then
    fail "aggregate-release.sh accepted a release payload without Windows artifacts"
  fi
}

test_verify_release_assets_parses_json_metadata() {
  local tmp_dir release_dir metadata_path
  tmp_dir="$(mktemp -d)"
  release_dir="$tmp_dir/release"
  mkdir -p "$release_dir"

  write_file "$release_dir/OpenCoWork-0.1.4-beta.2-arm64.dmg" "dmg"
  write_file "$release_dir/OpenCoWork-0.1.4-beta.2-arm64.zip" "zip"
  write_file "$release_dir/OpenCoWork-0.1.4-beta.2-arm64.zip.blockmap" "blockmap"
  cat > "$release_dir/latest-mac.yml" <<'EOF'
version: 0.1.4-beta.2
path: OpenCoWork-0.1.4-beta.2-arm64.zip
sha512: dummy
EOF

  (
    cd "$release_dir"
    : > SHA256SUMS.txt
    append_sha256 "OpenCoWork-0.1.4-beta.2-arm64.dmg"
    append_sha256 "OpenCoWork-0.1.4-beta.2-arm64.zip"
    append_sha256 "OpenCoWork-0.1.4-beta.2-arm64.zip.blockmap"
    append_sha256 "latest-mac.yml"
  )

  metadata_path="$release_dir/release-metadata.json"
  cat > "$metadata_path" <<'EOF'
{
  "product_name": "OpenCoWork",
  "version": "0.1.4-beta.2",
  "files": [
    {
      "path": "OpenCoWork-0.1.4-beta.2-arm64.dmg",
      "sha256": null
    },
    {
      "path": "OpenCoWork-0.1.4-beta.2-arm64.zip",
      "sha256": null
    }
  ]
}
EOF

  bash "$REPO_ROOT/scripts/verify-release-assets.sh" \
    --release-dir "$release_dir" \
    --metadata "$metadata_path" >/dev/null || fail "verify-release-assets.sh failed to parse JSON metadata"
}

test_collect_release_files_windows() {
  local tmp_dir release_dir output
  tmp_dir="$(mktemp -d)"
  release_dir="$tmp_dir/release"

  write_file "$release_dir/OpenCoWork-0.1.4-beta.2-x64.exe" "exe"
  write_file "$release_dir/OpenCoWork-0.1.4-beta.2-x64.zip" "zip"
  write_file "$release_dir/OpenCoWork-0.1.4-beta.2-x64.exe.blockmap" "blockmap"
  write_file "$release_dir/latest.yml" "path: OpenCoWork-0.1.4-beta.2-x64.exe"
  write_file "$release_dir/_internal/release-metadata.json" "{}"
  write_file "$release_dir/_internal/release-notes.md" "notes"

  output="$(bash "$REPO_ROOT/scripts/collect-release-files.sh" --release-dir "$release_dir" --platform windows)"
  grep -q 'OpenCoWork-0.1.4-beta.2-x64.exe' <<<"$output" || fail "windows exe missing from collected file list"
  grep -q 'OpenCoWork-0.1.4-beta.2-x64.zip' <<<"$output" || fail "windows zip missing from collected file list"
  grep -q 'latest.yml' <<<"$output" || fail "windows updater metadata missing from collected file list"
  grep -q '_internal/release-metadata.json' <<<"$output" || fail "internal metadata missing from collected file list"
  grep -q '_internal/release-notes.md' <<<"$output" || fail "internal notes missing from collected file list"
}

test_normalize_source_head_sha() {
  local exact prefix empty
  exact="$(bash "$REPO_ROOT/scripts/normalize-source-head-sha.sh" \
    --resolved-sha 517c04b0ea5e8adb150fe526b9dc4d4ee231ef4b \
    --requested-sha 517c04b0ea5e8adb150fe526b9dc4d4ee231ef4b)"
  [[ "$exact" == "517c04b0ea5e8adb150fe526b9dc4d4ee231ef4b" ]] || fail "exact SHA normalization failed"

  prefix="$(bash "$REPO_ROOT/scripts/normalize-source-head-sha.sh" \
    --resolved-sha 517c04b0ea5e8adb150fe526b9dc4d4ee231ef4b \
    --requested-sha 517c04b0)"
  [[ "$prefix" == "517c04b0ea5e8adb150fe526b9dc4d4ee231ef4b" ]] || fail "prefix SHA normalization failed"

  empty="$(bash "$REPO_ROOT/scripts/normalize-source-head-sha.sh" \
    --resolved-sha 517c04b0ea5e8adb150fe526b9dc4d4ee231ef4b)"
  [[ "$empty" == "517c04b0ea5e8adb150fe526b9dc4d4ee231ef4b" ]] || fail "empty requested SHA should resolve to canonical SHA"

  if bash "$REPO_ROOT/scripts/normalize-source-head-sha.sh" \
    --resolved-sha 517c04b0ea5e8adb150fe526b9dc4d4ee231ef4b \
    --requested-sha 517c04b4 >/dev/null 2>&1; then
    fail "mismatched SHA prefix should fail normalization"
  fi
}

test_release_workflow_rejects_noncanonical_source_inputs() {
  local workflow_path
  workflow_path="$REPO_ROOT/.github/workflows/release.yml"
  grep -q 'source_repository must remain daymade/opencowork' "$workflow_path" \
    || fail "release workflow no longer pins the canonical source repository"
  grep -q 'release_entrypoint must remain scripts/release/assemble-public-release.sh' "$workflow_path" \
    || fail "release workflow no longer pins the canonical release entrypoint"
}

test_aggregate_release_populates_sha256
test_verify_release_assets_parses_json_metadata
test_collect_release_files_windows
test_aggregate_release_requires_windows_artifacts
test_normalize_source_head_sha
test_release_workflow_rejects_noncanonical_source_inputs

echo "release script tests passed"
