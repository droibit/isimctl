import Foundation

/// Represents the complete output of `xcrun simctl list devices --json`
public struct SimulatorList: Equatable, Codable, Sendable {
  /// Dictionary mapping runtime identifiers to arrays of devices
  public let devices: [String: [Device]]

  public init(_ devices: [String: [Device]]) {
    self.devices = devices
  }
}

/// Represents a single simulator device
public struct Device: Equatable, Codable, Sendable {
  public let name: String
  public let state: String
  public let udid: String
  public let deviceTypeIdentifier: String

  public init(
    name: String,
    state: String,
    udid: String,
    deviceTypeIdentifier: String,
  ) {
    self.name = name
    self.state = state
    self.udid = udid
    self.deviceTypeIdentifier = deviceTypeIdentifier
  }
}
