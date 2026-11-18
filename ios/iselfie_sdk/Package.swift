// swift-tools-version: 5.9
import Foundation
import PackageDescription

// The native iSelfie SDK this plugin wraps: the public ISelfieSDK Swift package, pinned to the
// release that ships with this plugin version.
let iselfieSdkVersion: Version = "1.0.0-rc.2"

// Development only: when flutter/tool/publish_local_native_sdks.sh has copied a locally built
// ISelfieSDK.xcframework next to this repository's sources, the plugin builds against it instead
// of the GitHub release. That folder is git-ignored, so an app installing the plugin never sees
// it and always gets the release.
let localSdkPackage = URL(fileURLWithPath: #filePath)
  .resolvingSymlinksInPath()
  .deletingLastPathComponent()
  .appendingPathComponent("../../tool/local_ios_sdk/ISelfieSDK")
  .standardizedFileURL
let usesLocalSdk = FileManager.default.fileExists(
  atPath: localSdkPackage.appendingPathComponent("ISelfieSDK.xcframework").path
)

let iselfieSdkDependency: Package.Dependency = usesLocalSdk
  ? .package(path: localSdkPackage.path)
  : .package(url: "https://github.com/AiZtech-Labs/ISelfieSDK", exact: iselfieSdkVersion)

let package = Package(
  name: "iselfie_sdk",
  platforms: [
    // The native SDK's minimum.
    .iOS("15.1"),
  ],
  products: [
    .library(name: "iselfie-sdk", targets: ["iselfie_sdk"]),
  ],
  dependencies: [
    .package(name: "FlutterFramework", path: "../FlutterFramework"),
    iselfieSdkDependency,
  ],
  targets: [
    .target(
      name: "iselfie_sdk",
      dependencies: [
        .product(name: "FlutterFramework", package: "FlutterFramework"),
        .product(name: "ISelfieSDK", package: "ISelfieSDK"),
      ],
      resources: [
        // The plugin itself collects no data and calls no required-reason API; the native
        // ISelfieSDK framework ships its own privacy manifest.
        .process("PrivacyInfo.xcprivacy"),
      ]
    ),
  ]
)
