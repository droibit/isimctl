import Noora
import SimctlKit

/// Protocol for displaying messages related to shutting down a device
/// @mockable
protocol ShutdownDeviceMessaging: Sendable {
  /// Prompts the user to confirm the shutdown operation
  ///
  /// - Returns: `true` if the user confirms, `false` otherwise
  func confirmShutdown() -> Bool

  /// Shows a message indicating the device is being shut down
  func showShuttingDownDeviceMessage()

  /// Shows an alert when device shutdown is successful
  ///
  /// - Parameter device: The device option that was successfully shut down
  func showShutdownSuccessAlert(for device: DeviceOption)

  /// Shows an alert when all devices are shut down successfully
  func showShutdownAllSuccessAlert()

  /// Shows an alert when no devices are available to shutdown
  func showNoShuttableDevicesAlert()
}

/// Component for displaying messages related to shutting down a device using Noora
struct ShutdownDeviceMessage: ShutdownDeviceMessaging {
  private let noora: any Noorable

  init(noora: any Noorable) {
    self.noora = noora
  }

  func confirmShutdown() -> Bool {
    noora.yesOrNoChoicePrompt(
      question: "Would you like to shutdown?",
      defaultAnswer: true,
    )
  }

  func showShuttingDownDeviceMessage() {
    noora.passthrough("Shutting down the device ...\n")
  }

  func showShutdownSuccessAlert(for device: DeviceOption) {
    noora.success(.alert("Device \(.accent("\(device.device.name) (\(device.device.udid))")) is now shut down."))
  }

  func showShutdownAllSuccessAlert() {
    noora.success(.alert("All booted devices are now shut down."))
  }

  func showNoShuttableDevicesAlert() {
    noora.info(.alert("No devices available to shutdown.", takeaways: [
      "No devices are currently running.",
    ]))
  }
}
