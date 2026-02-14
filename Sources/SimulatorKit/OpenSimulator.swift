import Foundation
import Subprocess
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
  private let openCommand = Executable.name("open")
  private let runner: any CommandRunnable

  public init() {
    self.init(runner: CommandRunner())
  }

  init(runner: any CommandRunnable) {
    self.runner = runner
  }

  public func open(udid: String?) async throws {
    var arguments = ["-a", "\"Simulator\""]
    if let udid {
      arguments.append(contentsOf: ["--args", "-CurrentDeviceUDID", udid])
    }

    do {
      try await runner.execute(openCommand, arguments: Arguments(arguments))
    } catch let error as CommandExecutionError {
      throw OpenSimulatorError(
        command: error.command,
        description: error.description,
      )
    }
  }
}
