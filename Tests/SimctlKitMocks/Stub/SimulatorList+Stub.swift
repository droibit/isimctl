import SimctlKit

// MARK: - Device

extension Device {
  /// Creates a test stub Device with customizable parameters.
  static func stub(
    name: String,
    state: String,
    udid: String = "12345678-1234-1234-1234-123456789012",
    deviceTypeIdentifier: String = "com.apple.CoreSimulator.SimDeviceType.iPhone-16",
  ) -> Self {
    .init(
      name: name,
      state: state,
      udid: udid,
      deviceTypeIdentifier: deviceTypeIdentifier,
    )
  }
}
