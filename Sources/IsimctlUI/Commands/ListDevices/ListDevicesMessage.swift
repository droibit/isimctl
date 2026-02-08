import Noora
import SimctlKit

/// Protocol for displaying messages and alerts related to listing devices
/// @mockable
protocol ListDevicesMessaging: Sendable {
  /// Shows an alert when no simulators are available
  func showNoSimulatorsAlert()

  /// Shows an alert when no devices match the search term
  func showNoDevicesFoundAlert()

  /// Shows info message when no devices are available for selected runtime
  func showNoDevicesForRuntimeMessage()

  /// Shows useful commands for the selected device
  ///
  /// - Parameter device: The device option containing device information
  func showDeviceCommands(for device: DeviceOption)
}

/// Component for displaying messages and alerts for the list devices command using Noora
struct ListDevicesMessage: ListDevicesMessaging {
  private let noora: any Noorable

  init(noora: any Noorable) {
    self.noora = noora
  }

  func showNoSimulatorsAlert() {
    noora.info(.alert("No simulators available.", takeaways: [
      "Install simulator components: https://developer.apple.com/documentation/xcode/downloading-and-installing-additional-xcode-components",
    ]))
  }

  func showNoDevicesFoundAlert() {
    noora.info(.alert("No devices found for the search term.", takeaways: [
      "Try a different search term or check available devices without filtering.",
    ]))
  }

  func showNoDevicesForRuntimeMessage() {
    noora.info("No devices available for the selected runtime.")
  }

  func showDeviceCommands(for device: DeviceOption) {
    noora.info(.alert(
      """
      Useful Commands:
      """,
      takeaways: [
        "Open: \(.command("open -a \"Simulator\" --args -CurrentDeviceUDID \(device.device.udid)"))",
        "Boot: \(.command("xcrun simctl boot \(device.device.udid)"))",
        "Shutdown: \(.command("xcrun simctl shutdown \(device.device.udid)"))",
      ],
    ))
  }
}
