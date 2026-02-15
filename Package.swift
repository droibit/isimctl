// swift-tools-version: 6.0
import PackageDescription

private extension PackageDescription.Target.Dependency {
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
    .package(url: "https://github.com/tuist/Noora", exact: "0.54.1"),
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
        "SimulatorKit",
      ],
    ),
    .target(
      name: "SimctlKit",
      dependencies: [
        "SubprocessKit",
      ],
    ),
    .target(
      name: "SimulatorKit",
      dependencies: [
        "SubprocessKit",
      ],
    ),
    .target(
      name: "SubprocessKit",
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
        "SimulatorKit",
        "SimulatorKitMocks",
      ],
    ),
    .testTarget(
      name: "SimctlKitTests",
      dependencies: [
        "SimctlKit",
        "SimctlKitMocks",
        "SubprocessKit",
        "SubprocessKitMocks",
      ],
    ),
    .testTarget(
      name: "SimctlKitIntegrationTests",
      dependencies: [
        "SimctlKit",
      ],
    ),
    .testTarget(
      name: "SimulatorKitTests",
      dependencies: [
        "SimulatorKit",
        "SimulatorKitMocks",
        "SubprocessKit",
        "SubprocessKitMocks",
      ],
    ),
    .testTarget(
      name: "SubprocessKitTests",
      dependencies: [
        "SubprocessKit",
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
        "SimctlKit",
      ],
      path: "./Tests/SimctlKitMocks",
    ),
    .target(
      name: "SimulatorKitMocks",
      dependencies: [
        "SimulatorKit",
      ],
      path: "./Tests/SimulatorKitMocks",
    ),
    .target(
      name: "SubprocessKitMocks",
      dependencies: [
        .subprocess,
        "SubprocessKit",
      ],
      path: "./Tests/SubprocessKitMocks",
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
