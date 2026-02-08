// swiftlint:disable type_body_length file_length
import Noora
import SimctlKit
import SimctlKitMocks
import Testing
@testable import IsimctlUI
@testable import IsimctlUIMocks

struct ListDevicesCommandTests {
  private let noora: NooraMock
  private let simctl: SimctlableMock
  private let deviceTable: DeviceTableDisplayingMock
  private let deviceSelectionPrompt: DeviceSelectionPromptingMock
  private let deviceMessage: ListDevicesMessagingMock
  private let simctlErrorAlert: SimctlErrorAlertingMock
  private let command: ListDevicesCommand

  init() {
    noora = NooraMock()
    simctl = SimctlableMock()
    deviceTable = DeviceTableDisplayingMock()
    deviceSelectionPrompt = DeviceSelectionPromptingMock()
    deviceMessage = ListDevicesMessagingMock()
    simctlErrorAlert = SimctlErrorAlertingMock()
    command = ListDevicesCommand(
      simctl: simctl,
      deviceTable: deviceTable,
      deviceSelectionPrompt: deviceSelectionPrompt,
      deviceMessage: deviceMessage,
      simctlErrorAlert: simctlErrorAlert,
    )
  }

  // MARK: - Normal Cases

  // MARK: No Search Term + showAll=true

