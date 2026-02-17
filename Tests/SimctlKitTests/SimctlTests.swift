import Foundation
import Testing
@testable import SimctlKit
@testable import SimctlKitMocks
@testable import SubprocessKit
@testable import SubprocessKitMocks

struct SimctlTests {
  private let xcrun: ExecutingMock
  private let simctl: Simctl

  init() {
    xcrun = ExecutingMock()
    simctl = Simctl(xcrun: xcrun)
  }

  @Test
  func listDevices_shouldThrowXcrunNotFoundWhenXcrunIsNotAvailable() async throws {
    xcrun.isExecutableAvailableHandler = { false }

    let expectedError = SimctlError.xcrunNotFound
    await #expect(throws: expectedError) {
      try await simctl.listDevices(searchTerm: nil)
    }
    #expect(xcrun.captureOutputCallCount == 0)
  }

  @Test
  func listDevices_shouldThrowCommandFailedWhenXcrunReturnsError() async throws {
    xcrun.isExecutableAvailableHandler = { true }

    let runError = ExecutionError(
      command: "xcrun simctl list devices",
      description: "Unknown error",
    )
    xcrun.captureOutputHandler = { _ in
      throw runError
    }

    let expectedError = SimctlError.commandFailed(error: runError)
    await #expect(throws: expectedError) {
      try await simctl.listDevices(searchTerm: nil)
    }
    #expect(xcrun.captureOutputCallCount == 1)
  }

  @Test
  func listDevices_shouldCallXcrunWithSearchTermWhenProvided() async throws {
    xcrun.isExecutableAvailableHandler = { true }
    xcrun.captureOutputHandler = { _ in
      """
      {
        "devices": {}
      }
      """
    }

    _ = try await simctl.listDevices(searchTerm: .booted)
    #expect(xcrun.captureOutputArgValues == [["simctl", "list", "devices", "booted", "--json"]])
  }

  @Test
  func listDevices_shouldCallXcrunWithCorrectArgumentsWhenNoSearchTerm() async throws {
    xcrun.isExecutableAvailableHandler = { true }
    xcrun.captureOutputHandler = { _ in
      """
      {
        "devices": {}
      }
      """
    }

    _ = try await simctl.listDevices(searchTerm: nil)
    #expect(xcrun.captureOutputArgValues == [["simctl", "list", "devices", "--json"]])
  }

  @Test
  func listDevices_shouldThrowInvalidOutputWhenJSONIsInvalid() async throws {
    xcrun.isExecutableAvailableHandler = { true }
    xcrun.captureOutputHandler = { _ in "invalid json" }

    await #expect {
      try await simctl.listDevices(searchTerm: nil)
    } throws: { error in
      guard case let .invalidOutput(summary, description) = error as? SimctlError else {
        return false
      }
      return summary == "Failed to parse device information." && !description.isEmpty
    }
    #expect(xcrun.captureOutputCallCount == 1)
  }

  @Test
  func listDevices_shouldReturnValidSimulatorListWhenJSONIsValid() async throws {
    xcrun.isExecutableAvailableHandler = { true }
    xcrun.captureOutputHandler = { _ in
      """
      {
        "devices": {
          "com.apple.CoreSimulator.SimRuntime.iOS-18-0": [
            {
              "state": "Booted",
              "isAvailable": true,
              "name": "iPhone 16",
              "udid": "udid-1",
              "deviceTypeIdentifier": "com.apple.CoreSimulator.DeviceType.iPhone-16"
            }
          ],
          "com.apple.CoreSimulator.SimRuntime.iOS-17-0": [
            {
              "state": "Shutdown",
              "isAvailable": true,
              "name": "iPhone 15",
              "udid": "udid-2",
              "deviceTypeIdentifier": "com.apple.CoreSimulator.DeviceType.iPhone-15"
            }
          ]
        }
      }
      """
    }

    let result = try await simctl.listDevices(searchTerm: nil)
    #expect(result == SimulatorList([
      "com.apple.CoreSimulator.SimRuntime.iOS-18-0": [
        Device(
          name: "iPhone 16",
          state: "Booted",
          udid: "udid-1",
          deviceTypeIdentifier: "com.apple.CoreSimulator.DeviceType.iPhone-16",
        ),
      ],
      "com.apple.CoreSimulator.SimRuntime.iOS-17-0": [
        Device(
          name: "iPhone 15",
          state: "Shutdown",
          udid: "udid-2",
          deviceTypeIdentifier: "com.apple.CoreSimulator.DeviceType.iPhone-15",
        ),
      ],
    ]))
  }

  @Test
  func listDevices_shouldReturnEmptyDevicesWhenNoDevicesAvailable() async throws {
    xcrun.isExecutableAvailableHandler = { true }
    xcrun.captureOutputHandler = { _ in
      """
      {
        "devices": {}
      }
      """
    }

    let result = try await simctl.listDevices(searchTerm: nil)
    #expect(result.devices.isEmpty)
  }

  // MARK: - bootDevice

  @Test
  func bootDevice_shouldCallXcrunWithCorrectArguments() async throws {
    // Given: Mock runner to return successfully
    xcrun.isExecutableAvailableHandler = { true }
    xcrun.executeHandler = { _ in }

    // When: Boot a device
    try await simctl.bootDevice(udid: "test-udid-123")

    // Then: Verify runner was called with correct arguments
    #expect(xcrun.executeArgValues == [["simctl", "boot", "test-udid-123"]])
  }

  @Test
  func bootDevice_shouldThrowXcrunNotFoundWhenXcrunIsNotAvailable() async throws {
    // Given: xcrun is not available
    xcrun.isExecutableAvailableHandler = { false }

    // When/Then: Expect xcrunNotFound error
    let expectedError = SimctlError.xcrunNotFound
    await #expect(throws: expectedError) {
      try await simctl.bootDevice(udid: "test-udid")
    }

    // Then: Verify runner.execute was not called
    #expect(xcrun.executeCallCount == 0)
  }

  @Test
  func bootDevice_shouldThrowCommandFailedWhenXcrunThrowsError() async throws {
    // Given: runner throws an error (e.g., device already booted or invalid UUID)
    xcrun.isExecutableAvailableHandler = { true }

    let runError = ExecutionError(
      command: "xcrun simctl boot test-udid",
      description: "Unable to boot device in current state: Booted",
    )
    xcrun.executeHandler = { _ in
      throw runError
    }

    // When/Then: Expect commandFailed error
    let expectedError = SimctlError.commandFailed(error: runError)
    await #expect(throws: expectedError) {
      try await simctl.bootDevice(udid: "test-udid")
    }

    // Then: Verify runner.execute was called once
    #expect(xcrun.executeCallCount == 1)
  }
}
