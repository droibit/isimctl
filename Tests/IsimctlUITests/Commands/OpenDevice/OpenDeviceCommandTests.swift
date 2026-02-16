import SimctlKit
import SimctlKitMocks
import SimulatorKit
import SimulatorKitMocks
import Testing
@testable import IsimctlUI
@testable import IsimctlUIMocks

struct OpenDeviceCommandTests {
  private let simctl: SimctlableMock
  private let openSimulator: SimulatorOpenableMock
  private let deviceSelectionPrompt: DeviceSelectionPromptingMock
  private let openDeviceMessage: OpenDeviceMessagingMock
  private let openSimulatorErrorAlert: OpenSimulatorErrorAlertingMock
  private let command: OpenDeviceCommand

  init() {
    simctl = SimctlableMock()
    openSimulator = SimulatorOpenableMock()
    deviceSelectionPrompt = DeviceSelectionPromptingMock()
    openDeviceMessage = OpenDeviceMessagingMock()
    openSimulatorErrorAlert = OpenSimulatorErrorAlertingMock()
    command = OpenDeviceCommand(
      simctl: simctl,
      openSimulator: openSimulator,
      deviceSelectionPrompt: deviceSelectionPrompt,
      openDeviceMessage: openDeviceMessage,
      openSimulatorErrorAlert: openSimulatorErrorAlert,
    )
  }

  // MARK: - Normal Cases

