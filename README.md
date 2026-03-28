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

Intel Mac, Windows, and Linux builds are not published yet.

## Download Guide

For most users, download the latest **`.dmg`** file from the [Releases](https://github.com/daymade/opencowork-releases/releases) page.

1. Download `OpenCoWork-...-arm64.dmg`
2. Open the DMG
3. Drag `OpenCoWork.app` into `Applications`
4. Launch OpenCoWork

If you also see `*.zip`, `latest-mac.yml`, or `*.blockmap` files on the release page, those are for the app's in-app auto-update flow. They are not the recommended files for a normal manual install.

## What This Repo Is

This repository is for public release downloads and issue tracking only. OpenCoWork source code is maintained separately.

## Verify a Download

Official releases may include `SHA256SUMS.txt` for checksum verification.

```bash
shasum -a 256 OpenCoWork-*.dmg
```

Compare the result with the checksum file from the same GitHub Release.
