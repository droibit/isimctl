// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "isimctl",
  platforms: [.macOS(.v15)],
  products: [
    .executable(name: "isimctl", targets: ["CLI"]),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser", exact: "1.7.0"),
    .package(url: "https://github.com/swiftlang/swift-subprocess", exact: "0.2.1"),
    .package(url: "https://github.com/tuist/Noora", exact: "0.53.0"),
  ],
  targets: [
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    .executableTarget(
      name: "CLI",
      dependencies: [
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        .product(name: "Subprocess", package: "swift-subprocess"),
        .product(name: "Noora", package: "Noora"),
        "Core",
      ]
    ),
    .target(
      name: "Core",
      dependencies: [
        .product(name: "Subprocess", package: "swift-subprocess"),
        .product(name: "Noora", package: "Noora"),
      ]
    ),
    .testTarget(
      name: "CoreTests",
      dependencies: [
        "Core",
      ]
    ),
  ],
  swiftLanguageModes: [.v6]
)

// ref. https://github.com/treastrain/swift-upcomingfeatureflags-cheatsheet
extension SwiftSetting {
  static let existentialAny: Self = .enableUpcomingFeature("ExistentialAny") // SE-0335, Swift 5.6,  SwiftPM 5.8+
  static let internalImportsByDefault: Self = .enableUpcomingFeature("InternalImportsByDefault") // SE-0409, Swift 6.0,  SwiftPM 6.0+
  static let memberImportVisibility: Self = .enableUpcomingFeature("MemberImportVisibility") // SE-0444, Swift 6.1,  SwiftPM 6.1+
}

for target in package.targets {
  guard target.name != "Mocks" else {
    continue
  }

  target.swiftSettings = [
    .enableUpcomingFeature("StrictConcurrency"),
    .existentialAny,
    .internalImportsByDefault,
    .memberImportVisibility,
  ]
}
