# OpenCoWork Releases

**English** | [中文](README_CN.md)

---

Official download repository for **OpenCoWork**.

[![Latest Release](https://img.shields.io/github/v/release/daymade/opencowork-releases?display_name=tag&include_prereleases)](https://github.com/daymade/opencowork-releases/releases)
![Platform](https://img.shields.io/badge/platform-macOS%20Apple%20Silicon-black)

- Releases: https://github.com/daymade/opencowork-releases/releases
- Issues: https://github.com/daymade/opencowork-releases/issues

## Current Availability

OpenCoWork is currently available for:

- macOS
- Apple Silicon only (`arm64`, including M-series Macs)
- Windows (`x64`) once the Windows release lane is published

Intel Mac and Linux builds are not published yet.

## Download Guide

For most users, download the latest **`.dmg`** file from the [Releases](https://github.com/daymade/opencowork-releases/releases) page.

1. Download `OpenCoWork-...-arm64.dmg`
2. Open the DMG
3. Drag `OpenCoWork.app` into `Applications`
4. Launch OpenCoWork

If you also see `*.zip`, `*-mac.yml`, or `*.blockmap` files on the release page, those are for the app's in-app auto-update flow. They are not the recommended files for a normal manual install.

Windows releases may include:

1. `OpenCoWork-...-x64.exe`
2. `OpenCoWork-...-x64.zip`
3. `latest.yml`

For normal Windows installation, use the `.exe` installer.

## Release Channels

| Channel | Tag Pattern | Update Server |
|---|---|---|
| Stable | `vX.Y.Z` | `https://updates.openco.work` |
| Beta | `vX.Y.Z-beta.N` | `https://updates-beta.openco.work` |

`Beta` releases should be published as GitHub pre-releases.

## Auto-Update

OpenCoWork desktop uses a branded update feed instead of checking GitHub Releases directly.

- Stable channel feed root: `https://updates.openco.work/generic/`
- Beta channel feed root: `https://updates-beta.openco.work/generic/`
- Generated `*-mac.yml` metadata and the ZIP asset are consumed by the macOS in-app updater
- The DMG remains the recommended manual install path
- Windows updater metadata uses `latest.yml`, which resolves against the branded update domain for the active channel

## What This Repo Is

This repository is for public release downloads and issue tracking only. OpenCoWork source code is maintained separately.

## Maintainer Notes

When changing release workflow scripts in this repository, run:

```bash
bash tests/release-scripts.sh
```

The public release workflow intentionally enumerates concrete Windows artifact files before smoke/upload. Avoid raw wildcard matching against drive-letter paths in GitHub Actions.

## Verify a Download

Official releases may include `SHA256SUMS.txt` for checksum verification.

```bash
shasum -a 256 OpenCoWork-*.dmg
```

Compare the result with the checksum file from the same GitHub Release.
