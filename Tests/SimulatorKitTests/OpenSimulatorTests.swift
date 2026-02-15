import Foundation
import Subprocess
import Testing
@testable import SimulatorKit
@testable import SimulatorKitMocks
@testable import SubprocessKit
@testable import SubprocessKitMocks

struct OpenSimulatorTests {
  private let open: ExecutingMock
  private let openSimulator: OpenSimulator

  init() {
    open = ExecutingMock()
    openSimulator = OpenSimulator(open: open)
  }

  // MARK: - Normal Cases

  @Test
  func open_shouldCallRunnerExecuteWithCorrectArgumentsWhenUdidIsNil() async throws {
    // Given: Mock runner to execute successfully
    open.executeHandler = { _ in }

    // When: Open Simulator.app without a specific device
    try await openSimulator.open(udid: nil)

    // Then: Verify runner was called with correct arguments
    #expect(open.executeArgValues == [Arguments(["-a", "\"Simulator\""])])
  }

  @Test
  func open_shouldCallRunnerExecuteWithCorrectArgumentsWhenUdidIsProvided() async throws {
    // Given: Mock runner to execute successfully
    open.executeHandler = { _ in }

    // When: Open Simulator.app with a specific device UDID
    try await openSimulator.open(udid: "test-udid-123")

    // Then: Verify runner was called with correct arguments
    #expect(open.executeArgValues == [Arguments(["-a", "\"Simulator\"", "--args", "-CurrentDeviceUDID", "test-udid-123"])])
  }

  // MARK: - Error Handling

  @Test
  func open_shouldThrowOpenSimulatorErrorWhenRunnerThrowsExecutionError() async throws {
    // Given: Runner throws ExecutionError
    open.executeHandler = { _ in
      throw ExecutionError(
        command: "open -a \"Simulator\"",
        description: "Application not found",
      )
    }

    // When/Then: Expect OpenSimulatorError to be thrown
    let expectedError = OpenSimulatorError(
      command: "open -a \"Simulator\"",
      description: "Application not found",
    )
    await #expect(throws: expectedError) {
      try await openSimulator.open(udid: nil)
    }

    // Then: Verify runner.execute was called once
    #expect(open.executeCallCount == 1)
  }
}