  @Test
  func run_shouldDisplayTableWhenShowAllTrueAndNoSearchTerm() async throws {
    // Given: Multiple runtimes with multiple devices
    let device1 = Device.stub(name: "iPhone 16 Pro", state: "Shutdown")
    let device2 = Device.stub(name: "iPhone 16", state: "Booted")
    let simulators = SimulatorList.stub(runtimes: [
      (id: "com.apple.CoreSimulator.SimRuntime.iOS-26-2", devices: [device1, device2]),
    ])
    simctl.listDevicesHandler = { _ in simulators }

    let selectedRuntime = RuntimeDeviceGroupOption.stub(
      runtime: "iOS 26.2",
      devices: [device1, device2],
    )
    deviceSelectionPrompt.selectRuntimeHandler = { _, _ in selectedRuntime }

    // When
    try await command.run(searchTerm: nil, showAll: true)

    // Then: simctl.listDevices is called with correct searchTerm
    #expect(simctl.listDevicesArgValues == [nil])

    // Then: Runtime selection is called with autoselectSingleChoice=false
    #expect(deviceSelectionPrompt.selectRuntimeCallCount == 1)
    let runtimeArgs = deviceSelectionPrompt.selectRuntimeArgValues[0]
    #expect(runtimeArgs.autoselectSingleChoice == false)
    #expect(runtimeArgs.options == [
      RuntimeDeviceGroupOption(runtime: "iOS 26.2", devices: [device2, device1]),
    ])

    // Then: Table display is called with selected runtime
    #expect(deviceTable.displayInArgValues == [selectedRuntime])

    // Then: No error messages are displayed
    #expect(deviceMessage.showNoSimulatorsAlertCallCount == 0)
    #expect(deviceMessage.showNoDevicesFoundAlertCallCount == 0)
    #expect(deviceMessage.showNoDevicesForRuntimeMessageCallCount == 0)
  }

  // MARK: No Search Term + showAll=false

  @Test
  func run_shouldDisplayDeviceDetailsWhenShowAllFalseAndNoSearchTerm() async throws {
    // Given: Multiple runtimes with multiple devices
    let device1 = Device.stub(name: "iPhone 16 Pro", state: "Shutdown")
    let device2 = Device.stub(name: "iPhone 16", state: "Booted")
    let simulators = SimulatorList.stub(runtimes: [
      (id: "com.apple.CoreSimulator.SimRuntime.iOS-26-2", devices: [device1, device2]),
    ])
    simctl.listDevicesHandler = { _ in simulators }

    let selectedRuntime = RuntimeDeviceGroupOption.stub(
      runtime: "iOS 26.2",
      devices: [device1, device2],
    )
    deviceSelectionPrompt.selectRuntimeHandler = { _, _ in selectedRuntime }

    let selectedDeviceOption = DeviceOption(device1)
    deviceSelectionPrompt.selectDeviceHandler = { _ in selectedDeviceOption }

    // When
    try await command.run(searchTerm: nil, showAll: false)

    // Then: simctl.listDevices is called with correct searchTerm
    #expect(simctl.listDevicesArgValues == [nil])

    // Then: Runtime selection is called with autoselectSingleChoice=false
    #expect(deviceSelectionPrompt.selectRuntimeCallCount == 1)
    let runtimeArgs = deviceSelectionPrompt.selectRuntimeArgValues[0]
    #expect(runtimeArgs.autoselectSingleChoice == false)
    #expect(runtimeArgs.options == [
      RuntimeDeviceGroupOption(runtime: "iOS 26.2", devices: [device2, device1]),
    ])

    // Then: Device selection is called
    #expect(deviceSelectionPrompt.selectDeviceArgValues == [
      [DeviceOption(device1), DeviceOption(device2)],
    ])

    // Then: Device details and commands are displayed
    #expect(deviceTable.displayArgValues == [device1])
    #expect(deviceMessage.showDeviceCommandsArgValues == [selectedDeviceOption])

    // Then: Table display for runtime is not called
    #expect(deviceTable.displayInCallCount == 0)
    #expect(deviceTable.displayDevicesWithRuntimeCallCount == 0)
  }

  // MARK: With Search Term + showAll=true

  @Test
  func run_shouldDisplayTableImmediatelyWhenShowAllTrueAndSearchTerm() async throws {
    // Given: Search term returns multiple devices
    let device1 = Device.stub(name: "iPhone 16 Pro", state: "Booted")
    let device2 = Device.stub(name: "iPhone 16", state: "Booted")
    let simulators = SimulatorList.stub(runtimes: [
      (id: "com.apple.CoreSimulator.SimRuntime.iOS-26-2", devices: [device1, device2]),
    ])
    simctl.listDevicesHandler = { _ in simulators }

    // When
    try await command.run(searchTerm: "booted", showAll: true)

    // Then: simctl.listDevices is called with correct searchTerm
    #expect(simctl.listDevicesArgValues == [.init("booted")])

    // Then: Table display is called immediately with devices and runtime
    #expect(deviceTable.displayDevicesWithRuntimeArgValues == [
      [
        DeviceWithRuntime(device: device2, runtime: "iOS 26.2"),
        DeviceWithRuntime(device: device1, runtime: "iOS 26.2"),
      ],
    ])

    // Then: Runtime selection is not called
    #expect(deviceSelectionPrompt.selectRuntimeCallCount == 0)

    // Then: No error messages are displayed
    #expect(deviceMessage.showNoDevicesFoundAlertCallCount == 0)
  }

  // MARK: With Search Term + showAll=false

  @Test
  func run_shouldSelectRuntimeWithAutoselectWhenShowAllFalseAndSearchTerm() async throws {
    // Given: Search term returns devices in multiple runtimes
    let device1 = Device.stub(name: "iPhone 16 Pro", state: "Shutdown")
    let device2 = Device.stub(name: "iPad Pro", state: "Shutdown")
    let simulators = SimulatorList.stub(runtimes: [
      (id: "com.apple.CoreSimulator.SimRuntime.iOS-26-2", devices: [device1]),
      (id: "com.apple.CoreSimulator.SimRuntime.iPadOS-26-2", devices: [device2]),
    ])
    let selectedRuntime = RuntimeDeviceGroupOption.stub(
      runtime: "iOS 26.2",
      devices: [device1],
    )
    simctl.listDevicesHandler = { _ in simulators }
    deviceSelectionPrompt.selectRuntimeHandler = { _, _ in selectedRuntime }

    // When
    try await command.run(searchTerm: "available", showAll: false)

    // Then: simctl.listDevices is called with correct searchTerm
    #expect(simctl.listDevicesArgValues == [.init("available")])

    // Then: Runtime selection is called with autoselectSingleChoice=true
    #expect(deviceSelectionPrompt.selectRuntimeCallCount == 1)
    let runtimeArgs = deviceSelectionPrompt.selectRuntimeArgValues[0]
    #expect(runtimeArgs.autoselectSingleChoice == true)
    #expect(runtimeArgs.options == [
      RuntimeDeviceGroupOption(runtime: "iOS 26.2", devices: [device1]),
      RuntimeDeviceGroupOption(runtime: "iPadOS 26.2", devices: [device2]),
    ])

    // Then: Table display is called with selected runtime
    #expect(deviceTable.displayInArgValues == [selectedRuntime])

    // Then: Device selection is not called
    #expect(deviceSelectionPrompt.selectDeviceCallCount == 0)
  }

  // MARK: - Edge Cases: Empty Data

  @Test
  func run_shouldShowNoSimulatorsAlertWhenDevicesIsEmpty() async throws {
    // Given: No devices exist
    let simulators = SimulatorList.stub(runtimes: [])
    simctl.listDevicesHandler = { _ in simulators }

    // When
    try await command.run(searchTerm: nil, showAll: true)

    // Then: No simulators alert is shown
    #expect(deviceMessage.showNoSimulatorsAlertCallCount == 1)

    // Then: No other UI components are called
    #expect(deviceSelectionPrompt.selectRuntimeCallCount == 0)
    #expect(deviceTable.displayCallCount == 0)
    #expect(deviceTable.displayInCallCount == 0)
    #expect(deviceTable.displayDevicesWithRuntimeCallCount == 0)
  }

  @Test
  func run_shouldShowNoDevicesFoundAlertWhenSearchResultEmptyWithShowAllTrue() async throws {
    // Given: Search term but no matching devices (empty result after filtering)
    let simulators = SimulatorList.stub(runtimes: [
      (id: "com.apple.CoreSimulator.SimRuntime.iOS-26-2", devices: []),
    ])
    simctl.listDevicesHandler = { _ in simulators }

    // When
    try await command.run(searchTerm: "booted", showAll: true)

    // Then: No devices found alert is shown
    #expect(deviceMessage.showNoDevicesFoundAlertCallCount == 1)

    // Then: Table display is not called
    #expect(deviceTable.displayDevicesWithRuntimeCallCount == 0)
    #expect(deviceSelectionPrompt.selectRuntimeCallCount == 0)
  }

  @Test
  func run_shouldShowNoDevicesFoundAlertWhenSearchResultEmptyWithShowAllFalse() async throws {
    // Given: Search term but no matching devices
    let simulators = SimulatorList.stub(runtimes: [
      (id: "com.apple.CoreSimulator.SimRuntime.iOS-26-2", devices: []),
    ])
    simctl.listDevicesHandler = { _ in simulators }

    // When
    try await command.run(searchTerm: "xyz", showAll: false)

    // Then: No devices found alert is shown
    #expect(deviceMessage.showNoDevicesFoundAlertCallCount == 1)

    // Then: Runtime selection is not called
    #expect(deviceSelectionPrompt.selectRuntimeCallCount == 0)
    #expect(deviceTable.displayInCallCount == 0)
  }

  @Test
  func run_shouldShowNoDevicesForRuntimeMessageWhenSelectedRuntimeHasNoDevices() async throws {
    // Given: Runtime is selected but it has no devices
    let device1 = Device.stub(name: "iPhone 16 Pro", state: "Shutdown")
    let simulators = SimulatorList.stub(runtimes: [
      (id: "com.apple.CoreSimulator.SimRuntime.iOS-26-2", devices: [device1]),
    ])
    simctl.listDevicesHandler = { _ in simulators }

    let selectedRuntime = RuntimeDeviceGroupOption.stub(
      runtime: "iOS 26.2",
      devices: [],
    )
    deviceSelectionPrompt.selectRuntimeHandler = { _, _ in selectedRuntime }

    // When
    try await command.run(searchTerm: nil, showAll: true)

    // Then: No devices for runtime message is shown
    #expect(deviceMessage.showNoDevicesForRuntimeMessageCallCount == 1)

    // Then: Table display and device selection are not called
    #expect(deviceTable.displayInCallCount == 0)
    #expect(deviceSelectionPrompt.selectDeviceCallCount == 0)
  }

  // MARK: - Error Handling

  @Test
  func run_shouldShowErrorAlertWhenSimctlThrowsSimctlError() async throws {
    // Given: simctl throws SimctlError
    simctl.listDevicesHandler = { _ in
      throw SimctlError.xcrunNotFound
    }

    // When
    try await command.run(searchTerm: nil, showAll: true)

    // Then: Error alert is shown
    #expect(simctlErrorAlert.showArgValues == [.xcrunNotFound])

    // Then: No UI components are called
    #expect(deviceSelectionPrompt.selectRuntimeCallCount == 0)
    #expect(deviceTable.displayCallCount == 0)
  }

  @Test
  func run_shouldRethrowNonSimctlErrors() async throws {
    // Given: simctl throws non-SimctlError
    simctl.listDevicesHandler = { _ in
      throw CancellationError()
    }

    // When/Then: Error is rethrown
    await #expect(throws: CancellationError.self) {
      try await command.run(searchTerm: nil, showAll: true)
    }

    // Then: Error alert is NOT called
    #expect(simctlErrorAlert.showCallCount == 0)
  }

  // MARK: - Additional Test Cases

  @Test
  func run_shouldDisplayTableWhenSingleRuntimeAndShowAllTrue() async throws {
    // Given: Single runtime with multiple devices
    let device1 = Device.stub(name: "iPhone 16 Pro", state: "Shutdown")
    let device2 = Device.stub(name: "iPhone 16", state: "Booted")
    let simulators = SimulatorList.stub(runtimes: [
      (id: "com.apple.CoreSimulator.SimRuntime.iOS-26-2", devices: [device1, device2]),
    ])
    simctl.listDevicesHandler = { _ in simulators }

    let selectedRuntime = RuntimeDeviceGroupOption.stub(
      runtime: "iOS 26.2",
      devices: [device1, device2],
    )
    deviceSelectionPrompt.selectRuntimeHandler = { _, _ in selectedRuntime }

    // When
    try await command.run(searchTerm: nil, showAll: true)

    // Then: Runtime selection is called
    #expect(deviceSelectionPrompt.selectRuntimeCallCount == 1)

    // Then: Table display is called
    #expect(deviceTable.displayInCallCount == 1)
  }

  @Test
  func run_shouldAutoselectRuntimeWhenSingleRuntimeAndSearchTerm() async throws {
    // Given: Search term returns devices in single runtime
    let device1 = Device.stub(name: "iPhone 16 Pro", state: "Booted")
    let simulators = SimulatorList.stub(runtimes: [
      (id: "com.apple.CoreSimulator.SimRuntime.iOS-26-2", devices: [device1]),
    ])
    simctl.listDevicesHandler = { _ in simulators }

    let selectedRuntime = RuntimeDeviceGroupOption.stub(
      runtime: "iOS 26.2",
      devices: [device1],
    )
    deviceSelectionPrompt.selectRuntimeHandler = { _, autoselect in
      #expect(autoselect == true)
      return selectedRuntime
    }

    // When
    try await command.run(searchTerm: "booted", showAll: false)

    // Then: Runtime selection is called with autoselectSingleChoice=true
    #expect(deviceSelectionPrompt.selectRuntimeCallCount == 1)
    let runtimeArgs = deviceSelectionPrompt.selectRuntimeArgValues[0]
    #expect(runtimeArgs.autoselectSingleChoice == true)

    // Then: Table display is called
    #expect(deviceTable.displayInCallCount == 1)
  }

  @Test
  func run_shouldHandleEmptyStringSearchTermAsNoSearchTerm() async throws {
    // Given: Empty string as search term
    let device1 = Device.stub(name: "iPhone 16 Pro", state: "Shutdown")
    let simulators = SimulatorList.stub(runtimes: [
      (id: "com.apple.CoreSimulator.SimRuntime.iOS-26-2", devices: [device1]),
    ])
    simctl.listDevicesHandler = { _ in simulators }

    let selectedRuntime = RuntimeDeviceGroupOption.stub(
      runtime: "iOS 26.2",
      devices: [device1],
    )
    deviceSelectionPrompt.selectRuntimeHandler = { _, _ in selectedRuntime }

    // When: Empty string is treated as no search term
    try await command.run(searchTerm: "", showAll: true)

    // Then: simctl.listDevices is called with nil searchTerm (empty string is converted to nil)
    #expect(simctl.listDevicesArgValues == [nil])

    // Then: Runtime selection is called with autoselectSingleChoice=false (like no search term)
    #expect(deviceSelectionPrompt.selectRuntimeCallCount == 1)
    let runtimeArgs = deviceSelectionPrompt.selectRuntimeArgValues[0]
    #expect(runtimeArgs.autoselectSingleChoice == false)

    // Then: Table display is called
    #expect(deviceTable.displayInCallCount == 1)
  }
}
