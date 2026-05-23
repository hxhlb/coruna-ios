# Coruna iOS

[English](README.en.md) | 简体中文

Coruna iOS 是一个自用研究工具，用 iOS App 承载原 Coruna Web 资源，并在设备本地启动 HTTP 静态服务器，方便通过 App 内 WKWebView 或 Safari 访问，而不需要额外部署远程 server。

## 项目目标

本仓库当前目标不是把 Coruna 的 JavaScript 或 payload 逻辑重写成原生 Swift 实现，而是提供一个轻量 iOS 宿主：

- 将原 Web 资源打包进 App Bundle。
- 在 App 内启动/停止本地 HTTP server。
- 提供两个访问入口：App 内 WKWebView 和系统 Safari。
- 显示本地 server 状态、资源请求日志和错误日志。
- 保持签名配置本地化，避免把个人 Team ID 提交到仓库。

## 当前功能

- SwiftUI 主界面：启动/停止、WK 打开、Safari 打开、日志面板。
- 本地 HTTP server：默认监听 `127.0.0.1:34306`。
- 离线资源：`CorunaIOS/Resources/CorunaWeb`。
- App Icon：通过 `Assets.xcassets` 管理。
- 国际化：简体中文、繁体中文、English。
- 最低系统版本：iOS 15。

## 本地签名配置

仓库提交的默认签名配置位于 `Config/Signing.xcconfig`，其中 `DEVELOPMENT_TEAM` 为空。

个人签名配置应放在：

```text
Config/LocalSigning.xcconfig
```

该文件已被 `.gitignore` 忽略，不会提交到 GitHub。

新 clone 后可以运行：

```sh
Scripts/setup-local-signing.sh
```

脚本会生成一个本地 `LocalSigning.xcconfig`，并为 Bundle ID 添加随机后缀。你也可以手动填写自己的 `DEVELOPMENT_TEAM` 和 `PRODUCT_BUNDLE_IDENTIFIER`。

## 参考与致谢

本项目参考并打包原始 Coruna Web 实现：

- [khanhduytran0/coruna](https://github.com/khanhduytran0/coruna)

特别感谢 [34306](https://github.com/34306) 提供 Coruna 的 Web 实现。

## 状态

项目处于自用研究阶段。当前重点是提供稳定的本地承载和访问入口，不承诺 App Store 分发，也不面向通用用户。

## License

暂未选择 License。
