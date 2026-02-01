import Foundation
import System
import Testing
@testable import SimctlKit
@testable import SimctlKitMocks
@testable import Subprocess

struct XcrunTests {
  typealias CollectedResult = SubprocessRunnable.CollectedResult

  private let runner: SubprocessRunnableMock
  private let xcrun: Xcrun

  init() {
    runner = SubprocessRunnableMock()
    xcrun = Xcrun(runner: runner)
  }

  @Test
  func isAvailable_shouldReturnTrueWhenExecutableExists() {
    runner.isExecutableAvailableHandler = { _ in true }

    let result = xcrun.isAvailable()
    #expect(result == true)
  }

  @Test
  func isAvailable_shouldReturnFalseWhenExecutableNotFound() {
    runner.isExecutableAvailableHandler = { _ in false }

    let result = xcrun.isAvailable()
    #expect(result == false)
  }

  @Test
  func run_shouldThrowXcrunErrorWhenCommandFails() async throws {
    runner.runHandler = { _, _, _, _ in
      CollectedResult(
        processIdentifier: .init(value: 0),
        terminationStatus: .exited(1),
        standardOutput: nil,
        standardError: "Command not found",
      )
    }

    let expectedError = XcrunError(
      command: "xcrun simctl list unknown",
      description: "Command not found",
    )
    await #expect(throws: expectedError) {
      try await xcrun.run(arguments: ["simctl", "list", "unknown"])
    }
  }

  @Test
  func run_shouldThrowXcrunErrorWhenSubprocessRunnerThrowsError() async throws {
    struct TestError: Equatable, LocalizedError {
      var errorDescription: String? {
        "Test error occurred"
      }
    }
    runner.runHandler = { _, _, _, _ in
      throw TestError()
    }

    let expectedError = XcrunError(
      command: "xcrun simctl list devices",
      description: "Test error occurred",
    )
    await #expect(throws: expectedError) {
      try await xcrun.run(arguments: ["simctl", "list", "devices"])
    }
  }

  @Test
  func run_shouldThrowXcrunErrorWhenCommandFailsWithStandardOutput() async throws {
    runner.runHandler = { _, _, _, _ in
      CollectedResult(
        processIdentifier: .init(value: 0),
        terminationStatus: .exited(1),
        standardOutput: "Error message in stdout",
        standardError: nil,
      )
    }

    let expectedError = XcrunError(
      command: "xcrun simctl list devices",
      description: "Error message in stdout",
    )
    await #expect(throws: expectedError) {
      try await xcrun.run(arguments: ["simctl", "list", "devices"])
    }
  }

  @Test
  func run_shouldThrowXcrunErrorWhenCommandFailsWithoutAnyOutput() async throws {
    runner.runHandler = { _, _, _, _ in
      CollectedResult(
        processIdentifier: .init(value: 0),
        terminationStatus: .exited(1),
        standardOutput: nil,
        standardError: nil,
      )
    }

    let expectedError = XcrunError(
      command: "xcrun simctl list runtimes",
      description: TerminationStatus.exited(1).description,
    )
    await #expect(throws: expectedError) {
      try await xcrun.run(arguments: ["simctl", "list", "runtimes"])
    }
  }

  @Test(arguments: [nil as String?, ""])
  func run_shouldThrowXcrunErrorWhenNoOutputProvided(output: String?) async throws {
    runner.runHandler = { _, _, _, _ in
      CollectedResult(
        processIdentifier: .init(value: 0),
        terminationStatus: .exited(0),
        standardOutput: output,
        standardError: nil,
      )
    }

    let expectedError = XcrunError(
      command: "xcrun simctl list devices",
      description: "No output received from command.",
    )
    await #expect(throws: expectedError) {
      try await xcrun.run(arguments: ["simctl", "list", "devices"])
    }
  }

  @Test
  func run_shouldReturnOutputWhenCommandSucceeds() async throws {
    let expectedOutput = "test output"
    runner.runHandler = { _, _, _, _ in
      CollectedResult(
        processIdentifier: .init(value: 0),
        terminationStatus: .exited(0),
        standardOutput: expectedOutput,
        standardError: nil,
      )
    }

    let result = try await xcrun.run(arguments: ["simctl", "list", "devices"])
    #expect(result == expectedOutput)
    #expect(runner.runCallCount == 1)
  }

  @Test
  func run_shouldThrowCancellationErrorWhenTaskIsCancelled() async throws {
    runner.runHandler = { _, _, _, _ in
      throw CancellationError()
    }

    await #expect(throws: CancellationError.self) {
      try await xcrun.run(arguments: ["simctl", "list", "devices"])
    }
  }
}

extension XcrunError: Equatable {
  static func == (lhs: XcrunError, rhs: XcrunError) -> Bool {
    lhs.command == rhs.command && lhs.description == rhs.description
  }
}
