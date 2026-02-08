import SimctlKit
@testable import IsimctlUI

extension RuntimeDeviceGroupOption {
  /// Creates a test stub RuntimeDeviceGroupOption.
  static func stub(
    runtime: String,
    devices: [Device],
  ) -> Self {
    .init(runtime: runtime, devices: devices)
  }
}
