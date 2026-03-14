// swiftlint:disable type_body_length file_length
import SimctlKit
import SimctlKitMocks
import Testing
@testable import IsimctlUI
@testable import IsimctlUIMocks

struct ShutdownDeviceCommandTests {
  private let simctl: SimctlableMock
  private let deviceSelectionPrompt: DeviceSelectionPromptingMock
  private let shutdownDeviceMessage: ShutdownDeviceMessagingMock
  private let simctlErrorAlert: SimctlErrorAlertingMock
  private let command: ShutdownDeviceCommand

  init() {
    simctl = SimctlableMock()
    deviceSelectionPrompt = DeviceSelectionPromptingMock()
    shutdownDeviceMessage = ShutdownDeviceMessagingMock()
    simctlErrorAlert = SimctlErrorAlertingMock()
    command = ShutdownDeviceCommand(
      simctl: simctl,
      deviceSelectionPrompt: deviceSelectionPrompt,
      shutdownDeviceMessage: shutdownDeviceMessage,
      simctlErrorAlert: simctlErrorAlert,
    )
  }

  // MARK: - Normal Cases

  @Test
  func run_shouldShutdownDeviceSuccessfullyWhenBootedDevicesExist() async throws {
    // Given: Multiple booted devices exist
    let device1 = Device.stub(name: "iPhone 16 Pro", state: "Booted")
    let device2 = Device.stub(name: "iPhone 16", state: "Booted")
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

    simctl.shutdownHandler = { _ in }

    // When
    try await command.run()

    // Then: simctl.listDevices is called with .booted searchTerm
    #expect(simctl.listDevicesArgValues == [.booted])

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

    // Then: Shutting down message is shown
    #expect(shutdownDeviceMessage.showShuttingDownDeviceMessageCallCount == 1)

    // Then: shutdownDevice is called with correct UDID
    #expect(simctl.shutdownArgValues == [.device(udid: device1.udid)])

    // Then: Success alert is shown
    #expect(shutdownDeviceMessage.showShutdownSuccessAlertArgValues == [selectedDevice])

    // Then: No error alert is shown
    #expect(simctlErrorAlert.showCallCount == 0)
    #expect(shutdownDeviceMessage.showNoShuttableDevicesAlertCallCount == 0)
    #expect(shutdownDeviceMessage.showShutdownAllSuccessAlertCallCount == 0)
  }

  // MARK: - All Devices

  @Test
  func run_shouldShutdownAllDevicesWhenAllDevicesIsTrue() async throws {
    // Given: Booted devices exist
    let device1 = Device.stub(name: "iPhone 16 Pro", state: "Booted")
    let device2 = Device.stub(name: "iPhone 16", state: "Booted")
    let simulators = SimulatorList.stub(runtimes: [
      (id: "com.apple.CoreSimulator.SimRuntime.iOS-18-2", devices: [device1, device2]),
    ])
    simctl.listDevicesHandler = { _ in simulators }
    simctl.shutdownHandler = { _ in }

    // When: allDevices is true
    try await command.run(allDevices: true)

    // Then: simctl.listDevices is called with .booted searchTerm
    #expect(simctl.listDevicesArgValues == [.booted])

    // Then: shutdownDevice is called with .all
    #expect(simctl.shutdownArgValues == [.all])

    // Then: Shutting down message is shown
    #expect(shutdownDeviceMessage.showShuttingDownDeviceMessageCallCount == 1)

    // Then: All success alert is shown
    #expect(shutdownDeviceMessage.showShutdownAllSuccessAlertCallCount == 1)

    // Then: Device selection prompts are not called
    #expect(deviceSelectionPrompt.selectRuntimeCallCount == 0)
    #expect(deviceSelectionPrompt.selectDeviceCallCount == 0)

    // Then: No individual success alert or error alert is shown
    #expect(shutdownDeviceMessage.showShutdownSuccessAlertCallCount == 0)
    #expect(shutdownDeviceMessage.showNoShuttableDevicesAlertCallCount == 0)
    #expect(simctlErrorAlert.showCallCount == 0)
  }

  // MARK: - Edge Cases: Empty Data

  @Test
  func run_shouldShowNoShuttableDevicesAlertWhenNoBootedDevices() async throws {
    // Given: No booted devices exist
    let simulators = SimulatorList.stub(runtimes: [])
    simctl.listDevicesHandler = { _ in simulators }

    // When: allDevices is false (default)
    try await command.run()

    // Then: No shutable devices alert is shown
    #expect(shutdownDeviceMessage.showNoShuttableDevicesAlertCallCount == 1)

    // Then: Runtime and device selection are not called
    #expect(deviceSelectionPrompt.selectRuntimeCallCount == 0)
    #expect(deviceSelectionPrompt.selectDeviceCallCount == 0)

    // Then: Shutdown process is not executed
    #expect(shutdownDeviceMessage.showShuttingDownDeviceMessageCallCount == 0)
    #expect(simctl.shutdownCallCount == 0)
    #expect(shutdownDeviceMessage.showShutdownSuccessAlertCallCount == 0)
    #expect(shutdownDeviceMessage.showShutdownAllSuccessAlertCallCount == 0)
  }

