import Foundation
import Subprocess
import System

/// Protocol for executing `xcrun` commands
/// @mockable
protocol Xcrunnable: Sendable {
  /// Checks if `xcrun` command is available
  ///
  /// - Returns: `true` if xcrun is available, `false` otherwise
  func isAvailable() -> Bool

  /// Executes `xcrun` command with specified arguments
  ///
  /// - Parameter arguments: Arguments to pass to xcrun command
  /// - Returns: Standard output as a UTF-8 encoded String
  /// - Throws: ``XcrunError`` if command execution fails or output is invalid
  func run(arguments: [String]) async throws -> String
}

/// Executor for `xcrun` commands
struct Xcrun: Xcrunnable, Sendable {
  private let xcrun = Executable.path("/usr/bin/xcrun")
  private let runner: any SubprocessRunnable

  init(runner: any SubprocessRunnable = DefaultSubprocessRunner()) {
    self.runner = runner
  }

  func isAvailable() -> Bool {
    runner.isExecutableAvailable(xcrun)
  }

  func run(arguments: [String]) async throws -> String {
    let result: SubprocessRunnable.CollectedResult
    do {
      // Set reasonable limits: 10MB for output, 1MB for error messages
      // xcrun simctl output is typically < 1MB, but allow headroom for large device lists
      result = try await runner.run(
        xcrun,
        arguments: Arguments(arguments),
        output: .string(limit: 10 * 1024 * 1024),
        error: .string(limit: 1024 * 1024),
      )
    } catch {
      if error is CancellationError {
        throw error
      }
      throw XcrunError(
        command: makeCommand(from: arguments),
        description: error.localizedDescription,
      )
    }

    guard result.terminationStatus.isSuccess else {
      throw XcrunError(
        command: makeCommand(from: arguments),
        description: result.standardError ?? result.standardOutput ?? result.terminationStatus.description,
      )
    }

    guard let standardOutput = result.standardOutput, !standardOutput.isEmpty else {
      throw XcrunError(
        command: makeCommand(from: arguments),
        description: "No output received from command.",
      )
    }
    return standardOutput
  }

  private func makeCommand(from arguments: [String]) -> String {
    "xcrun " + arguments.joined(separator: " ")
  }
}

// MARK: - Error

/// Internal error type for xcrun command execution failures
struct XcrunError: LocalizedError, Sendable {
  let command: String
  let description: String

  var errorDescription: String {
    "Command failed: \(command)\n\(description)"
  }
}
