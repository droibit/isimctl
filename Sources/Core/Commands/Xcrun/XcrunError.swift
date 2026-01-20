public import Foundation

/// Error types that can occur when executing xcrun commands
public enum XcrunError: LocalizedError, Sendable {
  case xcrunNotFound
  case commandFailed(String)
  case invalidOutput(String)
  
  public var errorDescription: String? {
    switch self {
    case .xcrunNotFound:
      "xcrun command not found. Please ensure Xcode is installed."
    case let .commandFailed(message):
      message
    case let .invalidOutput(message):
      message
    }
  }
}
