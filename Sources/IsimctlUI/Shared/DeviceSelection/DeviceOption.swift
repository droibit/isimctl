import SimctlKit

/// Represents a device option for single choice selection
struct DeviceOption: Equatable, CustomStringConvertible, Sendable {
  /// The device
  let device: Device

  init(_ device: Device) {
    self.device = device
  }

  var description: String {
    device.name
  }
}
