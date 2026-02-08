import Foundation

/// Represents the operational state of a simulator device
public enum DeviceState: String, Equatable, Codable, Sendable {
  case booted = "Booted"
  case shutdown = "Shutdown"
}

/// Represents the complete output of `xcrun simctl list devices --json`
public struct SimulatorList: Equatable, Codable, Sendable {
  /// Dictionary mapping runtime identifiers to arrays of devices
  public let devices: [String: [Device]]

  public init(_ devices: [String: [Device]]) {
    self.devices = devices
  }

  /// Returns a new ``SimulatorList`` with devices filtered by the specified state.
  ///
  /// Filters devices by comparing their `state` property against the provided state
  /// using case-insensitive comparison. Runtimes with no matching devices are excluded
  /// from the result.
  ///
  /// - Parameter state: The device state to filter by
  /// - Returns: A new ``SimulatorList`` containing only devices matching the specified state
  public func filtering(state: DeviceState) -> Self {
    let stateValue = state.rawValue
    let filteredDevices = devices.mapValues { devices in
      devices.filter { device in
        device.state.caseInsensitiveCompare(stateValue) == .orderedSame
      }
    }
    .filter { !$0.value.isEmpty }

    return Self(filteredDevices)
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
