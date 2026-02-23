import Noora
import SimctlKit
import Testing
@testable import IsimctlUI
@testable import SimctlKitMocks

struct ShutdownDeviceMessageTests {
  private let noora: NooraMock
  private let message: ShutdownDeviceMessage

  init() {
    noora = NooraMock()
    message = ShutdownDeviceMessage(noora: noora)
  }

  @Test
  func showShuttingDownDeviceMessage_shouldDisplayShuttingDownMessage() {
    // When: Display shutting down message
    message.showShuttingDownDeviceMessage()

    // Then: Verify output
    let output = noora.description
    #expect(output == "Shutting down the device ...\n")
  }

  @Test
  func showShutdownSuccessAlert_shouldDisplaySuccessAlert() {
    // Given: Setup device
    let device = Device.stub(
      name: "iPhone 16 Pro",
      state: "Booted",
      udid: "12345678-1234-1234-1234-123456789012",
    )
    let deviceOption = DeviceOption(device)

    // When: Display success alert
    message.showShutdownSuccessAlert(for: deviceOption)

    // Then: Verify output
    let output = noora.description
    #expect(output == """
    ✔ Success
      Device iPhone 16 Pro (12345678-1234-1234-1234-123456789012) is now shut down.
    """)
  }

  @Test
  func showShutdownAllSuccessAlert_shouldDisplayAllSuccessAlert() {
    // When: Display all success alert
    message.showShutdownAllSuccessAlert()

    // Then: Verify output
    let output = noora.description
    #expect(output == """
    ✔ Success
      All booted devices are now shut down.
    """)
  }

  @Test
  func showNoShuttableDevicesAlert_shouldDisplayNoDevicesAlert() {
    // When: Display no shutable devices alert
    message.showNoShuttableDevicesAlert()

    // Then: Verify output
    let output = noora.description
    #expect(output == """
    i Info
      No devices available to shutdown.

      Takeaways:
       ▸ No devices are currently running.
    """)
  }
}
