import Noora
import SimctlKit
import Testing
@testable import IsimctlUI
@testable import SimctlKitMocks

struct OpenDeviceMessageTests {
  private let noora: NooraMock
  private let message: OpenDeviceMessage

  init() {
    noora = NooraMock()
    message = OpenDeviceMessage(noora: noora)
  }

  @Test
  func showOpeningDeviceMessage_shouldDisplayOpeningMessage() {
    // When: Display opening message
    message.showOpeningDeviceMessage()

    // Then: Verify output
    let output = noora.description
    #expect(output == "Opening the device in Simulator.app ...\n")
  }

  @Test
  func showOpenSuccessAlert_shouldDisplaySuccessAlert() {
    // Given: Setup device
    let device = Device.stub(
      name: "iPhone 16 Pro",
      state: "Shutdown",
      udid: "12345678-1234-1234-1234-123456789012",
    )
    let deviceOption = DeviceOption(device)

    // When: Display success alert
    message.showOpenSuccessAlert(for: deviceOption)

    // Then: Verify output
    let output = noora.description
    #expect(output == """
    ✔ Success
      Device iPhone 16 Pro (12345678-1234-1234-1234-123456789012) is now open in Simulator.app.
    """)
  }

  @Test
  func showNoOpenableDevicesAlert_shouldDisplayNoDevicesAlert() {
    // When: Display no openable devices alert
    message.showNoOpenableDevicesAlert()

    // Then: Verify output
    let output = noora.description
    #expect(output == """
    i Info
      No devices available to open.

      Takeaways:
       ▸ All available devices are already booted or unavailable.
    """)
  }
}
