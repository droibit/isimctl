public import Foundation
import SubprocessKit

/// Error types that can occur when executing `xcrun simctl` commands
public enum SimctlError: Equatable, LocalizedError {
  /// Indicates that the `xcrun` command is not available
  case xcrunNotFound
  /// Indicates that a command execution failed
  case commandFailed(command: String, description: String)
  /// Indicates that the output from a command was invalid or could not be parsed
  case invalidOutput(summary: String, description: String)

  public var errorDescription: String {
    switch self {
    case .xcrunNotFound:
      "xcrun command not found. Please ensure Xcode is installed."
    case let .commandFailed(command, description):
      "Command failed: \(command)\n\(description)"
    case let .invalidOutput(summary, description):
      "\(summary)\n\(description)"
    }
  }
}

extension SimctlError {
  /// Creates a `commandFailed` error from an `ExecutionError`
  ///
  /// This convenience method converts a low-level subprocess execution error into a simctl-specific error,
  /// making it easy to propagate command failures from the SubprocessKit layer to the SimctlKit API.
  ///
  /// - Parameter error: The ``ExecutionError`` that occurred during command execution
  /// - Returns: A `SimctlError/commandFailed(command:description:)` case containing the command and error description
  ///
  /// ## Example
  ///
  /// ```swift
  /// do {
  ///   try await xcrun.execute(arguments: arguments)
  /// } catch let error as ExecutionError {
  ///   throw SimctlError.commandFailed(error: error)
  /// }
  /// ```
  static func commandFailed(error: ExecutionError) -> Self {
    .commandFailed(command: error.command, description: error.description)
  }
}
