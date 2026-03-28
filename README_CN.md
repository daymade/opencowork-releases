# OpenCoWork Releases

[English](README.md) | **中文**

---

这是 **OpenCoWork** 的官方下载安装仓库。

[![Latest Release](https://img.shields.io/github/v/release/daymade/opencowork-releases?display_name=tag&include_prereleases)](https://github.com/daymade/opencowork-releases/releases)
![Platform](https://img.shields.io/badge/platform-macOS%20Apple%20Silicon-black)

- 下载入口：https://github.com/daymade/opencowork-releases/releases
- 问题反馈：https://github.com/daymade/opencowork-releases/issues

## 当前支持平台

目前 OpenCoWork 仅提供：

- macOS
- Apple Silicon（`arm64`，即 M 系列芯片）

暂未提供 Intel Mac、Windows 或 Linux 版本。

## 下载说明

对大多数用户来说，请在 [Releases](https://github.com/daymade/opencowork-releases/releases) 页面下载最新的 **`.dmg`** 文件。

1. 下载 `OpenCoWork-...-arm64.dmg`
2. 打开 DMG
3. 将 `OpenCoWork.app` 拖入 `Applications`
4. 启动 OpenCoWork

如果你在发布页上看到 `*.zip`、`latest-mac.yml` 或 `*.blockmap`，这些文件是给应用内自动更新使用的，不是普通手动安装时推荐下载的文件。

## 发布通道

| 通道 | Tag 格式 | 更新服务 |
|---|---|---|
| Stable | `vX.Y.Z` | `https://updates.openco.work` |
| Beta | `vX.Y.Z-beta.N` | `https://updates-beta.openco.work` |

`Beta` 版本应作为 GitHub Pre-release 发布。

## 自动更新

OpenCoWork 桌面端不会直接读取 GitHub Releases，而是通过品牌域名的更新 feed 检查新版本。

- Stable 通道 feed：`https://updates.openco.work/update/darwin/<current-version>`
- Beta 通道 feed：`https://updates-beta.openco.work/update/darwin/<current-version>`
- 应用内自动更新会消费 `latest-mac.yml` 和 ZIP 资产
- DMG 仍然是普通用户手动安装时的推荐下载方式

## 这个仓库的用途

这个仓库只用于公开发布下载和 issue 反馈。OpenCoWork 源码维护在独立仓库中。

## 校验下载文件

正式发布版本可能会附带 `SHA256SUMS.txt`，可用于校验下载文件。

```bash
shasum -a 256 OpenCoWork-*.dmg
```

将结果与同一个 GitHub Release 中的校验值对比即可。
