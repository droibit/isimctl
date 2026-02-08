import Foundation

/// Protocol for executing `xcrun simctl` commands
/// @mockable
public protocol Simctlable: Sendable {
  /// Executes `xcrun simctl list devices --json` and returns parsed ``SimulatorList``
  ///
  /// - Parameter searchTerm: Optional search term to filter devices
  /// - Returns: ``SimulatorList`` containing available devices
  /// - Throws: ``SimctlError`` if command execution fails or output is invalid
  func listDevices(searchTerm: DeviceSearchTerm?) async throws -> SimulatorList

  /// Executes `xcrun simctl boot <udid>` to boot a device
  ///
  /// - Parameter udid: The unique device identifier (must not be empty)
  /// - Throws: ``SimctlError`` if command execution fails or xcrun is not available
  /// - Precondition: `udid` must not be empty
  func bootDevice(udid: String) async throws
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

  public func listDevices(searchTerm: DeviceSearchTerm?) async throws -> SimulatorList {
    guard xcrun.isAvailable() else {
      throw SimctlError.xcrunNotFound
    }

    do {
      var arguments = ["simctl", "list", "devices"]
      if let term = searchTerm?.value {
        arguments.append(term)
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

  public func bootDevice(udid: String) async throws {
    precondition(!udid.isEmpty, "udid must not be empty")

    guard xcrun.isAvailable() else {
      throw SimctlError.xcrunNotFound
    }

    do {
      let arguments = ["simctl", "boot", udid]
      try await xcrun.run(arguments: arguments)
    } catch let error as XcrunError {
      throw SimctlError.commandFailed(command: error.command, description: error.description)
    }
  }
}
