import Noora
import SimctlKit

/// Protocol for displaying messages related to booting a device
/// @mockable
protocol BootDeviceMessaging: Sendable {
  /// Shows a message indicating the device is being booted
  ///
  /// - Parameter device: The device option being booted
  func showBootingDeviceMessage(for device: DeviceOption)

  /// Shows an alert when device boot is successful
  ///
  /// - Parameter device: The device option that was successfully booted
  func showBootSuccessAlert(for device: DeviceOption)

  /// Shows an alert when no devices are available to boot
  func showNoBootableDevicesAlert()
}

/// Component for displaying messages related to booting a device using Noora
struct BootDeviceMessage: BootDeviceMessaging {
  private let noora: any Noorable

  init(noora: any Noorable) {
    self.noora = noora
  }

  func showBootingDeviceMessage(for device: DeviceOption) {
    noora.passthrough("Booting the device ...\n")
  }

  func showBootSuccessAlert(for device: DeviceOption) {
    noora.success(.alert("Device \(.accent("\(device.device.name) (\(device.device.udid))")) is now booted."))
  }

  func showNoBootableDevicesAlert() {
    noora.info(.alert("No devices available to boot.", takeaways: [
      "All available devices are already booted or unavailable.",
    ]))
  }
}
