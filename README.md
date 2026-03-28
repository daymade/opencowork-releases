# OpenCoWork Releases

**English** | [中文](README_CN.md)

---

Official release repository for **OpenCoWork**.

[![Latest Release](https://img.shields.io/github/v/release/daymade/opencowork-releases?display_name=tag&include_prereleases)](https://github.com/daymade/opencowork-releases/releases)
![Platform](https://img.shields.io/badge/platform-macOS%20arm64-black)
![Source](https://img.shields.io/badge/source-private-lightgrey)

- Download page: https://github.com/daymade/opencowork-releases/releases
- Issue tracker: https://github.com/daymade/opencowork-releases/issues

## What This Repository Is

This repository publishes signed or unsigned release artifacts for end users.

- Release binaries and tags are hosted here.
- Release automation runs in GitHub Actions in this public repository.
- Source code is maintained in a private repository.
- This repository must not contain private OpenCoWork source code.

## Public Release Boundary

This is a **release-only** repository.

- The public workflow may check out the private `daymade/opencowork` repository using a read-only secret token.
- Build logic stays in the private source repository.
- The public workflow only assembles, verifies, and publishes release assets and release metadata.

Current private-repo contract:

- Entrypoint: `scripts/release/assemble-public-release.sh`
- Inputs: `--version`, `--ref`, `--head-sha`, `--output-dir`
- Output: standalone installers plus metadata in the requested output directory
- Required private release assets: `opencowork-runtime-<version>-darwin-arm64.tar.gz` and matching `.sha256`

## Platform Availability

| Platform | Architecture | Status | Files |
|---|---|---|---|
| macOS | Apple Silicon (arm64) | Planned / current default | `.dmg`, `.zip` |

Additional platforms can be added later by extending the private assembly script and this workflow.

## Download & Install

1. Open the [Releases](https://github.com/daymade/opencowork-releases/releases) page.
2. Download the latest installer for your platform.
3. On macOS, open the `.dmg` and drag `OpenCoWork.app` into `Applications`.
4. Launch OpenCoWork directly.

## Integrity & Provenance

Official releases from this repository are expected to include:

- Installer artifacts
- `SHA256SUMS.txt`
- `release-metadata.json`

Optional local verification:

```bash
shasum -a 256 OpenCoWork-*.dmg
shasum -a 256 OpenCoWork-*.zip
```

Compare the result with `SHA256SUMS.txt` from the same GitHub Release.

## Maintainer Setup

Configure these repository secrets before running the release workflow:

- `OPENCOWORK_SOURCE_REPO_TOKEN`: read-only token for the private source repository
- `MACOS_CERT_P12`: optional macOS signing certificate
- `MACOS_CERT_PASSWORD`: optional signing certificate password
- `APPLE_API_KEY`: optional App Store Connect API key
- `APPLE_API_KEY_ID`: optional App Store Connect key id
- `APPLE_API_ISSUER`: optional App Store Connect issuer id

Optional repository variables for Electron binary acquisition:

- `ELECTRON_CACHE`
- `ELECTRON_DOWNLOAD_URL`
- `ELECTRON_MIRROR`
- `ELECTRON_CUSTOM_DIR`
- `ELECTRON_CUSTOM_FILENAME`

Recommended default is to leave these unset and use GitHub's Electron releases with the
workflow cache at `~/Library/Caches/electron`. If your CI region/network is flaky, set a
mirror or exact download URL without changing the release contract itself.

Workflow inputs / dispatch payload:

- `ref`: git ref in the private source repository
- `head_sha`: exact source commit SHA to assemble
- `version`: release version without the leading `v`
- `source_repository`: optional, defaults to `daymade/opencowork`
- `release_entrypoint`: optional, defaults to `scripts/release/assemble-public-release.sh`

The private source release for the same version must include:

- `opencowork-runtime-<version>-darwin-arm64.tar.gz`
- `opencowork-runtime-<version>-darwin-arm64.tar.gz.sha256`

## Release Channels

| Channel | Tag Pattern | GitHub Release |
|---|---|---|
| Stable | `vX.Y.Z` | normal release |
| Beta | `vX.Y.Z-beta.N` | prerelease |

## FAQ

### Is this repository open source?

No. This repository is for release distribution and issue tracking only.
OpenCoWork source code remains private unless published separately.

### Does this repository depend on Flowzero?

No. The workflow and release contract are specific to OpenCoWork.

### Where should I report installer issues?

Please open an issue:
https://github.com/daymade/opencowork-releases/issues

## Build Provenance

- Releases are published by GitHub Actions.
- Assets are assembled from the private source repository at the requested commit SHA.
- The public workflow can add checksums and fallback metadata before publishing.

## License

OpenCoWork release artifacts are distributed via this repository.
Source licensing and code ownership remain defined by the private source repository.
