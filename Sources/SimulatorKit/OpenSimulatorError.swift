public import Foundation

/// Error thrown when opening Simulator.app fails
public struct OpenSimulatorError: LocalizedError, Sendable {
  /// The command that failed
  public let command: String

  /// Description of the error
  public let description: String

  public init(command: String, description: String) {
    self.command = command
    self.description = description
  }

  public var errorDescription: String? {
    "Failed to execute '\(command)': \(description)"
  }
}
