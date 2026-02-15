public import Subprocess
import Foundation

/// Protocol for executing command-line tools
/// @mockable
public protocol Executing: Sendable {
  /// Checks if an executable is available
  ///
  /// - Returns: `true` if executable is available, `false` otherwise
  func isExecutableAvailable() -> Bool

  /// Executes a command and returns its standard output
  ///
  /// This method runs a command-line tool and captures its standard output as a UTF-8 encoded string.
  /// Output is limited to 10MB to prevent memory issues with large outputs.
  ///
  /// - Parameter arguments: Arguments to pass to the executable
  /// - Returns: Standard output as a UTF-8 encoded String, or empty string if no output is produced
  /// - Throws:
  ///   - `ExecutionError` if command execution fails or returns a non-zero exit code
  ///   - `CancellationError` if the task is cancelled during execution
  func captureOutput(arguments: Arguments) async throws -> String

  /// Executes a command without capturing output
  ///
  /// This method runs a command-line tool and discards its standard output.
  /// Use this when you only care about whether the command succeeds, not its output.
  ///
  /// - Parameter arguments: Arguments to pass to the executable
  /// - Throws:
  ///   - `ExecutionError` if command execution fails or returns a non-zero exit code
  ///   - `CancellationError` if the task is cancelled during execution
  func execute(arguments: Arguments) async throws
}

/// Implementation of ``Executing`` using Subprocess
public struct Executor: Executing {
  private let executable: Executable

  public init(executable: Executable) {
    self.executable = executable
  }

  public func isExecutableAvailable() -> Bool {
    do {
      _ = try executable.resolveExecutablePath(in: .inherit)
      return true
    } catch {
      return false
    }
  }

  public func captureOutput(arguments: Arguments) async throws -> String {
    let result: CollectedResult<StringOutput<Unicode.UTF8>, StringOutput<Unicode.UTF8>>
    do {
      // Set reasonable limits: 10MB for output, 1MB for error messages
      // xcrun simctl output is typically < 1MB, but allow headroom for large device lists
      result = try await Subprocess.run(
        executable,
        arguments: arguments,
        output: .string(limit: 10 * 1024 * 1024),
        error: .string(limit: 1024 * 1024),
      )
    } catch {
      if error is CancellationError {
        throw error
      }
      throw ExecutionError(
        command: "\(executable) \(arguments)",
        description: error.localizedDescription,
      )
    }

    guard result.terminationStatus.isSuccess else {
      throw ExecutionError(command: "\(executable) \(arguments)", from: result)
    }
    return result.standardOutput ?? ""
  }

  public func execute(arguments: Arguments) async throws {
    let result: CollectedResult<DiscardedOutput, StringOutput<Unicode.UTF8>>
    do {
      result = try await Subprocess.run(
        executable,
        arguments: arguments,
        output: .discarded,
        error: .string(limit: 1024 * 1024),
      )
    } catch {
      if error is CancellationError {
        throw error
      }
      throw ExecutionError(
        command: "\(executable) \(arguments)",
        description: error.localizedDescription,
      )
    }

    if !result.terminationStatus.isSuccess {
      throw ExecutionError(command: "\(executable) \(arguments)", from: result)
    }
  }
}
