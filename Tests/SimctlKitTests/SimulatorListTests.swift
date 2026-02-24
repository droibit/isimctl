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
    // Then: Only shutdown devices should be included
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

  @Test
  func filtering_shouldPreserveRuntimeWithNoMatchingDevices() {
    // Given: A SimulatorList with one runtime having no booted devices
    let devices: [String: [Device]] = [
      "com.apple.CoreSimulator.SimRuntime.iOS-18-1": [
        Device.stub(name: "iPhone 16", state: "Booted"),
      ],
      "com.apple.CoreSimulator.SimRuntime.iOS-17-2": [
        Device.stub(name: "iPhone 15", state: "Shutdown"),
      ],
    ]
    let simulatorList = SimulatorList(devices)

    // When: Filtering by booted state
    let result = simulatorList.filtering(state: .booted)
    // Then: The runtime with no matching devices should be preserved with an empty device array
    #expect(result.devices == [
      "com.apple.CoreSimulator.SimRuntime.iOS-18-1": [
        Device.stub(name: "iPhone 16", state: "Booted"),
      ],
      "com.apple.CoreSimulator.SimRuntime.iOS-17-2": [],
    ])
  }

  @Test
  func filtering_shouldReturnEmptyWhenDevicesDictionaryIsEmpty() {
    // Given: A SimulatorList with no runtimes
    let simulatorList = SimulatorList([:])

    // When: Filtering by any state
    let result = simulatorList.filtering(state: .booted)
    // Then: Result should remain empty
    #expect(result.devices.isEmpty)
  }

  @Test
  func filtering_shouldPreserveRuntimesWithEmptyDeviceArrays() {
    // Given: A SimulatorList with runtimes that have no devices registered
    let devices: [String: [Device]] = [
      "com.apple.CoreSimulator.SimRuntime.iOS-18-1": [],
      "com.apple.CoreSimulator.SimRuntime.iOS-17-2": [],
    ]
    let simulatorList = SimulatorList(devices)

    // When: Filtering by any state
    let result = simulatorList.filtering(state: .booted)
    // Then: Runtimes should be preserved with empty device arrays
    #expect(result.devices == devices)
  }
}
