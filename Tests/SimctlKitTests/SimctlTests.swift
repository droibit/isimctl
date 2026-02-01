import Foundation
import Testing
@testable import SimctlKit
@testable import SimctlKitMocks

struct SimctlTests {
  private let xcrun: XcrunnableMock
  private let simctl: Simctl

  init() {
    xcrun = XcrunnableMock()
    simctl = Simctl(xcrun: xcrun)
  }

  @Test
  func listDevices_shouldThrowXcrunNotFoundWhenXcrunIsNotAvailable() async throws {
    xcrun.isAvailableHandler = { false }

    let expectedError = SimctlError.xcrunNotFound
    await #expect(throws: expectedError) {
      try await simctl.listDevices(searchTerm: nil)
    }
    #expect(xcrun.runCallCount == 0)
  }

  @Test
  func listDevices_shouldThrowCommandFailedWhenXcrunReturnsError() async throws {
    xcrun.isAvailableHandler = { true }
    xcrun.runHandler = { _ in
      throw XcrunError(
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
    #expect(xcrun.runCallCount == 1)
  }

  @Test
  func listDevices_shouldCallXcrunWithSearchTermWhenProvided() async throws {
    xcrun.isAvailableHandler = { true }
    xcrun.runHandler = { _ in
      """
      {
        "devices": {}
      }
      """
    }

    _ = try await simctl.listDevices(searchTerm: "booted")
    #expect(xcrun.runArgValues == [["simctl", "list", "devices", "booted", "--json"]])
  }

  @Test(arguments: [nil as String?, ""])
  func listDevices_shouldCallXcrunWithCorrectArgumentsWhenNoSearchTerm(searchTerm: String?) async throws {
    xcrun.isAvailableHandler = { true }
    xcrun.runHandler = { _ in
      """
      {
        "devices": {}
      }
      """
    }

    _ = try await simctl.listDevices(searchTerm: searchTerm)
    #expect(xcrun.runArgValues == [["simctl", "list", "devices", "--json"]])
  }

  @Test
  func listDevices_shouldThrowInvalidOutputWhenJSONIsInvalid() async throws {
    xcrun.isAvailableHandler = { true }
    xcrun.runHandler = { _ in "invalid json" }

    let expectedError = SimctlError.invalidOutput(
      summary: "Failed to parse device information.",
      description: "The data couldn’t be read because it isn’t in the correct format.",
    )
    await #expect(throws: expectedError) {
      try await simctl.listDevices(searchTerm: nil)
    }
    #expect(xcrun.runCallCount == 1)
  }

  @Test
  func listDevices_shouldReturnValidSimulatorListWhenJSONIsValid() async throws {
    xcrun.isAvailableHandler = { true }
    xcrun.runHandler = { _ in
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
    xcrun.isAvailableHandler = { true }
    xcrun.runHandler = { _ in
      """
      {
        "devices": {}
      }
      """
    }

    let result = try await simctl.listDevices(searchTerm: nil)
    #expect(result.devices.isEmpty)
  }
}

extension SimctlError: Equatable {
  static func == (lhs: SimctlError, rhs: SimctlError) -> Bool {
    switch (lhs, rhs) {
    case (.xcrunNotFound, .xcrunNotFound):
      true
    case let (.commandFailed(lhsCommand, lhsDescription), .commandFailed(rhsCommand, rhsDescription)):
      lhsCommand == rhsCommand && lhsDescription == rhsDescription
    case let (.invalidOutput(lhsSummary, lhsDescription), .invalidOutput(rhsSummary, rhsDescription)):
      lhsSummary == rhsSummary && lhsDescription == rhsDescription
    default:
      false
    }
  }
}
