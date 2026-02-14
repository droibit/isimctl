import Foundation
import Subprocess
import Testing
@testable import SimctlKit
@testable import SimctlKitMocks
@testable import SubprocessKit
@testable import SubprocessKitMocks

struct SimctlTests {
  private let runner: CommandRunnableMock
  private let simctl: Simctl

  init() {
    runner = CommandRunnableMock()
    simctl = Simctl(runner: runner)
  }

  @Test
  func listDevices_shouldThrowXcrunNotFoundWhenXcrunIsNotAvailable() async throws {
    runner.isExecutableAvailableHandler = { _ in false }

    let expectedError = SimctlError.xcrunNotFound
    await #expect(throws: expectedError) {
      try await simctl.listDevices(searchTerm: nil)
    }
    #expect(runner.runForOutputCallCount == 0)
  }

  @Test
  func listDevices_shouldThrowCommandFailedWhenXcrunReturnsError() async throws {
    runner.isExecutableAvailableHandler = { _ in true }
    runner.runForOutputHandler = { _, _ in
      throw CommandExecutionError(
        command: "xcrun simctl list devices",
        description: "Unknown error",
      )
    }

    let expectedError = SimctlError.commandFailed(
      command: "xcrun simctl list devices",
      description: "Unknown error",
    )
    await #expect(throws: expectedError) {
      try await simctl.listDevices(searchTerm: nil)
    }
    #expect(runner.runForOutputCallCount == 1)
  }

  @Test
  func listDevices_shouldCallXcrunWithSearchTermWhenProvided() async throws {
    runner.isExecutableAvailableHandler = { _ in true }
    runner.runForOutputHandler = { _, _ in
      """
      {
        "devices": {}
      }
      """
    }

    _ = try await simctl.listDevices(searchTerm: .booted)
    #expect(runner.runForOutputArgValues.count == 1)
    #expect(runner.runForOutputArgValues[0].executable == Executable.name("xcrun"))
    #expect(runner.runForOutputArgValues[0].arguments == Arguments(["simctl", "list", "devices", "booted", "--json"]))
  }

  @Test
  func listDevices_shouldCallXcrunWithCorrectArgumentsWhenNoSearchTerm() async throws {
    runner.isExecutableAvailableHandler = { _ in true }
    runner.runForOutputHandler = { _, _ in
      """
      {
        "devices": {}
      }
      """
    }

    _ = try await simctl.listDevices(searchTerm: nil)
    #expect(runner.runForOutputArgValues.count == 1)
    #expect(runner.runForOutputArgValues[0].executable == Executable.name("xcrun"))
    #expect(runner.runForOutputArgValues[0].arguments == Arguments(["simctl", "list", "devices", "--json"]))
  }

  @Test
  func listDevices_shouldThrowInvalidOutputWhenJSONIsInvalid() async throws {
    runner.isExecutableAvailableHandler = { _ in true }
    runner.runForOutputHandler = { _, _ in "invalid json" }

    await #expect {
      try await simctl.listDevices(searchTerm: nil)
    } throws: { error in
      guard case let .invalidOutput(summary, description) = error as? SimctlError else {
        return false
      }
      return summary == "Failed to parse device information." && !description.isEmpty
    }
    #expect(runner.runForOutputCallCount == 1)
  }

  @Test
  func listDevices_shouldReturnValidSimulatorListWhenJSONIsValid() async throws {
    runner.isExecutableAvailableHandler = { _ in true }
    runner.runForOutputHandler = { _, _ in
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
    runner.isExecutableAvailableHandler = { _ in true }
    runner.runForOutputHandler = { _, _ in
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
    runner.isExecutableAvailableHandler = { _ in true }
    runner.executeHandler = { _, _ in }

    // When: Boot a device
    try await simctl.bootDevice(udid: "test-udid-123")

    // Then: Verify runner was called with correct arguments
    #expect(runner.executeArgValues.count == 1)
    #expect(runner.executeArgValues[0].executable == Executable.name("xcrun"))
    #expect(runner.executeArgValues[0].arguments == Arguments(["simctl", "boot", "test-udid-123"]))
  }

  @Test
  func bootDevice_shouldThrowXcrunNotFoundWhenXcrunIsNotAvailable() async throws {
    // Given: xcrun is not available
    runner.isExecutableAvailableHandler = { _ in false }

    // When/Then: Expect xcrunNotFound error
    let expectedError = SimctlError.xcrunNotFound
    await #expect(throws: expectedError) {
      try await simctl.bootDevice(udid: "test-udid")
    }

    // Then: Verify runner.execute was not called
    #expect(runner.executeCallCount == 0)
  }

  @Test
  func bootDevice_shouldThrowCommandFailedWhenXcrunThrowsError() async throws {
    // Given: runner throws an error (e.g., device already booted or invalid UUID)
    runner.isExecutableAvailableHandler = { _ in true }
    runner.executeHandler = { _, _ in
      throw CommandExecutionError(
        command: "xcrun simctl boot test-udid",
        description: "Unable to boot device in current state: Booted",
      )
    }

    // When/Then: Expect commandFailed error
    let expectedError = SimctlError.commandFailed(
      command: "xcrun simctl boot test-udid",
      description: "Unable to boot device in current state: Booted",
    )
    await #expect(throws: expectedError) {
      try await simctl.bootDevice(udid: "test-udid")
    }

    // Then: Verify runner.execute was called once
    #expect(runner.executeCallCount == 1)
  }
}
