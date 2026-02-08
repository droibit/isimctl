import Foundation
import Testing
@testable import SimctlKit
@testable import SimctlKitMocks

struct SimulatorListTests {
  // MARK: - Normal Cases

  @Test
  func filtering_shouldFilterDevicesByStateInSingleRuntime() {
    // Given: A SimulatorList with a single runtime containing mixed device states
    let devices: [String: [Device]] = [
      "com.apple.CoreSimulator.SimRuntime.iOS-18-1": [
        Device.stub(name: "iPhone 16", state: "Booted"),
        Device.stub(name: "iPhone 15", state: "Shutdown"),
        Device.stub(name: "iPhone 14", state: "Booted"),
      ],
    ]
    let simulatorList = SimulatorList(devices)

    // When: Filtering by booted state
    let result = simulatorList.filtering(state: .booted)
    // Then: Only booted devices should be included
    #expect(result.devices == [
      "com.apple.CoreSimulator.SimRuntime.iOS-18-1": [
        Device.stub(name: "iPhone 16", state: "Booted"),
        Device.stub(name: "iPhone 14", state: "Booted"),
      ],
    ])
  }

  @Test
  func filtering_shouldFilterAcrossMultipleRuntimes() {
    // Given: A SimulatorList with multiple runtimes containing mixed device states
    let devices: [String: [Device]] = [
      "com.apple.CoreSimulator.SimRuntime.iOS-18-1": [
        Device.stub(name: "iPhone 16", state: "Booted"),
        Device.stub(name: "iPhone 15", state: "Shutdown"),
      ],
      "com.apple.CoreSimulator.SimRuntime.iOS-17-2": [
        Device.stub(name: "iPhone 14", state: "Shutdown"),
        Device.stub(name: "iPhone 13", state: "Shutdown"),
      ],
    ]
    let simulatorList = SimulatorList(devices)

    // When: Filtering by shutdown state
    let result = simulatorList.filtering(state: .shutdown)
    // Then: Only shutdown devices should be included, and runtimes with only booted devices should be excluded
    #expect(result.devices == [
      "com.apple.CoreSimulator.SimRuntime.iOS-18-1": [
        Device.stub(name: "iPhone 15", state: "Shutdown"),
      ],
      "com.apple.CoreSimulator.SimRuntime.iOS-17-2": [
        Device.stub(name: "iPhone 14", state: "Shutdown"),
        Device.stub(name: "iPhone 13", state: "Shutdown"),
      ],
    ])
  }

  @Test(arguments: [
    (deviceState: DeviceState.booted, expectedDeviceName: "iPhone 16"),
    (deviceState: DeviceState.shutdown, expectedDeviceName: "iPhone 15"),
  ])
  func filtering_shouldMatchStatesCaseInsensitively(
    deviceState: DeviceState,
    expectedDeviceName: String,
  ) {
    // Given: A SimulatorList with devices in specific states
    let devices: [String: [Device]] = [
      "com.apple.CoreSimulator.SimRuntime.iOS-18-1": [
        Device.stub(name: "iPhone 16", state: "booted"),
        Device.stub(name: "iPhone 15", state: "SHUTDOWN"),
      ],
    ]
    let simulatorList = SimulatorList(devices)

    // When: Filtering with different casing
    let result = simulatorList.filtering(state: deviceState)
    // Then: Should match devices case-insensitively
    let matchedDeviceName = result.devices["com.apple.CoreSimulator.SimRuntime.iOS-18-1"]?.first?.name
    #expect(matchedDeviceName == expectedDeviceName)
  }

  // MARK: - Edge Cases

  @Test
  func filtering_shouldReturnAllDevicesWhenAllMatch() {
    // Given: A SimulatorList where all devices have the same state
    let devices: [String: [Device]] = [
      "com.apple.CoreSimulator.SimRuntime.iOS-18-1": [
        Device.stub(name: "iPhone 16", state: "Booted"),
        Device.stub(name: "iPhone 15", state: "Booted"),
      ],
    ]
    let simulatorList = SimulatorList(devices)

    // When: Filtering by the matching state
    let result = simulatorList.filtering(state: .booted)
    // Then: All devices and runtimes should be preserved
    #expect(result.devices == devices)
  }

  @Test(arguments: [
    [:],
    [
      "com.apple.CoreSimulator.SimRuntime.iOS-18-1": [Device](),
      "com.apple.CoreSimulator.SimRuntime.iOS-17-2": [Device](),
    ],
  ])
  func filtering_shouldReturnEmptyWhenStartingWithEmptyList(devices: [String: [Device]]) {
    // Given: An empty SimulatorList
    let simulatorList = SimulatorList(devices)

    // When: Filtering by any state
    let result = simulatorList.filtering(state: .booted)
    // Then: Result should remain empty
    #expect(result.devices.isEmpty)
  }
}
