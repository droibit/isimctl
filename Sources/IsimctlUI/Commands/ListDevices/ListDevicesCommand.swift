public import Noora
import SimctlKit

/// Command for listing and browsing simulator devices interactively.
///
/// This command provides an interactive interface to browse simulators installed on the system.
/// The behavior depends on the `searchTerm` and `showAll` parameters:
///
/// **Without search term (searchTerm is nil or empty):**
/// - User selects a runtime environment
/// - With `showAll=true`: Displays all devices for the selected runtime in a table
/// - With `showAll=false`: Prompts user to select a specific device, then shows details
///
/// **With search term:**
/// - With `showAll=true`: Displays all matching devices immediately (no runtime selection)
/// - With `showAll=false`: Shows runtime selection, then displays all matching devices for selected runtime
///
/// ## Usage Examples
///
/// ```swift
/// let command = ListDevicesCommand(noora: Noora.current)
///
/// // Browse all devices after selecting runtime
/// try await command.run(searchTerm: nil, showAll: true)
///
/// // Select a specific device to view details
/// try await command.run(searchTerm: nil, showAll: false)
///
/// // Show all booted devices immediately
/// try await command.run(searchTerm: "booted", showAll: true)
///
/// // Show booted devices by runtime
/// try await command.run(searchTerm: "booted", showAll: false)
/// ```
public struct ListDevicesCommand: Sendable {
  private let simctl: any Simctlable
  private let deviceTable: any DeviceTableDisplaying
  private let deviceSelectionPrompt: any DeviceSelectionPrompting
  private let deviceMessage: any ListDevicesMessaging
  private let simctlErrorAlert: any SimctlErrorAlerting

  public init(noora: any Noorable) {
    self.init(
      simctl: Simctl(),
      deviceTable: DeviceTable(noora: noora),
      deviceSelectionPrompt: DeviceSelectionPrompt(noora: noora, purpose: .listDevices),
      deviceMessage: ListDevicesMessage(noora: noora),
      simctlErrorAlert: SimctlErrorAlert(noora: noora),
    )
  }

  init(
    simctl: any Simctlable,
    deviceTable: any DeviceTableDisplaying,
    deviceSelectionPrompt: any DeviceSelectionPrompting,
    deviceMessage: any ListDevicesMessaging,
    simctlErrorAlert: any SimctlErrorAlerting,
  ) {
    self.simctl = simctl
    self.deviceTable = deviceTable
    self.deviceSelectionPrompt = deviceSelectionPrompt
    self.deviceMessage = deviceMessage
    self.simctlErrorAlert = simctlErrorAlert
  }

  /// Lists available simulator devices with an interactive interface.
  ///
  /// The behavior of this method depends on the `searchTerm` and `showAll` parameters:
  ///
  /// **Without search term (nil or empty):**
  /// - Always prompts the user to select a runtime environment first
  /// - If `showAll=true`: Displays all devices for the selected runtime in a table format
  /// - If `showAll=false`: Prompts user to select a specific device, displays detailed information and useful commands
  ///
  /// **With search term:**
  /// - Filters devices matching the search term before display
  /// - If `showAll=true`: Displays all matching devices immediately without runtime selection
  /// - If `showAll=false`: Prompts runtime selection (auto-selects if only one option), then displays matching devices
  ///
  /// - Parameters:
  ///   - searchTerm: Optional search term to filter devices (e.g., "booted", "available"). If nil or empty, shows all available devices.
  ///   - showAll: If `true`, displays all devices (or all matching devices if searchTerm is provided) in a table format.
  ///     If `false`, prompts the user to select a specific device (when searchTerm is nil) or shows filtered results by runtime.
  public func run(searchTerm: String?, showAll: Bool) async throws {
    do {
      let srcSimulators = try await simctl.listDevices(searchTerm: DeviceSearchTerm(searchTerm))
      guard !srcSimulators.devices.isEmpty else {
        deviceMessage.showNoSimulatorsAlert()
        return
      }

      if let searchTerm, !searchTerm.isEmpty {
        handleWithSearchTerm(simulators: srcSimulators, showAll: showAll)
      } else {
        handleWithoutSearchTerm(simulators: srcSimulators, showAll: showAll)
      }
    } catch {
      guard let realError = error as? SimctlError else {
        throw error
      }
      simctlErrorAlert.show(realError)
    }
  }

  // MARK: - Search Term Handling

  private func handleWithSearchTerm(simulators: SimulatorList, showAll: Bool) {
    // When a search term is provided, we adjust the display mode:
    // - showAll=true: Show all filtered devices without runtime selection
    // - showAll=false: Show runtime selection, then display all filtered devices
    //   (no individual device selection since results are expected to be few)
    if showAll {
      let devicesWithRuntime = simulators.toDevicesWithRuntime()
      guard !devicesWithRuntime.isEmpty else {
        deviceMessage.showNoDevicesFoundAlert()
        return
      }
      deviceTable.display(devicesWithRuntime)
    } else {
      let runtimeOptions = simulators.toRuntimeDeviceGroupOptions(excludeEmpty: true)
      guard !runtimeOptions.isEmpty else {
        deviceMessage.showNoDevicesFoundAlert()
        return
      }
      let selectedRuntime = deviceSelectionPrompt.selectRuntime(
        from: runtimeOptions,
        autoselectSingleChoice: true,
      )
      deviceTable.display(in: selectedRuntime)
    }
  }

  private func handleWithoutSearchTerm(simulators: SimulatorList, showAll: Bool) {
    let selectedRuntime = deviceSelectionPrompt.selectRuntime(
      from: simulators.toRuntimeDeviceGroupOptions(),
      autoselectSingleChoice: false,
    )
    guard !selectedRuntime.devices.isEmpty else {
      deviceMessage.showNoDevicesForRuntimeMessage()
      return
    }

    if showAll {
      deviceTable.display(in: selectedRuntime)
    } else {
      let selectedDevice = deviceSelectionPrompt.selectDevice(from: selectedRuntime.toDeviceOptions())
      deviceTable.display(selectedDevice.device)
      deviceMessage.showDeviceCommands(for: selectedDevice)
    }
  }
}
