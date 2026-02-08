import Noora
import SimctlKit
import Testing
@testable import IsimctlUI

struct BootDeviceMessageTests {
  private let noora: NooraMock
  private let message: BootDeviceMessage

  init() {
    noora = NooraMock()
    message = BootDeviceMessage(noora: noora)
  }

  @Test
  func showBootingDeviceMessage_shouldDisplayBootingMessage() {
    // Given: Setup device
    let device = Device(
      name: "iPhone 16 Pro",
      state: "Shutdown",
      udid: "12345678-1234-1234-1234-123456789012",
      deviceTypeIdentifier: "com.apple.CoreSimulator.SimDeviceType.iPhone-16-Pro",
    )
    let deviceOption = DeviceOption(device)

    // When: Display booting message
    message.showBootingDeviceMessage(for: deviceOption)

    // Then: Verify output
    let output = noora.description
    #expect(output == "Booting the device ...\n")
  }

  @Test
  func showBootSuccessAlert_shouldDisplaySuccessAlert() {
    // Given: Setup device
    let device = Device(
      name: "iPhone 16 Pro",
      state: "Booted",
      udid: "12345678-1234-1234-1234-123456789012",
      deviceTypeIdentifier: "com.apple.CoreSimulator.SimDeviceType.iPhone-16-Pro",
    )
    let deviceOption = DeviceOption(device)

    // When: Display success alert
    message.showBootSuccessAlert(for: deviceOption)

    // Then: Verify output
    let output = noora.description
    #expect(output == """
    ✔ Success
      Device iPhone 16 Pro (12345678-1234-1234-1234-123456789012) is now booted.
    """)
  }

  @Test
  func showNoBootableDevicesAlert_shouldDisplayNoDevicesAlert() {
    // When: Display no bootable devices alert
    message.showNoBootableDevicesAlert()

    // Then: Verify output
    let output = noora.description
    #expect(output == """
    i Info
      No devices available to boot.

      Takeaways:
       ▸ All available devices are already booted or unavailable.
    """)
  }
}
