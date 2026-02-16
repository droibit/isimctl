import Noora
import SimctlKit

/// Protocol for displaying messages related to opening a device
/// @mockable
protocol OpenDeviceMessaging: Sendable {
  /// Prompts the user to confirm the open operation
  ///
  /// - Returns: `true` if the user confirms, `false` otherwise
  func confirmOpen() -> Bool

  /// Shows a message indicating the device is being opened
  func showOpeningDeviceMessage()

  /// Shows an alert when device open is successful
  ///
  /// - Parameter device: The device option that was successfully opened
  func showOpenSuccessAlert(for device: DeviceOption)

  /// Shows an alert when no devices are available to open
  func showNoOpenableDevicesAlert()
}

/// Component for displaying messages related to opening a device using Noora
struct OpenDeviceMessage: OpenDeviceMessaging {
  private let noora: any Noorable

  init(noora: any Noorable) {
    self.noora = noora
  }

  func confirmOpen() -> Bool {
    noora.yesOrNoChoicePrompt(
      question: "Would you like to open?",
      defaultAnswer: true,
    )
  }

  func showOpeningDeviceMessage() {
    noora.passthrough("Opening the device in Simulator.app ...\n")
  }

  func showOpenSuccessAlert(for device: DeviceOption) {
    noora.success(.alert("Device \(.accent("\(device.device.name) (\(device.device.udid))")) is now open in Simulator.app."))
  }

  func showNoOpenableDevicesAlert() {
    noora.info(.alert("No devices available to open.", takeaways: [
      "All available devices are already booted or unavailable.",
    ]))
  }
}
