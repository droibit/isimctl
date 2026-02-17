import Foundation
import SubprocessKit

/// Protocol for opening Simulator.app
/// @mockable
public protocol SimulatorOpenable: Sendable {
  /// Opens Simulator.app with an optional device UDID
  ///
  /// - Parameter udid: Optional device UDID. If nil, opens Simulator.app without a specific device.
  /// - Throws: ``OpenSimulatorError`` if the command execution fails
  func open(udid: String?) async throws
}

/// Opens Simulator.app using macOS `open` command
public struct OpenSimulator: SimulatorOpenable {
  private let open: any Executing

  public init() {
    self.init(open: Executor(name: "open"))
  }

  init(open: any Executing) {
    self.open = open
  }

  public func open(udid: String?) async throws {
    var arguments = ["-a", "Simulator"]
    if let udid {
      arguments.append(contentsOf: ["--args", "-CurrentDeviceUDID", udid])
    }

    do {
      try await open.execute(arguments)
    } catch let error as ExecutionError {
      throw OpenSimulatorError(error)
    }
  }
}
