import Foundation

/// Represents the complete output of `xcrun simctl list runtimes --json`
public struct RuntimeList: Codable, Sendable {
  /// Array of available runtimes
  public let runtimes: [Runtime]

  public init(_ runtimes: [Runtime]) {
    self.runtimes = runtimes
  }
}

/// Represents a single simulator runtime
public struct Runtime: Codable, Sendable {
  public let identifier: String
  public let name: String
  public let platform: String
  public let version: String
  public let buildversion: String
  public let supportedArchitectures: [String]
  public let supportedDeviceTypes: [DeviceType]
  public let isInternal: Bool
  public let isAvailable: Bool

  public init(
    identifier: String,
    name: String,
    platform: String,
    version: String,
    buildversion: String,
    supportedArchitectures: [String],
    supportedDeviceTypes: [DeviceType],
    isInternal: Bool,
    isAvailable: Bool,
  ) {
    self.identifier = identifier
    self.name = name
    self.platform = platform
    self.version = version
    self.buildversion = buildversion
    self.supportedArchitectures = supportedArchitectures
    self.supportedDeviceTypes = supportedDeviceTypes
    self.isInternal = isInternal
    self.isAvailable = isAvailable
  }
}

/// Represents a supported device type for a runtime
public struct DeviceType: Codable, Sendable {
  public let identifier: String
  public let name: String
  public let productFamily: String

  public init(
    identifier: String,
    name: String,
    productFamily: String
  ) {
    self.identifier = identifier
    self.name = name
    self.productFamily = productFamily
  }
}
