import Foundation

/// Executor for `xcrun simctl` commands
public struct Simctl: Sendable {
  private let xcrun = Xcrun()

  public init() {}

  /// Executes `xcrun simctl list runtimes --json` and returns parsed RuntimeList
  ///
  /// - Returns: RuntimeList containing available runtimes
  /// - Throws: ``XcrunError`` if command execution fails or output is invalid
  public func listRuntimes() async throws -> RuntimeList {
    do {
      let standardOutput = try await list(for: "runtimes")
      return try JSONDecoder().decode(RuntimeList.self, from: standardOutput)
    } catch _ as DecodingError {
      throw XcrunError.invalidOutput(
        "Failed to parse runtime information. Please ensure your Xcode is properly installed."
      )
    }
  }

  /// Executes `xcrun simctl list devices --json` and returns parsed SimulatorList
  ///
  /// - Returns: SimulatorList containing available devices
  /// - Throws: ``XcrunError`` if command execution fails or output is invalid
  public func listDevices() async throws -> SimulatorList {
    do {
      let standardOutput = try await list(for: "devices")
      return try JSONDecoder().decode(SimulatorList.self, from: standardOutput)
    } catch _ as DecodingError {
      throw XcrunError.invalidOutput(
        "Failed to parse device information. Please ensure your Xcode is properly installed."
      )
    }
  }

  private func list(for target: String) async throws -> Data {
    do {
      try xcrun.checkAvailability()
    } catch {
      throw XcrunError.xcrunNotFound
    }
    
    let output = try await xcrun.run(arguments: ["simctl", "list", target, "--json"])
    guard let data = output.data(using: .utf8) else {
      throw XcrunError.invalidOutput("Failed to process command output.")
    }
    return data
  }
}
