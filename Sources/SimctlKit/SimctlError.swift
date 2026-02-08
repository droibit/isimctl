public import Foundation

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
