public import Foundation
import SubprocessKit

/// Error thrown when opening Simulator.app fails
public struct OpenSimulatorError: Equatable, LocalizedError, Sendable {
  /// The command that failed
  public let command: String

  /// Description of the error
  public let description: String

  /// Creates an `OpenSimulatorError` from a command and description
  ///
  /// - Parameters:
  ///   - command: The command that failed
  ///   - description: Description of why the command failed
  public init(command: String, description: String) {
    self.command = command
    self.description = description
  }

  public var errorDescription: String? {
    "Failed to execute '\(command)': \(description)"
  }
}

extension OpenSimulatorError {
  /// Creates an `OpenSimulatorError` from an `ExecutionError`
  ///
  /// This convenience initializer converts a low-level subprocess execution error
  /// into an OpenSimulator-specific error, making it easy to propagate command failures
  /// from the SubprocessKit layer to the SimulatorKit API.
  ///
  /// - Parameter error: The ``ExecutionError`` that occurred during command execution
  ///
  /// ## Example
  ///
  /// ```swift
  /// do {
  ///   try await open.execute(arguments)
  /// } catch let error as ExecutionError {
  ///   throw OpenSimulatorError(error)
  /// }
  /// ```
  init(_ error: ExecutionError) {
    self.init(command: error.command, description: error.description)
  }
}
