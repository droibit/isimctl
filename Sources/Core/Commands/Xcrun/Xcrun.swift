import Foundation
import Subprocess
import System

/// Executor for `xcrun` commands
public struct Xcrun: Sendable {
  public init() {}

  /// Checks if `xcrun` command is available
  ///
  /// - Throws: `XcrunError.xcrunNotFound` if xcrun is not found
  public func checkAvailability() throws {
    do {
      _ = try Executable.path("/usr/bin/xcrun")
        .resolveExecutablePath(in: .inherit)
    } catch {
      throw XcrunError.xcrunNotFound
    }
  }

  /// Executes `xcrun` command with specified arguments
  ///
  /// - Parameter arguments: Arguments to pass to xcrun command
  /// - Returns: Standard output as String
  /// - Throws: ``XcrunError`` if command execution fails or output is invalid
  public func run(arguments: [String]) async throws -> String {
    try checkAvailability()

    let result = try await Subprocess.run(
      .path("/usr/bin/xcrun"),
      arguments: Arguments(arguments),
      output: .string(limit: .max),
      error: .string(limit: .max)
    )

    guard result.terminationStatus.isSuccess else {
      let stderr = result.standardError ?? "Unknown error occurred."
      throw XcrunError.commandFailed(stderr)
    }

    guard let standardOutput = result.standardOutput else {
      throw XcrunError.invalidOutput("Failed to process command output.")
    }
    return standardOutput
  }
}
