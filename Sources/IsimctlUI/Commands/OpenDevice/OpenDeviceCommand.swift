public import Noora
import SimctlKit
import SimulatorKit

/// Command for opening a simulator in Simulator.app interactively.
///
/// This command provides an interactive interface to select and open a simulator in Simulator.app.
/// The user is first prompted to select a runtime environment, then to select a specific device to open.
///
/// Only devices that are currently shut down are available for selection.
///
/// ## Usage Examples
///
/// ```swift
/// let command = OpenDeviceCommand(noora: Noora.current)
/// try await command.run()
/// ```
public struct OpenDeviceCommand: Sendable {
  private let simctl: any Simctlable
  private let openSimulator: any SimulatorOpenable
  private let deviceSelectionPrompt: any DeviceSelectionPrompting
  private let openDeviceMessage: any OpenDeviceMessaging
  private let openSimulatorErrorAlert: any OpenSimulatorErrorAlerting

  public init(noora: any Noorable) {
    self.init(
      simctl: Simctl(),
      openSimulator: OpenSimulator(),
      deviceSelectionPrompt: DeviceSelectionPrompt(noora: noora, purpose: .openDevice),
      openDeviceMessage: OpenDeviceMessage(noora: noora),
      openSimulatorErrorAlert: OpenSimulatorErrorAlert(noora: noora),
    )
  }

  init(
    simctl: any Simctlable,
    openSimulator: any SimulatorOpenable,
    deviceSelectionPrompt: any DeviceSelectionPrompting,
    openDeviceMessage: any OpenDeviceMessaging,
    openSimulatorErrorAlert: any OpenSimulatorErrorAlerting,
  ) {
    self.simctl = simctl
    self.openSimulator = openSimulator
    self.deviceSelectionPrompt = deviceSelectionPrompt
    self.openDeviceMessage = openDeviceMessage
    self.openSimulatorErrorAlert = openSimulatorErrorAlert
  }

  /// Opens a simulator in Simulator.app using an interactive interface.
  ///
  /// This method orchestrates the open process by:
  /// 1. Fetching available (shut down) devices
  /// 2. Prompting the user to select a runtime environment
  /// 3. Prompting the user to select a device from the selected runtime
  /// 4. Optionally prompting for confirmation (if shouldConfirm is true)
  /// 5. Executing the open command
  /// 6. Displaying the result
  ///
  /// - Parameter shouldConfirm: Whether to prompt for confirmation before opening. Defaults to false.
  public func run(shouldConfirm: Bool = false) async throws {
    do {
      let simulators = try await simctl
        .listDevices(searchTerm: .available)
        .filtering(state: .shutdown)
      guard !simulators.devices.isEmpty else {
        openDeviceMessage.showNoOpenableDevicesAlert()
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
        guard openDeviceMessage.confirmOpen() else {
          return
        }
      }

      openDeviceMessage.showOpeningDeviceMessage()

      try await openSimulator.open(udid: selectedDevice.device.udid)

      openDeviceMessage.showOpenSuccessAlert(for: selectedDevice)
    } catch {
      guard let realError = error as? OpenSimulatorError else {
        throw error
      }
      openSimulatorErrorAlert.show(realError)
    }
  }
}