  @Test
  func run_shouldShowNoShuttableDevicesAlertWhenRuntimesHaveEmptyDeviceLists() async throws {
    // Given: Runtimes exist, but all have empty device lists (e.g., xcrun simctl returned empty arrays)
    let simulators = SimulatorList.stub(runtimes: [
      (id: "com.apple.CoreSimulator.SimRuntime.iOS-18-2", devices: []),
      (id: "com.apple.CoreSimulator.SimRuntime.iPadOS-18-2", devices: []),
    ])
    simctl.listDevicesHandler = { _ in simulators }

    // When: allDevices is false (default)
    try await command.run()

    // Then: No shutable devices alert is shown
    #expect(shutdownDeviceMessage.showNoShuttableDevicesAlertCallCount == 1)

    // Then: Runtime and device selection are not called
    #expect(deviceSelectionPrompt.selectRuntimeCallCount == 0)
    #expect(deviceSelectionPrompt.selectDeviceCallCount == 0)

    // Then: Shutdown process is not executed
    #expect(shutdownDeviceMessage.showShuttingDownDeviceMessageCallCount == 0)
    #expect(simctl.shutdownCallCount == 0)
    #expect(shutdownDeviceMessage.showShutdownSuccessAlertCallCount == 0)
    #expect(shutdownDeviceMessage.showShutdownAllSuccessAlertCallCount == 0)
  }

  @Test
  func run_shouldShowNoShuttableDevicesAlertWhenNoBootedDevicesEvenWithAllDevicesFlag() async throws {
    // Given: No booted devices exist
    let simulators = SimulatorList.stub(runtimes: [])
    simctl.listDevicesHandler = { _ in simulators }

    // When: allDevices is true
    try await command.run(allDevices: true)

    // Then: No shutable devices alert is shown (same as allDevices: false)
    #expect(shutdownDeviceMessage.showNoShuttableDevicesAlertCallCount == 1)

    // Then: Shutdown process is not executed
    #expect(shutdownDeviceMessage.showShuttingDownDeviceMessageCallCount == 0)
    #expect(simctl.shutdownCallCount == 0)
    #expect(shutdownDeviceMessage.showShutdownSuccessAlertCallCount == 0)
    #expect(shutdownDeviceMessage.showShutdownAllSuccessAlertCallCount == 0)
  }

  @Test
  func run_shouldShowNoShuttableDevicesAlertWhenRuntimesHaveEmptyDeviceListsEvenWithAllDevicesFlag() async throws {
    // Given: Runtimes exist, but all have empty device lists (e.g., xcrun simctl returned empty arrays)
    let simulators = SimulatorList.stub(runtimes: [
      (id: "com.apple.CoreSimulator.SimRuntime.iOS-18-2", devices: []),
      (id: "com.apple.CoreSimulator.SimRuntime.iPadOS-18-2", devices: []),
    ])
    simctl.listDevicesHandler = { _ in simulators }

    // When: allDevices is true
    try await command.run(allDevices: true)

    // Then: No shutable devices alert is shown
    #expect(shutdownDeviceMessage.showNoShuttableDevicesAlertCallCount == 1)

    // Then: Shutdown process is not executed
    #expect(shutdownDeviceMessage.showShuttingDownDeviceMessageCallCount == 0)
    #expect(simctl.shutdownCallCount == 0)
    #expect(shutdownDeviceMessage.showShutdownSuccessAlertCallCount == 0)
    #expect(shutdownDeviceMessage.showShutdownAllSuccessAlertCallCount == 0)
  }

  // MARK: - Error Handling

  @Test
  func run_shouldShowErrorAlertWhenListDevicesThrowsSimctlError() async throws {
    // Given: simctl.listDevices throws SimctlError
    simctl.listDevicesHandler = { _ in
      throw SimctlError.xcrunNotFound
    }

    // When
    try await command.run()

    // Then: Error alert is shown
    #expect(simctlErrorAlert.showArgValues == [.xcrunNotFound])

    // Then: No other UI components are called
    #expect(deviceSelectionPrompt.selectRuntimeCallCount == 0)
    #expect(deviceSelectionPrompt.selectDeviceCallCount == 0)
    #expect(shutdownDeviceMessage.showShuttingDownDeviceMessageCallCount == 0)
    #expect(simctl.shutdownCallCount == 0)
    #expect(shutdownDeviceMessage.showShutdownSuccessAlertCallCount == 0)
  }

