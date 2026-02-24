import SimctlKit
import Testing
@testable import IsimctlUI

struct SimulatorListUITests {
  // MARK: - toRuntimeDeviceGroupOptions tests

  @Test
  func toRuntimeDeviceGroupOptions_shouldConvertSingleRuntimeCorrectly() {
    let devices = [
      Device(
        name: "iPhone 17",
        state: "Booted",
        udid: "device-1",
        deviceTypeIdentifier: "type-1",
      ),
      Device(
        name: "iPhone 17 Pro",
        state: "Shutdown",
        udid: "device-2",
        deviceTypeIdentifier: "type-2",
      ),
    ]
    let simulatorList = SimulatorList([
      "com.apple.CoreSimulator.SimRuntime.iOS-26-2": devices,
    ])

    let result = simulatorList.toRuntimeDeviceGroupOptions()
    #expect(result == [
      RuntimeDeviceGroupOption(
        runtime: "iOS 26.2",
        devices: devices,
      ),
    ])
  }

  @Test
  func toRuntimeDeviceGroupOptions_shouldConvertMultipleRuntimesCorrectly() {
    let iOSDevices = [
      Device(
        name: "iPhone 16",
        state: "Booted",
        udid: "ios-device-1",
        deviceTypeIdentifier: "type-1",
      ),
    ]
    let watchOSDevices = [
      Device(
        name: "Apple Watch Series 10",
        state: "Shutdown",
        udid: "watch-device-1",
        deviceTypeIdentifier: "type-2",
      ),
    ]
    let tvOSDevices = [
      Device(
        name: "Apple TV 4K",
        state: "Booted",
        udid: "tv-device-1",
        deviceTypeIdentifier: "type-3",
      ),
    ]

    let simulatorList = SimulatorList([
      "com.apple.CoreSimulator.SimRuntime.iOS-26-2": iOSDevices,
      "com.apple.CoreSimulator.SimRuntime.watchOS-26-2": watchOSDevices,
      "com.apple.CoreSimulator.SimRuntime.tvOS-26-2": tvOSDevices,
    ])

    let result = simulatorList.toRuntimeDeviceGroupOptions()
    #expect(result == [
      RuntimeDeviceGroupOption(
        runtime: "iOS 26.2",
        devices: iOSDevices,
      ),
      RuntimeDeviceGroupOption(
        runtime: "tvOS 26.2",
        devices: tvOSDevices,
      ),
      RuntimeDeviceGroupOption(
        runtime: "watchOS 26.2",
        devices: watchOSDevices,
      ),
    ])
  }

  @Test
  func toRuntimeDeviceGroupOptions_shouldSortRuntimesAlphabetically() {
    let device = Device(name: "iPhone 16", state: "Booted", udid: "device-1", deviceTypeIdentifier: "type-1")
    let simulatorList = SimulatorList([
      "com.apple.CoreSimulator.SimRuntime.watchOS-26-2": [device],
      "com.apple.CoreSimulator.SimRuntime.iOS-26-2": [device],
      "com.apple.CoreSimulator.SimRuntime.tvOS-26-2": [device],
      "com.apple.CoreSimulator.SimRuntime.iOS-18-6": [device],
    ])

    let result = simulatorList.toRuntimeDeviceGroupOptions()
    #expect(result.map(\.runtime) == [
      "iOS 18.6",
      "iOS 26.2",
      "tvOS 26.2",
      "watchOS 26.2",
    ])
  }

  @Test
  func toRuntimeDeviceGroupOptions_shouldSortDevicesByNameWithinEachRuntime() {
    let devices = [
      Device(
        name: "iPhone 16 Pro Max",
        state: "Booted",
        udid: "device-3",
        deviceTypeIdentifier: "type-3",
      ),
      Device(
        name: "iPhone 16",
        state: "Shutdown",
        udid: "device-1",
        deviceTypeIdentifier: "type-1",
      ),
      Device(
        name: "iPhone 16 Pro",
        state: "Booted",
        udid: "device-2",
        deviceTypeIdentifier: "type-2",
      ),
    ]
    let simulatorList = SimulatorList([
      "com.apple.CoreSimulator.SimRuntime.iOS-18-4": devices,
    ])

    let result = simulatorList.toRuntimeDeviceGroupOptions()
    #expect(result == [
      RuntimeDeviceGroupOption(
        runtime: "iOS 18.4",
        devices: [
          devices[1], // iPhone 16
          devices[2], // iPhone 16 Pro
          devices[0], // iPhone 16 Pro Max
        ],
      ),
    ])
  }

  @Test
  func toRuntimeDeviceGroupOptions_shouldReturnEmptyArrayWhenDevicesIsEmpty() {
    let simulatorList = SimulatorList([:])
    let result = simulatorList.toRuntimeDeviceGroupOptions()
    #expect(result.isEmpty)
  }

  // MARK: - toRuntimeDeviceGroupOptions with empty runtimes tests

  @Test
  func toRuntimeDeviceGroupOptions_shouldExcludeEmptyRuntimesFromResult() {
    let devices = [
      Device(
        name: "iPhone 16",
        state: "Booted",
        udid: "device-1",
        deviceTypeIdentifier: "type-1",
      ),
    ]
    let simulatorList = SimulatorList([
      "com.apple.CoreSimulator.SimRuntime.iOS-26-2": devices,
      "com.apple.CoreSimulator.SimRuntime.watchOS-26-2": [],
      "com.apple.CoreSimulator.SimRuntime.tvOS-26-2": [],
    ])

    let result = simulatorList.toRuntimeDeviceGroupOptions()
    #expect(result == [
      RuntimeDeviceGroupOption(
        runtime: "iOS 26.2",
        devices: devices,
      ),
    ])
  }

  @Test
  func toRuntimeDeviceGroupOptions_shouldKeepAllRuntimesWithDevices() {
    let iOSDevices = [
      Device(
        name: "iPhone 16",
        state: "Booted",
        udid: "ios-device-1",
        deviceTypeIdentifier: "type-1",
      ),
    ]
    let watchOSDevices = [
      Device(
        name: "Apple Watch Series 10",
        state: "Shutdown",
        udid: "watch-device-1",
        deviceTypeIdentifier: "type-2",
      ),
    ]
    let simulatorList = SimulatorList([
      "com.apple.CoreSimulator.SimRuntime.iOS-26-2": iOSDevices,
      "com.apple.CoreSimulator.SimRuntime.watchOS-26-2": watchOSDevices,
      "com.apple.CoreSimulator.SimRuntime.tvOS-26-2": [],
    ])

    let result = simulatorList.toRuntimeDeviceGroupOptions()
    #expect(result == [
      RuntimeDeviceGroupOption(
        runtime: "iOS 26.2",
        devices: iOSDevices,
      ),
      RuntimeDeviceGroupOption(
        runtime: "watchOS 26.2",
        devices: watchOSDevices,
      ),
    ])
  }

  @Test
  func toRuntimeDeviceGroupOptions_shouldReturnEmptyArrayWhenAllRuntimesAreEmpty() {
    let simulatorList = SimulatorList([
      "com.apple.CoreSimulator.SimRuntime.iOS-26-2": [],
      "com.apple.CoreSimulator.SimRuntime.watchOS-26-2": [],
    ])

    let result = simulatorList.toRuntimeDeviceGroupOptions()
    #expect(result.isEmpty)
  }

  // MARK: - toRuntimeDeviceGroupOptions with filteringBy tests

  @Test
  func toRuntimeDeviceGroupOptions_shouldFilterDevicesByStateWhenFilteringByIsProvided() {
    // Given: A SimulatorList with a runtime containing both booted and shutdown devices
    let bootedDevice = Device(name: "iPhone 16", state: "Booted", udid: "device-1", deviceTypeIdentifier: "type-1")
    let shutdownDevice = Device(name: "iPhone 15", state: "Shutdown", udid: "device-2", deviceTypeIdentifier: "type-2")
    let simulatorList = SimulatorList([
      "com.apple.CoreSimulator.SimRuntime.iOS-26-2": [bootedDevice, shutdownDevice],
    ])

    // When: Converting with filteringBy .booted
    let result = simulatorList.toRuntimeDeviceGroupOptions(filteringBy: .booted)

    // Then: Only the booted device should be included
    #expect(result == [
      RuntimeDeviceGroupOption(runtime: "iOS 26.2", devices: [bootedDevice]),
    ])
  }

  @Test
  func toRuntimeDeviceGroupOptions_shouldExcludeRuntimesWithNoMatchingDevicesWhenFilteringByIsProvided() {
    // Given: Multiple runtimes, only one has a device matching the filter state
    let bootedDevice = Device(name: "iPhone 16", state: "Booted", udid: "ios-device-1", deviceTypeIdentifier: "type-1")
    let shutdownDevice = Device(name: "Apple Watch Series 10", state: "Shutdown", udid: "watch-device-1", deviceTypeIdentifier: "type-2")
    let simulatorList = SimulatorList([
      "com.apple.CoreSimulator.SimRuntime.iOS-26-2": [bootedDevice],
      "com.apple.CoreSimulator.SimRuntime.watchOS-26-2": [shutdownDevice],
    ])

    // When: Converting with filteringBy .booted
    let result = simulatorList.toRuntimeDeviceGroupOptions(filteringBy: .booted)

    // Then: Only the runtime with matching devices should be included
    #expect(result == [
      RuntimeDeviceGroupOption(runtime: "iOS 26.2", devices: [bootedDevice]),
    ])
  }

  @Test
  func toRuntimeDeviceGroupOptions_shouldReturnEmptyWhenNoDevicesMatchFilteringByState() {
    // Given: A SimulatorList where no devices match the requested state
    let simulatorList = SimulatorList([
      "com.apple.CoreSimulator.SimRuntime.iOS-26-2": [
        Device(name: "iPhone 16", state: "Shutdown", udid: "device-1", deviceTypeIdentifier: "type-1"),
      ],
    ])

    // When: Converting with filteringBy .booted
    let result = simulatorList.toRuntimeDeviceGroupOptions(filteringBy: .booted)

    // Then: Result should be empty
    #expect(result.isEmpty)
  }
}
