import Foundation
import SimctlKit

/// Represents a runtime with its associated devices for single choice selection
struct RuntimeDeviceGroupOption: Equatable, CustomStringConvertible, Sendable {
  /// The runtime OS name and version (e.g., "iOS 26.2", "watchOS 26.2")
  let runtime: String
  /// The devices available for this runtime
  let devices: [Device]

  var description: String {
    runtime
  }
}

extension RuntimeDeviceGroupOption {
  /// Converts runtime identifier to human-readable format
  ///
  /// - Parameter runtimeIdentifier: e.g., "com.apple.CoreSimulator.SimRuntime.iOS-26-2"
  /// - Returns: e.g., "iOS 26.2"
  static func formatRuntime(_ runtimeIdentifier: String) -> String {
    // Remove prefix "com.apple.CoreSimulator.SimRuntime."
    let withoutPrefix = runtimeIdentifier
      .replacingOccurrences(of: "com.apple.CoreSimulator.SimRuntime.", with: "")

    // Replace hyphens with dots and split OS name from version
    let components = withoutPrefix.split(separator: "-")
    guard components.count >= 2 else {
      return withoutPrefix
    }

    let osName = components[0]
    let version = components.dropFirst().joined(separator: ".")
    return "\(osName) \(version)"
  }

  /// Converts devices to device options for single choice selection
  ///
  /// - Returns: An array of ``DeviceOption`` objects for the devices in this runtime group option
  func toDeviceOptions() -> [DeviceOption] {
    devices.map { DeviceOption($0) }
  }
}

extension SimulatorList {
  /// Converts the simulator list to runtime device group options sorted by runtime name
  ///
  /// - Parameter excludeEmpty: If `true`, runtime groups with no devices are excluded from the result. Defaults to `false`.
  /// - Returns: An array of ``RuntimeDeviceGroupOption`` objects sorted alphabetically by runtime
  func toRuntimeDeviceGroupOptions(excludeEmpty: Bool = false) -> [RuntimeDeviceGroupOption] {
    devices
      .filter { !excludeEmpty || !$0.value.isEmpty }
      .map { runtimeId, devices in
        RuntimeDeviceGroupOption(
          runtime: RuntimeDeviceGroupOption.formatRuntime(runtimeId),
          devices: devices.sorted { $0.name < $1.name },
        )
      }
      .sorted { $0.runtime < $1.runtime }
  }
}
