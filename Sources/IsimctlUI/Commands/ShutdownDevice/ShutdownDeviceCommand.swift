public import Noora
import SimctlKit

/// Command for shutting down a simulator interactively.
///
/// This command provides an interactive interface to select and shut down a simulator installed on the system.
/// The user is first prompted to select a runtime environment, then to select a specific device to shut down.
///
/// Only devices that are currently booted are available for selection.
///
/// ## Usage Examples
///
/// ```swift
/// // Shut down a single device interactively
/// let command = ShutdownDeviceCommand(noora: Noora.current)
/// try await command.run()
///
/// // Shut down all running devices
/// try await command.run(allDevices: true)
/// ```
public struct ShutdownDeviceCommand: Sendable {
  private let simctl: any Simctlable
  private let deviceSelectionPrompt: any DeviceSelectionPrompting
  private let shutdownDeviceMessage: any ShutdownDeviceMessaging
  private let simctlErrorAlert: any SimctlErrorAlerting

  public init(noora: any Noorable) {
    self.init(
      simctl: Simctl(),
      deviceSelectionPrompt: DeviceSelectionPrompt(noora: noora, purpose: .shutdownDevice),
      shutdownDeviceMessage: ShutdownDeviceMessage(noora: noora),
      simctlErrorAlert: SimctlErrorAlert(noora: noora),
    )
  }

  init(
    simctl: any Simctlable,
    deviceSelectionPrompt: any DeviceSelectionPrompting,
    shutdownDeviceMessage: any ShutdownDeviceMessaging,
    simctlErrorAlert: any SimctlErrorAlerting,
  ) {
    self.simctl = simctl
    self.deviceSelectionPrompt = deviceSelectionPrompt
    self.shutdownDeviceMessage = shutdownDeviceMessage
    self.simctlErrorAlert = simctlErrorAlert
  }

  /// Shuts down a simulator using an interactive interface.
  ///
  /// This method orchestrates the shutdown process by:
  /// 1. Fetching currently booted devices (regardless of `allDevices` flag)
  /// 2. Showing an alert and returning early if no booted devices exist
  /// 3a. If `allDevices` is true: executing shutdown for all devices directly
  /// 3b. If `allDevices` is false: prompting the user to select a runtime and device,
  ///     optionally prompting for confirmation, then executing the shutdown command
  /// 4. Displaying the result
  ///
  /// - Parameters:
  ///   - allDevices: Whether to shut down all running devices without selection. Defaults to false.
  ///   - shouldConfirm: Whether to prompt for confirmation before shutting down. Defaults to false.
  public func run(allDevices: Bool = false, shouldConfirm: Bool = false) async throws {
    do {
      let simulators = try await simctl
        .listDevices(searchTerm: .booted)
        .filtering(state: .booted)
      guard !simulators.devices.isEmpty else {
        shutdownDeviceMessage.showNoShuttableDevicesAlert()
        return
      }

      if allDevices {
        shutdownDeviceMessage.showShuttingDownDeviceMessage()
        try await simctl.shutdownDevice(.all)
        shutdownDeviceMessage.showShutdownAllSuccessAlert()
      } else {
        let selectedRuntime = deviceSelectionPrompt.selectRuntime(
          from: simulators.toRuntimeDeviceGroupOptions(),
          autoselectSingleChoice: false,
        )
        let selectedDevice = deviceSelectionPrompt.selectDevice(
          from: selectedRuntime.toDeviceOptions(),
        )

        if shouldConfirm {
          guard shutdownDeviceMessage.confirmShutdown() else {
            return
          }
        }

        shutdownDeviceMessage.showShuttingDownDeviceMessage()
        try await simctl.shutdownDevice(.device(udid: selectedDevice.device.udid))
        shutdownDeviceMessage.showShutdownSuccessAlert(for: selectedDevice)
      }
    } catch {
      guard let realError = error as? SimctlError else {
        throw error
      }
      simctlErrorAlert.show(realError)
    }
  }
}