  @Test
  func run_shouldRethrowWhenListDevicesThrowsNonSimctlError() async throws {
    // Given: simctl.listDevices throws non-SimctlError
    simctl.listDevicesHandler = { _ in
      throw CancellationError()
    }

    // When/Then: Error is rethrown
    await #expect(throws: CancellationError.self) {
      try await command.run()
    }

    // Then: Error alert is NOT called
    #expect(simctlErrorAlert.showCallCount == 0)
  }

  @Test
  func run_shouldShowErrorAlertWhenShutdownDeviceThrowsSimctlError() async throws {
    // Given: shutdownDevice throws SimctlError
    let device = Device.stub(name: "iPhone 16 Pro", state: "Booted")
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

    let expectedError = SimctlError.commandFailed(
      command: "xcrun simctl shutdown \(device.udid)",
      description: "Unable to shutdown device in current state: Shutdown",
    )
    simctl.shutdownHandler = { _ in
      throw expectedError
    }

    // When
    try await command.run()

    // Then: Error alert is shown
    #expect(simctlErrorAlert.showArgValues == [expectedError])

    // Then: Shutting down message is shown (before error occurs)
    #expect(shutdownDeviceMessage.showShuttingDownDeviceMessageCallCount == 1)

    // Then: Success alert is NOT shown
    #expect(shutdownDeviceMessage.showShutdownSuccessAlertCallCount == 0)
  }

  @Test
  func run_shouldRethrowWhenShutdownDeviceThrowsNonSimctlError() async throws {
    // Given: shutdownDevice throws non-SimctlError
    let device = Device.stub(name: "iPhone 16 Pro", state: "Booted")
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

    simctl.shutdownHandler = { _ in
      throw CancellationError()
    }

    // When/Then: Error is rethrown
    await #expect(throws: CancellationError.self) {
      try await command.run()
    }

    // Then: Error alert is NOT called
    #expect(simctlErrorAlert.showCallCount == 0)
  }

  // MARK: - Confirmation Feature

  @Test
  func run_shouldShutdownDeviceWhenConfirmationIsAccepted() async throws {
    // Given: A device exists and user confirms the shutdown
    let device = Device.stub(name: "iPhone 16 Pro", state: "Booted")
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

    shutdownDeviceMessage.confirmShutdownHandler = { true }
    simctl.shutdownHandler = { _ in }

    // When: shouldConfirm is true
    try await command.run(shouldConfirm: true)

    // Then: Confirmation is requested
    #expect(shutdownDeviceMessage.confirmShutdownCallCount == 1)

    // Then: Shutdown process is executed
    #expect(shutdownDeviceMessage.showShuttingDownDeviceMessageCallCount == 1)
    #expect(simctl.shutdownArgValues == [.device(udid: device.udid)])
    #expect(shutdownDeviceMessage.showShutdownSuccessAlertCallCount == 1)
  }

  @Test
  func run_shouldNotShutdownDeviceWhenConfirmationIsRejected() async throws {
    // Given: A device exists and user rejects the shutdown
    let device = Device.stub(name: "iPhone 16 Pro", state: "Booted")
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

    shutdownDeviceMessage.confirmShutdownHandler = { false }

    // When: shouldConfirm is true
    try await command.run(shouldConfirm: true)

    // Then: Confirmation is requested
    #expect(shutdownDeviceMessage.confirmShutdownCallCount == 1)

    // Then: Shutdown process is NOT executed
    #expect(shutdownDeviceMessage.showShuttingDownDeviceMessageCallCount == 0)
    #expect(simctl.shutdownCallCount == 0)
    #expect(shutdownDeviceMessage.showShutdownSuccessAlertCallCount == 0)
  }

  @Test
  func run_shouldSkipConfirmationWhenShouldConfirmIsFalse() async throws {
    // Given: A device exists
    let device = Device.stub(name: "iPhone 16 Pro", state: "Booted")
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

    simctl.shutdownHandler = { _ in }

    // When: shouldConfirm is false (default behavior)
    try await command.run(shouldConfirm: false)

    // Then: Confirmation is NOT requested
    #expect(shutdownDeviceMessage.confirmShutdownCallCount == 0)

    // Then: Shutdown process is executed directly
    #expect(shutdownDeviceMessage.showShuttingDownDeviceMessageCallCount == 1)
    #expect(simctl.shutdownArgValues == [.device(udid: device.udid)])
    #expect(shutdownDeviceMessage.showShutdownSuccessAlertCallCount == 1)
  }
}
