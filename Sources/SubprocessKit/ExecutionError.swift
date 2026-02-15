public import Foundation
import Subprocess

/// Error thrown when command execution fails
///
/// This error is thrown when a command-line tool fails to execute or returns a non-zero exit code.
/// It captures both the command that failed and a description of the error, which may include
/// standard error output or the underlying system error message.
///
/// ## Example
///
/// ```swift
/// do {
///   try await executor.execute(arguments: [])
/// } catch let error as ExecutionError {
///   print(error.command)      // "false"
///   print(error.description)  // Exit status details
/// }
/// ```
public struct ExecutionError: Equatable, LocalizedError {
  /// The command that failed, including the executable and arguments
  ///
  /// This string representation helps identify which command caused the error.
  /// Format: `"<executable> <arguments>"`
  public let command: String

  /// Description of the error
  ///
  /// This may contain:
  /// - Standard error output from the command
  /// - Exit status information (e.g., "exited with code 1")
  /// - System error messages (e.g., "No such file or directory")
  public let description: String

  /// Creates a new command execution error
  ///
  /// - Parameters:
  ///   - command: The command that failed (executable and arguments)
  ///   - description: Description of why the command failed
  public init(command: String, description: String) {
    self.command = command
    self.description = description
  }

  public var errorDescription: String? {
    "Command failed: \(command)\n\(description)"
  }
}

extension ExecutionError {
  init(
    command: String,
    from result: CollectedResult<StringOutput<Unicode.UTF8>, StringOutput<Unicode.UTF8>>,
  ) {
    let description = result.standardError ?? result.standardOutput ?? result.terminationStatus.description
    self.init(command: command, description: description)
  }

  init(
    command: String,
    from result: CollectedResult<DiscardedOutput, StringOutput<Unicode.UTF8>>,
  ) {
    let description = result.standardError ?? result.terminationStatus.description
    self.init(command: command, description: description)
  }
}
