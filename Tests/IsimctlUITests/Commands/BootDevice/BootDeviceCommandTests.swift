import SimctlKit
import SimctlKitMocks
import Testing
@testable import IsimctlUI
@testable import IsimctlUIMocks

struct BootDeviceCommandTests {
  private let simctl: SimctlableMock
  private let deviceSelectionPrompt: DeviceSelectionPromptingMock
  private let bootDeviceMessage: BootDeviceMessagingMock
  private let simctlErrorAlert: SimctlErrorAlertingMock
  private let command: BootDeviceCommand

  init() {
    simctl = SimctlableMock()
    deviceSelectionPrompt = DeviceSelectionPromptingMock()
    bootDeviceMessage = BootDeviceMessagingMock()
    simctlErrorAlert = SimctlErrorAlertingMock()
    command = BootDeviceCommand(
      simctl: simctl,
      deviceSelectionPrompt: deviceSelectionPrompt,
      bootDeviceMessage: bootDeviceMessage,
      simctlErrorAlert: simctlErrorAlert,
    )
  }

  // MARK: - Normal Cases

  @Test
  func run_shouldBootDeviceSuccessfullyWhenDevicesExist() async throws {
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

    simctl.bootDeviceHandler = { _ in }

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

    // Then: Booting message is shown
    #expect(bootDeviceMessage.showBootingDeviceMessageArgValues == [selectedDevice])

    // Then: bootDevice is called with correct UDID
    #expect(simctl.bootDeviceArgValues == [device1.udid])

    // Then: Success alert is shown
    #expect(bootDeviceMessage.showBootSuccessAlertArgValues == [selectedDevice])

    // Then: No error alert is shown
    #expect(simctlErrorAlert.showCallCount == 0)
    #expect(bootDeviceMessage.showNoBootableDevicesAlertCallCount == 0)
  }

  // MARK: - Edge Cases: Empty Data

  @Test
  func run_shouldShowNoBootableDevicesAlertWhenNoShutdownDevices() async throws {
    // Given: No shutdown devices exist (all devices are booted or unavailable)
    let simulators = SimulatorList.stub(runtimes: [])
    simctl.listDevicesHandler = { _ in simulators }

    // When
    try await command.run()

    // Then: No bootable devices alert is shown
    #expect(bootDeviceMessage.showNoBootableDevicesAlertCallCount == 1)

    // Then: Runtime and device selection are not called
    #expect(deviceSelectionPrompt.selectRuntimeCallCount == 0)
    #expect(deviceSelectionPrompt.selectDeviceCallCount == 0)

    // Then: Boot process is not executed
    #expect(bootDeviceMessage.showBootingDeviceMessageCallCount == 0)
    #expect(simctl.bootDeviceCallCount == 0)
    #expect(bootDeviceMessage.showBootSuccessAlertCallCount == 0)
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
    #expect(bootDeviceMessage.showBootingDeviceMessageCallCount == 0)
    #expect(simctl.bootDeviceCallCount == 0)
    #expect(bootDeviceMessage.showBootSuccessAlertCallCount == 0)
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
  func run_shouldShowErrorAlertWhenBootDeviceThrowsSimctlError() async throws {
    // Given: bootDevice throws SimctlError (e.g., device already booted)
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

    simctl.bootDeviceHandler = { _ in
      throw SimctlError.commandFailed(
        command: "xcrun simctl boot \(device1.udid)",
        description: "Unable to boot device in current state: Booted",
      )
    }

    // When
    try await command.run()

    // Then: Error alert is shown
    #expect(simctlErrorAlert.showArgValues == [
      .commandFailed(
        command: "xcrun simctl boot \(device1.udid)",
        description: "Unable to boot device in current state: Booted",
      ),
    ])

    // Then: Booting message is shown (before error occurs)
    #expect(bootDeviceMessage.showBootingDeviceMessageCallCount == 1)

    // Then: Success alert is NOT shown
    #expect(bootDeviceMessage.showBootSuccessAlertCallCount == 0)
  }

  @Test
  func run_shouldRethrowWhenBootDeviceThrowsNonSimctlError() async throws {
    // Given: bootDevice throws non-SimctlError
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

    simctl.bootDeviceHandler = { _ in
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
  func run_shouldBootDeviceWhenConfirmationIsAccepted() async throws {
    // Given: A device exists and user confirms the boot
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

    bootDeviceMessage.confirmBootHandler = { true }
    simctl.bootDeviceHandler = { _ in }

    // When: shouldConfirm is true
    try await command.run(shouldConfirm: true)

    // Then: Confirmation is requested
    #expect(bootDeviceMessage.confirmBootCallCount == 1)

    // Then: Boot process is executed
    #expect(bootDeviceMessage.showBootingDeviceMessageArgValues == [selectedDevice])
    #expect(simctl.bootDeviceArgValues == [device.udid])
    #expect(bootDeviceMessage.showBootSuccessAlertCallCount == 1)
  }

  @Test
  func run_shouldNotBootDeviceWhenConfirmationIsRejected() async throws {
    // Given: A device exists and user rejects the boot
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

    bootDeviceMessage.confirmBootHandler = { false }

    // When: shouldConfirm is true
    try await command.run(shouldConfirm: true)

    // Then: Confirmation is requested
    #expect(bootDeviceMessage.confirmBootCallCount == 1)

    // Then: Boot process is NOT executed
    #expect(bootDeviceMessage.showBootingDeviceMessageCallCount == 0)
    #expect(simctl.bootDeviceCallCount == 0)
    #expect(bootDeviceMessage.showBootSuccessAlertCallCount == 0)
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

    simctl.bootDeviceHandler = { _ in }

    // When: shouldConfirm is false (default behavior)
    try await command.run(shouldConfirm: false)

    // Then: Confirmation is NOT requested
    #expect(bootDeviceMessage.confirmBootCallCount == 0)

    // Then: Boot process is executed directly
    #expect(bootDeviceMessage.showBootingDeviceMessageCallCount == 1)
    #expect(simctl.bootDeviceArgValues == [device.udid])
    #expect(bootDeviceMessage.showBootSuccessAlertCallCount == 1)
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

    simctl.bootDeviceHandler = { _ in }

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
    #expect(bootDeviceMessage.showBootingDeviceMessageCallCount == 1)
    #expect(simctl.bootDeviceCallCount == 1)
    #expect(bootDeviceMessage.showBootSuccessAlertCallCount == 1)

    // Then: Boot is called with selected device's UDID
    #expect(simctl.bootDeviceArgValues == ["udid-2"])
  }
}
