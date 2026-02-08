// swift-tools-version: 6.0
import PackageDescription

private extension PackageDescription.Target.Dependency {
  // static let factory: Self = .product(name: "Factory", package: "Factory")
  static let argumentParser: Self = .product(name: "ArgumentParser", package: "swift-argument-parser")
  static let subprocess: Self = .product(name: "Subprocess", package: "swift-subprocess")
  static let noora: Self = .product(name: "Noora", package: "Noora")
}

let package = Package(
  name: "isimctl",
  platforms: [.macOS(.v15)],
  products: [
    .executable(name: "isimctl", targets: ["Isimctl"]),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser", exact: "1.7.0"),
    .package(url: "https://github.com/swiftlang/swift-subprocess", exact: "0.2.1"),
    .package(url: "https://github.com/tuist/Noora", exact: "0.53.0"),
  ],
  targets: [
    .executableTarget(
      name: "Isimctl",
      dependencies: [
        .argumentParser,
        .noora,
        "IsimctlUI",
      ],
    ),
    .target(
      name: "IsimctlUI",
      dependencies: [
        .noora,
        "SimctlKit",
      ],
    ),
    .target(
      name: "SimctlKit",
      dependencies: [
        .subprocess,
      ],
    ),

    // MARK: - Tests

    .testTarget(
      name: "IsimctlUITests",
      dependencies: [
        "IsimctlUI",
        "IsimctlUIMocks",
        "SimctlKit",
        "SimctlKitMocks",
      ],
    ),
    .testTarget(
      name: "SimctlKitTests",
      dependencies: [
        "SimctlKit",
        "SimctlKitMocks",
      ],
    ),
    .testTarget(
      name: "SimctlKitIntegrationTests",
      dependencies: [
        "SimctlKit",
      ],
    ),

    // MARK: - Mocks

    .target(
      name: "IsimctlUIMocks",
      dependencies: [
        "IsimctlUI",
      ],
      path: "./Tests/IsimctlUIMocks",
    ),

    .target(
      name: "SimctlKitMocks",
      dependencies: [
        .subprocess,
        "SimctlKit",
      ],
      path: "./Tests/SimctlKitMocks",
    ),
  ],
  swiftLanguageModes: [.v6],
)

/// ref. https://github.com/treastrain/swift-upcomingfeatureflags-cheatsheet
extension SwiftSetting {
  static let existentialAny: Self = .enableUpcomingFeature("ExistentialAny") // SE-0335, Swift 5.6,  SwiftPM 5.8+
  static let internalImportsByDefault: Self = .enableUpcomingFeature("InternalImportsByDefault") // SE-0409, Swift 6.0,  SwiftPM 6.0+
  static let memberImportVisibility: Self = .enableUpcomingFeature("MemberImportVisibility") // SE-0444, Swift 6.1,  SwiftPM 6.1+
  static let strictConcurrency: Self = .enableUpcomingFeature("StrictConcurrency")
}

for target in package.targets {
  guard !target.name.hasSuffix("Mocks") else {
    continue
  }

  target.swiftSettings = [
    .existentialAny,
    .internalImportsByDefault,
    .memberImportVisibility,
    .strictConcurrency,
  ]
}
