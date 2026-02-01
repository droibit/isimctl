import SimctlKit
import Testing
@testable import IsimctlUI

struct DeviceOptionTests {
  // MARK: - description tests

  @Test(arguments: [
    "iPhone 15 Pro",
    "Apple Watch Series 9",
    "Apple TV 4K (3rd generation)",
  ])
  func description_shouldReturnDeviceName(deviceName: String) {
    let deviceOption = DeviceOption(
      Device(
        name: deviceName,
        state: "Shutdown",
        udid: "test-udid",
        deviceTypeIdentifier: "test-device-type",
      ),
    )
    #expect(deviceOption.description == deviceName)
  }
}
