public import Subprocess
import Foundation

/// Protocol for executing command-line tools
/// @mockable
public protocol CommandRunnable: Sendable {
  /// Checks if an executable is available
  ///
  /// - Parameter executable: The executable to check
  /// - Returns: `true` if executable is available, `false` otherwise
  func isExecutableAvailable(_ executable: Executable) -> Bool

  /// Executes a command and returns its standard output
  ///
  /// This method runs a command-line tool and captures its standard output as a UTF-8 encoded string.
  /// Output is limited to 10MB to prevent memory issues with large outputs.
  ///
  /// - Parameters:
  ///   - executable: The executable to run (e.g., `Executable.path("/usr/bin/xcrun")` or `Executable.name("git")`)
  ///   - arguments: Arguments to pass to the executable
  /// - Returns: Standard output as a UTF-8 encoded String, or empty string if no output is produced
  /// - Throws:
  ///   - `CommandExecutionError` if command execution fails or returns a non-zero exit code
  ///   - `CancellationError` if the task is cancelled during execution
  func runForOutput(_ executable: Executable, arguments: Arguments) async throws -> String

  /// Executes a command without capturing output
  ///
  /// This method runs a command-line tool and discards its standard output.
  /// Use this when you only care about whether the command succeeds, not its output.
  ///
  /// - Parameters:
  ///   - executable: The executable to run (e.g., `Executable.path("/usr/bin/open")` or `Executable.name("make")`)
  ///   - arguments: Arguments to pass to the executable
  /// - Throws:
  ///   - `CommandExecutionError` if command execution fails or returns a non-zero exit code
  ///   - `CancellationError` if the task is cancelled during execution
  func execute(_ executable: Executable, arguments: Arguments) async throws
}

/// Implementation of ``CommandRunnable`` using Subprocess
public struct CommandRunner: CommandRunnable {
  public init() {}

  public func isExecutableAvailable(_ executable: Executable) -> Bool {
    do {
      _ = try executable.resolveExecutablePath(in: .inherit)
      return true
    } catch {
      return false
    }
  }

  public func runForOutput(_ executable: Executable, arguments: Arguments) async throws -> String {
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
      throw CommandExecutionError(
        command: "\(executable) \(arguments)",
        description: error.localizedDescription,
      )
    }

    guard result.terminationStatus.isSuccess else {
      throw CommandExecutionError(
        command: "\(executable) \(arguments)",
        description: result.standardError ?? result.standardOutput ?? result.terminationStatus.description,
      )
    }
    return result.standardOutput ?? ""
  }

  public func execute(_ executable: Executable, arguments: Arguments) async throws {
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
      throw CommandExecutionError(
        command: "\(executable) \(arguments)",
        description: error.localizedDescription,
      )
    }

    if !result.terminationStatus.isSuccess {
      throw CommandExecutionError(
        command: "\(executable) \(arguments)",
        description: result.standardError ?? result.terminationStatus.description,
      )
    }
  }
}