  @Test
  func run_shouldOpenDeviceSuccessfullyWhenDevicesExist() async throws {
    // Given: Multiple shutdown devices exist
    let device1 = Device.stub(name: "iPhone 16 Pro", state: "Shutdown")
    let device2 = Device.stub(name: "iPhone 16", state: "Shutdown")
    let simulators = SimulatorList.stub(runtimes: [
      (id: "com.apple.CoreSimulator.SimRuntime.iOS-18-2", devices: [device1, device2]),
    ])
    simctl.listDevicesHandler = { _ in simulators }

    let selectedRuntime = RuntimeDeviceGroupOption.stub(
      runtime: "iOS 18.2",
      devices: [device2, device1],
    )
    deviceSelectionPrompt.selectRuntimeHandler = { _, _ in selectedRuntime }

    let selectedDevice = DeviceOption(device1)
    deviceSelectionPrompt.selectDeviceHandler = { _ in selectedDevice }

    openSimulator.openHandler = { _ in }

    // When
    try await command.run()

    // Then: simctl.listDevices is called with correct searchTerm
    #expect(simctl.listDevicesArgValues == [.available])

    // Then: Runtime selection is called with autoselectSingleChoice=false
    #expect(deviceSelectionPrompt.selectRuntimeCallCount == 1)
    let runtimeArgs = deviceSelectionPrompt.selectRuntimeArgValues[0]
    #expect(runtimeArgs.autoselectSingleChoice == false)
    #expect(runtimeArgs.options == [
      RuntimeDeviceGroupOption(runtime: "iOS 18.2", devices: [device2, device1]),
    ])

    // Then: Device selection is called with correct options
    #expect(deviceSelectionPrompt.selectDeviceArgValues == [
      [DeviceOption(device2), DeviceOption(device1)],
    ])

    // Then: Opening message is shown
    #expect(openDeviceMessage.showOpeningDeviceMessageCallCount == 1)

    // Then: openSimulator is called with correct UDID
    #expect(openSimulator.openArgValues == [device1.udid])

    // Then: Success alert is shown
    #expect(openDeviceMessage.showOpenSuccessAlertArgValues == [selectedDevice])

    // Then: No error alert is shown
    #expect(openSimulatorErrorAlert.showCallCount == 0)
    #expect(openDeviceMessage.showNoOpenableDevicesAlertCallCount == 0)
  }

  // MARK: - Edge Cases: Empty Data

  @Test
  func run_shouldShowNoOpenableDevicesAlertWhenNoShutdownDevices() async throws {
    // Given: No shutdown devices exist (all devices are booted or unavailable)
    let simulators = SimulatorList.stub(runtimes: [])
    simctl.listDevicesHandler = { _ in simulators }

    // When
    try await command.run()

    // Then: No openable devices alert is shown
    #expect(openDeviceMessage.showNoOpenableDevicesAlertCallCount == 1)

    // Then: Runtime and device selection are not called
    #expect(deviceSelectionPrompt.selectRuntimeCallCount == 0)
    #expect(deviceSelectionPrompt.selectDeviceCallCount == 0)

    // Then: Open process is not executed
    #expect(openDeviceMessage.showOpeningDeviceMessageCallCount == 0)
    #expect(openSimulator.openCallCount == 0)
    #expect(openDeviceMessage.showOpenSuccessAlertCallCount == 0)
  }

  // MARK: - Error Handling

  @Test
  func run_shouldRethrowWhenListDevicesThrowsSimctlError() async throws {
    // Given: simctl.listDevices throws SimctlError
    simctl.listDevicesHandler = { _ in
      throw SimctlError.xcrunNotFound
    }

    // When/Then: Error is rethrown (SimctlError is not caught by OpenDeviceCommand)
    await #expect(throws: SimctlError.self) {
      try await command.run()
    }

    // Then: Error alert is NOT called
    #expect(openSimulatorErrorAlert.showCallCount == 0)

    // Then: No other UI components are called
    #expect(deviceSelectionPrompt.selectRuntimeCallCount == 0)
    #expect(deviceSelectionPrompt.selectDeviceCallCount == 0)
    #expect(openDeviceMessage.showOpeningDeviceMessageCallCount == 0)
    #expect(openSimulator.openCallCount == 0)
    #expect(openDeviceMessage.showOpenSuccessAlertCallCount == 0)
  }

  @Test
  func run_shouldRethrowWhenListDevicesThrowsError() async throws {
    // Given: simctl.listDevices throws error
    simctl.listDevicesHandler = { _ in
      throw CancellationError()
    }

    // When/Then: Error is rethrown
    await #expect(throws: CancellationError.self) {
      try await command.run()
    }

    // Then: Error alert is NOT called
    #expect(openSimulatorErrorAlert.showCallCount == 0)
  }

  @Test
  func run_shouldShowErrorAlertWhenOpenSimulatorThrowsOpenSimulatorError() async throws {
    // Given: openSimulator throws OpenSimulatorError
    let device1 = Device.stub(name: "iPhone 16 Pro", state: "Shutdown")
    let simulators = SimulatorList.stub(runtimes: [
      (id: "com.apple.CoreSimulator.SimRuntime.iOS-18-2", devices: [device1]),
    ])
    simctl.listDevicesHandler = { _ in simulators }

    let selectedRuntime = RuntimeDeviceGroupOption.stub(
      runtime: "iOS 18.2",
      devices: [device1],
    )
    deviceSelectionPrompt.selectRuntimeHandler = { _, _ in selectedRuntime }

    let selectedDevice = DeviceOption(device1)
    deviceSelectionPrompt.selectDeviceHandler = { _ in selectedDevice }

    let expectedError = OpenSimulatorError(
      command: "open -a \"Simulator\"",
      description: "Command execution failed with exit code 1",
    )
    openSimulator.openHandler = { _ in
      throw expectedError
    }

    // When
    try await command.run()

    // Then: Error alert is shown
    #expect(openSimulatorErrorAlert.showArgValues == [expectedError])
    // Then: Opening message is shown (before error occurs)
    #expect(openDeviceMessage.showOpeningDeviceMessageCallCount == 1)
    // Then: Success alert is NOT shown
    #expect(openDeviceMessage.showOpenSuccessAlertCallCount == 0)
  }

  @Test
  func run_shouldRethrowWhenOpenSimulatorThrowsNonOpenSimulatorError() async throws {
    // Given: openSimulator throws non-OpenSimulatorError
    let device1 = Device.stub(name: "iPhone 16 Pro", state: "Shutdown")
    let simulators = SimulatorList.stub(runtimes: [
      (id: "com.apple.CoreSimulator.SimRuntime.iOS-18-2", devices: [device1]),
    ])
    simctl.listDevicesHandler = { _ in simulators }

    let selectedRuntime = RuntimeDeviceGroupOption.stub(
      runtime: "iOS 18.2",
      devices: [device1],
    )
    deviceSelectionPrompt.selectRuntimeHandler = { _, _ in selectedRuntime }

    let selectedDevice = DeviceOption(device1)
    deviceSelectionPrompt.selectDeviceHandler = { _ in selectedDevice }

    openSimulator.openHandler = { _ in
      throw CancellationError()
    }

    // When/Then: Error is rethrown
    await #expect(throws: CancellationError.self) {
      try await command.run()
    }

    // Then: Error alert is NOT called
    #expect(openSimulatorErrorAlert.showCallCount == 0)
  }

  // MARK: - Confirmation Feature

  @Test
  func run_shouldOpenDeviceWhenConfirmationIsAccepted() async throws {
    // Given: A device exists and user confirms the open
    let device = Device.stub(name: "iPhone 16 Pro", state: "Shutdown")
    let simulators = SimulatorList.stub(runtimes: [
      (id: "com.apple.CoreSimulator.SimRuntime.iOS-18-2", devices: [device]),
    ])
    simctl.listDevicesHandler = { _ in simulators }

    let selectedRuntime = RuntimeDeviceGroupOption.stub(
      runtime: "iOS 18.2",
      devices: [device],
    )
    deviceSelectionPrompt.selectRuntimeHandler = { _, _ in selectedRuntime }

    let selectedDevice = DeviceOption(device)
    deviceSelectionPrompt.selectDeviceHandler = { _ in selectedDevice }

    openDeviceMessage.confirmOpenHandler = { true }
    openSimulator.openHandler = { _ in }

    // When: shouldConfirm is true
    try await command.run(shouldConfirm: true)

    // Then: Confirmation is requested
    #expect(openDeviceMessage.confirmOpenCallCount == 1)

    // Then: Open process is executed
    #expect(openDeviceMessage.showOpeningDeviceMessageCallCount == 1)
    #expect(openSimulator.openArgValues == [device.udid])
    #expect(openDeviceMessage.showOpenSuccessAlertCallCount == 1)
  }

  @Test
  func run_shouldNotOpenDeviceWhenConfirmationIsRejected() async throws {
    // Given: A device exists and user rejects the open
    let device = Device.stub(name: "iPhone 16 Pro", state: "Shutdown")
    let simulators = SimulatorList.stub(runtimes: [
      (id: "com.apple.CoreSimulator.SimRuntime.iOS-18-2", devices: [device]),
    ])
    simctl.listDevicesHandler = { _ in simulators }

    let selectedRuntime = RuntimeDeviceGroupOption.stub(
      runtime: "iOS 18.2",
      devices: [device],
    )
    deviceSelectionPrompt.selectRuntimeHandler = { _, _ in selectedRuntime }

    let selectedDevice = DeviceOption(device)
    deviceSelectionPrompt.selectDeviceHandler = { _ in selectedDevice }

    openDeviceMessage.confirmOpenHandler = { false }

    // When: shouldConfirm is true
    try await command.run(shouldConfirm: true)

    // Then: Confirmation is requested
    #expect(openDeviceMessage.confirmOpenCallCount == 1)

    // Then: Open process is NOT executed
    #expect(openDeviceMessage.showOpeningDeviceMessageCallCount == 0)
    #expect(openSimulator.openCallCount == 0)
    #expect(openDeviceMessage.showOpenSuccessAlertCallCount == 0)
  }

  @Test
  func run_shouldSkipConfirmationWhenShouldConfirmIsFalse() async throws {
    // Given: A device exists
    let device = Device.stub(name: "iPhone 16 Pro", state: "Shutdown")
    let simulators = SimulatorList.stub(runtimes: [
      (id: "com.apple.CoreSimulator.SimRuntime.iOS-18-2", devices: [device]),
    ])
    simctl.listDevicesHandler = { _ in simulators }

    let selectedRuntime = RuntimeDeviceGroupOption.stub(
      runtime: "iOS 18.2",
      devices: [device],
    )
    deviceSelectionPrompt.selectRuntimeHandler = { _, _ in selectedRuntime }

    let selectedDevice = DeviceOption(device)
    deviceSelectionPrompt.selectDeviceHandler = { _ in selectedDevice }

    openSimulator.openHandler = { _ in }

    // When: shouldConfirm is false (default behavior)
    try await command.run(shouldConfirm: false)

    // Then: Confirmation is NOT requested
    #expect(openDeviceMessage.confirmOpenCallCount == 0)
    // Then: Open process is executed directly
    #expect(openDeviceMessage.showOpeningDeviceMessageCallCount == 1)
    #expect(openSimulator.openArgValues == [device.udid])
    #expect(openDeviceMessage.showOpenSuccessAlertCallCount == 1)
  }

  // MARK: - Additional Test Cases

  @Test
  func run_shouldCallComponentsWithCorrectArgumentsForMultipleRuntimes() async throws {
    // Given: Multiple runtimes with multiple devices
    let device1 = Device.stub(name: "iPhone 16 Pro", state: "Shutdown", udid: "udid-1")
    let device2 = Device.stub(name: "iPhone 16", state: "Shutdown", udid: "udid-2")
    let device3 = Device.stub(name: "iPad Pro", state: "Shutdown", udid: "udid-3")
    let simulators = SimulatorList.stub(runtimes: [
      (id: "com.apple.CoreSimulator.SimRuntime.iOS-18-2", devices: [device1, device2]),
      (id: "com.apple.CoreSimulator.SimRuntime.iPadOS-18-2", devices: [device3]),
    ])
    simctl.listDevicesHandler = { _ in simulators }

    let selectedRuntime = RuntimeDeviceGroupOption.stub(
      runtime: "iOS 18.2",
      devices: [device2, device1],
    )
    deviceSelectionPrompt.selectRuntimeHandler = { _, _ in selectedRuntime }

    let selectedDevice = DeviceOption(device2)
    deviceSelectionPrompt.selectDeviceHandler = { _ in selectedDevice }

    openSimulator.openHandler = { _ in }

    // When
    try await command.run()

    // Then: Runtime options are sorted alphabetically
    #expect(deviceSelectionPrompt.selectRuntimeCallCount == 1)
    let runtimeArgs = deviceSelectionPrompt.selectRuntimeArgValues[0]
    #expect(runtimeArgs.options == [
      RuntimeDeviceGroupOption(runtime: "iOS 18.2", devices: [device2, device1]),
      RuntimeDeviceGroupOption(runtime: "iPadOS 18.2", devices: [device3]),
    ])

    // Then: Device options are sorted alphabetically
    #expect(deviceSelectionPrompt.selectDeviceArgValues == [
      [DeviceOption(device2), DeviceOption(device1)],
    ])
    // Then: Components are called in correct order
    #expect(deviceSelectionPrompt.selectRuntimeCallCount == 1)
    #expect(deviceSelectionPrompt.selectDeviceCallCount == 1)
    #expect(openDeviceMessage.showOpeningDeviceMessageCallCount == 1)
    #expect(openSimulator.openCallCount == 1)
    #expect(openDeviceMessage.showOpenSuccessAlertCallCount == 1)
    // Then: Open is called with selected device's UDID
    #expect(openSimulator.openArgValues == ["udid-2"])
  }
}
