# Coruna iOS

English | [简体中文](README.md)

Coruna iOS is a personal research utility that packages the original Coruna Web resources inside an iOS app and serves them through a local HTTP static server. It makes the Web UI available from either an in-app WKWebView or Safari without deploying a separate remote server.

## Goal

The current goal is not to rewrite the Coruna JavaScript or payload flow as native Swift. This repository provides a lightweight iOS host app:

- Bundle the original Web resources inside the app.
- Start and stop a local HTTP server from the app.
- Provide two launch paths: in-app WKWebView and system Safari.
- Show server status, resource request logs, and error logs.
- Keep personal signing settings local so Team IDs are not committed.

## Current Features

- SwiftUI main screen: start/stop, open in WKWebView, open in Safari, and a log panel.
- Local HTTP server: listens on `127.0.0.1:34306` by default.
- Offline resources: `CorunaIOS/Resources/CorunaWeb`.
- App Icon managed through `Assets.xcassets`.
- Localization: Simplified Chinese, Traditional Chinese, and English.
- Minimum deployment target: iOS 15.

## Local Signing

The committed default signing configuration is `Config/Signing.xcconfig`, with an empty `DEVELOPMENT_TEAM`.

Personal signing settings should be placed in:

```text
Config/LocalSigning.xcconfig
```

That file is ignored by git and should not be pushed to GitHub.

After cloning, you can run:

```sh
Scripts/setup-local-signing.sh
```

The script creates a local `LocalSigning.xcconfig` and adds a random suffix to the Bundle ID. You can also edit it manually with your own `DEVELOPMENT_TEAM` and `PRODUCT_BUNDLE_IDENTIFIER`.

## References and Thanks

This project references and packages the original Coruna Web implementation:

- [khanhduytran0/coruna](https://github.com/khanhduytran0/coruna)

Special thanks to [34306](https://github.com/34306) for providing the Coruna Web implementation.

## Status

This is a personal research-stage project. The current focus is stable local hosting and launch paths. App Store distribution is not a goal, and the app is not intended for general end users.

## License

No license has been selected yet.
