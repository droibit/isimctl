import Foundation
import Subprocess

/// Protocol for executing subprocess commands
/// @mockable(typealias: Output=StringOutput<UTF8>; Error=StringOutput<UTF8>)
protocol SubprocessRunnable: Sendable {
  typealias Output = StringOutput<UTF8>
  typealias ErrorOutput = StringOutput<UTF8>
  typealias CollectedResult = Subprocess.CollectedResult<Output, ErrorOutput>

  /// Checks if an executable is available
  ///
  /// - Parameter executable: The executable to check
  /// - Returns: `true` if executable is available, `false` otherwise
  func isExecutableAvailable(_ executable: Executable) -> Bool

  /// Executes a subprocess command
  ///
  /// - Parameters:
  ///   - executable: The executable to run
  ///   - arguments: Arguments to pass to the executable
  ///   - output: Output method for standard output
  ///   - error: Output method for standard error
  /// - Returns: Result of the subprocess execution
  /// - Throws: Error if subprocess execution fails
  func run(
    _ executable: Executable,
    arguments: Arguments,
    output: Output,
    error: ErrorOutput,
  ) async throws -> CollectedResult
}

/// Default implementation using actual Subprocess
struct DefaultSubprocessRunner: SubprocessRunnable {
  func isExecutableAvailable(_ executable: Executable) -> Bool {
    do {
      _ = try executable.resolveExecutablePath(in: .inherit)
      return true
    } catch {
      return false
    }
  }

  func run(
    _ executable: Executable,
    arguments: Arguments,
    output: Output,
    error: ErrorOutput,
  ) async throws -> CollectedResult<Output, ErrorOutput> {
    try await Subprocess.run(
      executable,
      arguments: arguments,
      output: output,
      error: error,
    )
  }
}
