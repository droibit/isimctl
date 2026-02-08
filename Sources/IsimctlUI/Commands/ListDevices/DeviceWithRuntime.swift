import SimctlKit

/// Represents a device with its associated runtime information
struct DeviceWithRuntime: Equatable, Sendable {
  /// The device
  let device: Device
  /// The runtime OS name and version (e.g., "iOS 26.2", "watchOS 26.2")
  let runtime: String
}

extension SimulatorList {
  /// Converts the simulator list to devices with runtime information sorted by runtime name
  ///
  /// - Returns: An array of ``DeviceWithRuntime`` objects sorted alphabetically by runtime, then by device name
  func toDevicesWithRuntime() -> [DeviceWithRuntime] {
    devices
      .map { runtimeId, devices in
        let formattedRuntime = RuntimeDeviceGroupOption.formatRuntime(runtimeId)
        return (runtime: formattedRuntime, devices: devices)
      }
      .flatMap { runtime, devices in
        devices.map { DeviceWithRuntime(device: $0, runtime: runtime) }
      }
      .sorted { lhs, rhs in
        if lhs.runtime != rhs.runtime {
          return lhs.runtime < rhs.runtime
        }
        return lhs.device.name < rhs.device.name
      }
  }
}
