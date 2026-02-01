import SimctlKit
import Testing
@testable import IsimctlUI

struct RuntimeDeviceGroupOptionTests {
  // MARK: - formatRuntime tests

  @Test(arguments: [
    ("com.apple.CoreSimulator.SimRuntime.watchOS-26-2", "watchOS 26.2"),
    ("com.apple.CoreSimulator.SimRuntime.iOS-26-2", "iOS 26.2"),
    ("com.apple.CoreSimulator.SimRuntime.tvOS-26-2", "tvOS 26.2"),
    ("com.apple.CoreSimulator.SimRuntime.iOS-18-6", "iOS 18.6"),
    ("iOS-26-2", "iOS 26.2"),
    ("com.apple.CoreSimulator.SimRuntime.iOS", "iOS"),
    ("iOS", "iOS"),
    ("", ""),
  ])
  func formatRuntime_shouldFormatRuntimeIdentifierCorrectly(
    input: String,
    expected: String,
  ) {
    let result = RuntimeDeviceGroupOption.formatRuntime(input)
    #expect(result == expected)
  }

  // MARK: - description tests

  @Test(arguments: [
    ("iOS 26.2", []),
    ("watchOS 26.2", [
      Device(
        name: "iPhone",
        state: "Booted",
        udid: "test-udid",
        deviceTypeIdentifier: "test-device-type",
      ),
    ]),
  ])
  func description_shouldReturnRuntimeValue(runtime: String, devices: [Device]) {
    let runtimeOption = RuntimeDeviceGroupOption(
      runtime: runtime,
      devices: devices,
    )
    #expect(runtimeOption.description == runtime)
  }
}
