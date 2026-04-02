# OpenCoWork Releases

[English](README.md) | **中文**

---

这是 **OpenCoWork** 的官方下载安装仓库。

本仓库刻意保持精简：

- 只负责 public CI 编排、最终产物聚合与校验。
- 不承载桌面打包策略、runtime 构建、合规资源准备、完整性生成、fuse 或 smoke 实现的权威逻辑；这些都留在私有源码仓库。

[![Latest Release](https://img.shields.io/github/v/release/daymade/opencowork-releases?display_name=tag&include_prereleases)](https://github.com/daymade/opencowork-releases/releases)
![Platform](https://img.shields.io/badge/platform-macOS%20Apple%20Silicon-black)

- 下载入口：https://github.com/daymade/opencowork-releases/releases
- 问题反馈：https://github.com/daymade/opencowork-releases/issues

## 当前支持平台

目前 OpenCoWork 仅提供：

- macOS
- Apple Silicon（`arm64`，即 M 系列芯片）
- Windows（`x64`）

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
手动触发 `workflow_dispatch` 时，必须显式提供精确的 40 位 `head_sha`。public workflow 不再根据 `ref` 自动解析或规范化源码 commit。
public release contract 现在在内部固定 `source_repository=daymade/opencowork` 和 `release_entrypoint=scripts/release/assemble-public-release.sh`；不要再围绕可覆盖输入设计发布流程。
不要把 `release` job 变绿当成唯一成功信号。只有在 run artifacts 里出现 `release-windows-x64`，并且 `verify-published-windows`、`verify-published-macos`、`publish-release` 全部成功后，这次发布才算真正完成。
公开 release 资产里禁止出现 `*.map`，公开 `release-metadata.json` 里也禁止继续暴露 `source_repository`、`source_ref`、`source_head_sha`。
`verify-release-assets.sh` 必须是完整性校验门，而不是只检查文件存在：它要校验 `SHA256SUMS.txt`、非空 metadata `sha256`，以及 `latest.yml` / `latest-mac.yml` 里的全部引用项和 `size` / `sha512`。
私有仓库触发 public release 时，必须以 PASS gate evidence + 已校验的 release-input digests 为前提，不能靠临时本地状态直接 dispatch。
如果公开 release 发错了资产，或者泄露了源码/私有元数据，应当先在 `opencowork-releases` 删除这个公开 release，再从修复后的代码重新构建；不要让已知有问题的 release 挂着再边跑边补。

## 校验下载文件

正式发布版本可能会附带 `SHA256SUMS.txt`，可用于校验下载文件。

```bash
shasum -a 256 OpenCoWork-*.dmg
```

将结果与同一个 GitHub Release 中的校验值对比即可。
