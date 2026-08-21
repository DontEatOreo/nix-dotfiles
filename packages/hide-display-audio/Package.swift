// swift-tools-version: 6.2
import PackageDescription

let package = Package(
  name: "HideDisplayAudio",
  platforms: [.macOS(.v13)],
  products: [
    .executable(name: "hide-display-audio", targets: ["HideDisplayAudio"])
  ],
  targets: [
    .target(
      name: "PrivateIOKit",
      publicHeadersPath: "include",
      linkerSettings: [
        .linkedFramework("CoreFoundation"),
        .linkedFramework("IOKit"),
      ]
    ),
    .target(name: "EDIDKit"),
    .executableTarget(
      name: "HideDisplayAudio",
      dependencies: ["EDIDKit", "PrivateIOKit"]
    ),
    .testTarget(name: "EDIDKitTests", dependencies: ["EDIDKit"]),
  ],
  // PackageDescription 6.2 still calls the finalized ISO C23 mode `c2x`.
  cLanguageStandard: .c2x
)
