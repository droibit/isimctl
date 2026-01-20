import Foundation

/// Represents the complete output of `xcrun simctl list devices --json`
public struct SimulatorList: Codable, Sendable {
  /// Dictionary mapping runtime identifiers to arrays of devices
  public let devices: [String: [Device]]

  public init(_ devices: [String: [Device]]) {
    self.devices = devices
  }
}

/// Represents a single simulator device
public struct Device: Codable, Sendable {
  public let udid: String
  public let deviceTypeIdentifier: String
  public let name: String
  public let state: String
  public let isAvailable: Bool

  public init(
    udid: String,
    deviceTypeIdentifier: String,
    name: String,
    state: String,
    isAvailable: Bool,
  ) {
    self.udid = udid
    self.deviceTypeIdentifier = deviceTypeIdentifier
    self.name = name
    self.state = state
    self.isAvailable = isAvailable
  }
}
