# OpenCoWork Releases

[English](README.md) | **中文**

---

这是 **OpenCoWork** 的官方发布仓库。

[![Latest Release](https://img.shields.io/github/v/release/daymade/opencowork-releases?display_name=tag&include_prereleases)](https://github.com/daymade/opencowork-releases/releases)
![Platform](https://img.shields.io/badge/platform-macOS%20arm64-black)
![Source](https://img.shields.io/badge/source-private-lightgrey)

- 下载入口：https://github.com/daymade/opencowork-releases/releases
- 问题反馈：https://github.com/daymade/opencowork-releases/issues

## 仓库定位

这个仓库用于发布面向最终用户的 OpenCoWork 安装产物。

- Release 二进制和 tag 在这里维护。
- 发布自动化运行在这个公开仓库的 GitHub Actions 中。
- 源码维护在私有仓库中。
- 这个公开仓库不得包含私有 OpenCoWork 源码。

## 公开发布边界

这是一个**仅用于发布**的仓库。

- 公开 workflow 可以通过只读 secret token 拉取私有 `daymade/opencowork` 仓库。
- 构建逻辑保留在私有源码仓中。
- 公开 workflow 只负责组装、校验并发布 release 产物和元数据。

当前私有仓约定：

- 入口脚本：`scripts/release/assemble-public-release.sh`
- 输入参数：`--version`、`--ref`、`--head-sha`、`--output-dir`
- 输出结果：把独立安装包和元数据写入指定输出目录
- 必需私有 release 资产：`opencowork-runtime-<version>-darwin-arm64.tar.gz` 及对应 `.sha256`

## 平台支持

| 平台 | 架构 | 状态 | 文件 |
|---|---|---|---|
| macOS | Apple Silicon (arm64) | 规划中 / 当前默认 | `.dmg`, `.zip` |

后续如果需要更多平台，只需要扩展私有仓的组装脚本和本仓库 workflow。

## 下载与安装

1. 打开 [Releases](https://github.com/daymade/opencowork-releases/releases) 页面。
2. 下载适合你平台的最新安装包。
3. 在 macOS 上，打开 `.dmg`，将 `OpenCoWork.app` 拖入 `Applications`。
4. 直接启动 OpenCoWork。

## 完整性与可追溯性

本仓库的正式 release 预期会包含：

- 安装包文件
- `SHA256SUMS.txt`
- `release-metadata.json`

可选本地校验命令：

```bash
shasum -a 256 OpenCoWork-*.dmg
shasum -a 256 OpenCoWork-*.zip
```

然后与同一个 GitHub Release 中的 `SHA256SUMS.txt` 对比。

## 维护者配置

运行 release workflow 前，请配置这些仓库 secrets：

- `OPENCOWORK_SOURCE_REPO_TOKEN`：用于读取私有源码仓的只读 token
- `MACOS_CERT_P12`：可选，macOS 签名证书
- `MACOS_CERT_PASSWORD`：可选，签名证书密码
- `APPLE_API_KEY`：可选，App Store Connect API key
- `APPLE_API_KEY_ID`：可选，App Store Connect key id
- `APPLE_API_ISSUER`：可选，App Store Connect issuer id

可选仓库变量，用于 Electron 二进制获取：

- `ELECTRON_CACHE`
- `ELECTRON_DOWNLOAD_URL`
- `ELECTRON_MIRROR`
- `ELECTRON_CUSTOM_DIR`
- `ELECTRON_CUSTOM_FILENAME`

推荐默认保持未设置，直接使用 GitHub 官方 Electron releases，并依赖
`~/Library/Caches/electron` 的 workflow 缓存。如果你的 CI 所在网络不稳定，
再通过 mirror 或精确下载 URL 覆盖，而不是改动发布合同本身。

Workflow 输入 / dispatch payload：

- `ref`：私有源码仓中的 git ref
- `head_sha`：要组装的精确源码提交 SHA
- `version`：不带前缀 `v` 的版本号
- `source_repository`：可选，默认 `daymade/opencowork`
- `release_entrypoint`：可选，默认 `scripts/release/assemble-public-release.sh`

同版本的私有源码 release 还必须提供：

- `opencowork-runtime-<version>-darwin-arm64.tar.gz`
- `opencowork-runtime-<version>-darwin-arm64.tar.gz.sha256`

## 发布通道

| 通道 | Tag 规则 | GitHub Release |
|---|---|---|
| Stable | `vX.Y.Z` | 正式版 |
| Beta | `vX.Y.Z-beta.N` | 预发布 |

## 常见问题

### 这是开源仓库吗？

不是。这个仓库只负责发布分发和 issue 跟踪。
OpenCoWork 源码仍然保持私有，除非未来另行公开。

### 这个仓库依赖 Flowzero 吗？

不依赖。这里的 workflow 和发布约定都只面向 OpenCoWork。

### 安装包问题应该去哪里反馈？

请在这里提交 issue：  
https://github.com/daymade/opencowork-releases/issues

## 构建来源说明

- Release 由 GitHub Actions 发布。
- 产物从私有源码仓指定的 commit SHA 组装而来。
- 公开 workflow 会在发布前补充 checksum 和兜底元数据。

## License

本仓库用于分发 OpenCoWork release 产物。
源码许可与代码归属以私有源码仓为准。
