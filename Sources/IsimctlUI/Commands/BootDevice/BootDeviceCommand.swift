public import Noora
import SimctlKit

/// Command for booting a simulator interactively.
///
/// This command provides an interactive interface to select and boot a simulator installed on the system.
/// The user is first prompted to select a runtime environment, then to select a specific device to boot.
///
/// Only devices that are currently shut down are available for selection.
///
/// ## Usage Examples
///
/// ```swift
/// let command = BootDeviceCommand(noora: Noora.current)
/// try await command.run()
/// ```
public struct BootDeviceCommand: Sendable {
  private let simctl: any Simctlable
  private let deviceSelectionPrompt: any DeviceSelectionPrompting
  private let bootDeviceMessage: any BootDeviceMessaging
  private let simctlErrorAlert: any SimctlErrorAlerting

  public init(noora: any Noorable) {
    self.init(
      simctl: Simctl(),
      deviceSelectionPrompt: DeviceSelectionPrompt(noora: noora, purpose: .bootDevice),
      bootDeviceMessage: BootDeviceMessage(noora: noora),
      simctlErrorAlert: SimctlErrorAlert(noora: noora),
    )
  }

  init(
    simctl: any Simctlable,
    deviceSelectionPrompt: any DeviceSelectionPrompting,
    bootDeviceMessage: any BootDeviceMessaging,
    simctlErrorAlert: any SimctlErrorAlerting,
  ) {
    self.simctl = simctl
    self.deviceSelectionPrompt = deviceSelectionPrompt
    self.bootDeviceMessage = bootDeviceMessage
    self.simctlErrorAlert = simctlErrorAlert
  }

  /// Boots a simulator using an interactive interface.
  ///
  /// This method orchestrates the boot process by:
  /// 1. Fetching available (shut down) devices
  /// 2. Prompting the user to select a runtime environment
  /// 3. Prompting the user to select a device from the selected runtime
  /// 4. Optionally prompting for confirmation (if shouldConfirm is true)
  /// 5. Executing the boot command
  /// 6. Displaying the result
  ///
  /// - Parameter shouldConfirm: Whether to prompt for confirmation before booting. Defaults to false.
  public func run(shouldConfirm: Bool = false) async throws {
    do {
      let simulators = try await simctl
        .listDevices(searchTerm: .available)
        .filtering(state: .shutdown)
      guard !simulators.devices.isEmpty else {
        bootDeviceMessage.showNoBootableDevicesAlert()
        return
      }

      let selectedRuntime = deviceSelectionPrompt.selectRuntime(
        from: simulators.toRuntimeDeviceGroupOptions(),
        autoselectSingleChoice: false,
      )
      let selectedDevice = deviceSelectionPrompt.selectDevice(
        from: selectedRuntime.toDeviceOptions(),
      )

      if shouldConfirm {
        guard bootDeviceMessage.confirmBoot() else {
          return
        }
      }

      bootDeviceMessage.showBootingDeviceMessage(for: selectedDevice)

      try await simctl.bootDevice(udid: selectedDevice.device.udid)

      bootDeviceMessage.showBootSuccessAlert(for: selectedDevice)
    } catch {
      guard let realError = error as? SimctlError else {
        throw error
      }
      simctlErrorAlert.show(realError)
    }
  }
}
