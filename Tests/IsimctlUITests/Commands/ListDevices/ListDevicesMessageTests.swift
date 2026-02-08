import Noora
import SimctlKit
import Testing
@testable import IsimctlUI

struct ListDevicesMessageTests {
  private let noora: NooraMock
  private let message: ListDevicesMessage

  init() {
    noora = NooraMock()
    message = ListDevicesMessage(noora: noora)
  }

  @Test
  func showNoSimulatorsAlert_shouldDisplayCorrectMessage() {
    message.showNoSimulatorsAlert()

    let output = noora.description
    #expect(output == """
    i Info
      No simulators available.

      Takeaways:
       ▸ Install simulator components: https://developer.apple.com/documentation/xcode/downloading-and-installing-additional-xcode-components
    """)
  }

  @Test
  func showNoDevicesFoundAlert_shouldDisplayCorrectMessage() {
    message.showNoDevicesFoundAlert()

    let output = noora.description
    #expect(output == """
    i Info
      No devices found for the search term.

      Takeaways:
       ▸ Try a different search term or check available devices without filtering.
    """)
  }

  @Test
  func showNoDevicesForRuntimeMessage_shouldDisplayCorrectMessage() {
    message.showNoDevicesForRuntimeMessage()

    let output = noora.description
    #expect(output == """
    i Info
      No devices available for the selected runtime.
    """)
  }

  @Test
  func showDeviceCommands_shouldDisplayCorrectCommands() {
    let device = Device(
      name: "iPhone 16 Pro",
      state: "Shutdown",
      udid: "12345678-1234-1234-1234-123456789012",
      deviceTypeIdentifier: "com.apple.CoreSimulator.SimDeviceType.iPhone-16-Pro",
    )
    let deviceOption = DeviceOption(device)
    message.showDeviceCommands(for: deviceOption)

    let output = noora.description
    #expect(output == """
    i Info
      Useful Commands:

      Takeaways:
       ▸ Open: 'open -a "Simulator" --args -CurrentDeviceUDID 12345678-1234-1234-1234-123456789012'
       ▸ Boot: 'xcrun simctl boot 12345678-1234-1234-1234-123456789012'
       ▸ Shutdown: 'xcrun simctl shutdown 12345678-1234-1234-1234-123456789012'
    """)
  }
}
