import SimctlKit
@testable import IsimctlUI

extension Device {
  /// Creates a test stub Device with customizable parameters.
  static func stub(
    name: String = "iPhone 16 Pro",
    state: String = "Shutdown",
    udid: String = "12345678-1234-1234-1234-123456789012",
    deviceTypeIdentifier: String = "com.apple.CoreSimulator.SimDeviceType.iPhone-16-Pro",
  ) -> Self {
    .init(
      name: name,
      state: state,
      udid: udid,
      deviceTypeIdentifier: deviceTypeIdentifier,
    )
  }
}

extension SimulatorList {
  /// Creates a test stub SimulatorList from runtime-device pairs.
  static func stub(
    runtimes: [(id: String, devices: [Device])],
  ) -> Self {
    .init(Dictionary(uniqueKeysWithValues: runtimes.map { ($0.id, $0.devices) }))
  }
}
