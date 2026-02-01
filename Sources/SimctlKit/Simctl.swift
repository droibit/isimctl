public import Foundation

/// Protocol for executing `xcrun simctl` commands
/// @mockable
public protocol Simctlable: Sendable {
  /// Executes `xcrun simctl list devices --json` and returns parsed ``SimulatorList``
  ///
  /// - Parameter searchTerm: Optional search term to filter devices
  /// - Returns: ``SimulatorList`` containing available devices
  /// - Throws: ``SimctlError`` if command execution fails or output is invalid
  func listDevices(searchTerm: String?) async throws -> SimulatorList
}

/// Public interface for executing simctl commands
public struct Simctl: Simctlable, Sendable {
  private let xcrun: any Xcrunnable

  public init() {
    self.init(xcrun: Xcrun())
  }

  init(xcrun: any Xcrunnable) {
    self.xcrun = xcrun
  }

  public func listDevices(searchTerm: String?) async throws -> SimulatorList {
    guard xcrun.isAvailable() else {
      throw SimctlError.xcrunNotFound
    }

    do {
      var arguments = ["simctl", "list", "devices"]
      if let searchTerm, !searchTerm.isEmpty {
        arguments.append(searchTerm)
      }
      arguments.append("--json")
      let output = try await xcrun.run(arguments: arguments)
      return try JSONDecoder().decode(SimulatorList.self, from: output.data(using: .utf8)!)
    } catch let error as XcrunError {
      throw SimctlError.commandFailed(command: error.command, description: error.description)
    } catch let error as DecodingError {
      throw SimctlError.invalidOutput(
        summary: "Failed to parse device information.",
        description: error.localizedDescription,
      )
    }
  }
}

// MARK: - Error

/// Error types that can occur when executing `xcrun simctl` commands
public enum SimctlError: LocalizedError, Sendable {
  case xcrunNotFound
  case commandFailed(command: String, description: String)
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
