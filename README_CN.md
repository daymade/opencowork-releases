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
- Windows（`x64`，待 Windows release lane 发布后提供）

暂未提供 Intel Mac 和 Linux 版本。

## 下载说明

对大多数用户来说，请在 [Releases](https://github.com/daymade/opencowork-releases/releases) 页面下载最新的 **`.dmg`** 文件。

1. 下载 `OpenCoWork-...-arm64.dmg`
2. 打开 DMG
3. 将 `OpenCoWork.app` 拖入 `Applications`
4. 启动 OpenCoWork

如果你在发布页上看到 `*.zip`、`*-mac.yml` 或 `*.blockmap`，这些文件是给应用内自动更新使用的，不是普通手动安装时推荐下载的文件。

Windows 发布后，页面上还可能出现：

1. `OpenCoWork-...-x64.exe`
2. `OpenCoWork-...-x64.zip`
3. `latest.yml`

普通 Windows 用户应优先使用 `.exe` 安装包。

## 发布通道

| 通道 | Tag 格式 | 更新服务 |
|---|---|---|
| Stable | `vX.Y.Z` | `https://updates.openco.work` |
| Beta | `vX.Y.Z-beta.N` | `https://updates-beta.openco.work` |

`Beta` 版本应作为 GitHub Pre-release 发布。

## 自动更新

OpenCoWork 桌面端不会直接读取 GitHub Releases，而是通过品牌域名的更新 feed 检查新版本。

- Stable 通道 feed 根路径：`https://updates.openco.work/generic/`
- Beta 通道 feed 根路径：`https://updates-beta.openco.work/generic/`
- macOS 应用内自动更新会消费生成的 `*-mac.yml` 元数据和 ZIP 资产
- Windows 更新元数据使用 `latest.yml`，并通过对应通道的品牌更新域名解析真实下载资产
- DMG 仍然是普通用户手动安装时的推荐下载方式

## 这个仓库的用途

这个仓库只用于公开发布下载和 issue 反馈。OpenCoWork 源码维护在独立仓库中。

## 维护说明

当你修改本仓库里的 release workflow 脚本时，请先运行：

```bash
bash tests/release-scripts.sh
```

public release workflow 会先枚举 Windows 的具体产物文件，再做 smoke / upload。不要在 GitHub Actions 里继续依赖 `D:\\...` 路径上的原始通配符匹配。

## 校验下载文件

正式发布版本可能会附带 `SHA256SUMS.txt`，可用于校验下载文件。

```bash
shasum -a 256 OpenCoWork-*.dmg
```

将结果与同一个 GitHub Release 中的校验值对比即可。
