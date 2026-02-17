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
///   try await executor.execute([])
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
  init(command: String, description: String) {
    self.command = command
    self.description = description
  }

  public var errorDescription: String? {
    "Command failed: \(command)\n\(description)"
  }
}

extension ExecutionError {
  /// Represents a command invocation with an executable and arguments
  struct Invocation: Sendable, Equatable {
    let executable: String
    let arguments: [String]

    /// Command string representation
    var description: String {
      "\(executable) \(arguments.joined(separator: " "))"
    }
  }

  /// Creates a new command execution error from a command invocation
  init(command: Invocation, description: String) {
    self.init(command: command.description, description: description)
  }

  /// Creates a new command execution error from a command invocation and a subprocess result with string output
  init(
    command: Invocation,
    result: CollectedResult<StringOutput<Unicode.UTF8>, StringOutput<Unicode.UTF8>>,
  ) {
    let description = result.standardError ?? result.standardOutput ?? result.terminationStatus.description
    self.init(command: command.description, description: description)
  }

  /// Creates a new command execution error from a command invocation and a subprocess result with discarded output
  init(
    command: Invocation,
    result: CollectedResult<DiscardedOutput, StringOutput<Unicode.UTF8>>,
  ) {
    let description = result.standardError ?? result.terminationStatus.description
    self.init(command: command.description, description: description)
  }
}
