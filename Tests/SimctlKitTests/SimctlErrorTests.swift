import Testing
@testable import SimctlKit
@testable import SubprocessKit

struct SimctlErrorTests {
  // MARK: - commandFailed(error:) Conversion

  @Test
  func commandFailed_shouldConvertExecutionErrorWithValidData() {
    // Given: An ExecutionError with command and description
    let execError = ExecutionError(
      command: "xcrun simctl list devices",
      description: "Command timed out",
    )

    // When: Converting to SimctlError using the factory method
    let simctlError = SimctlError.commandFailed(error: execError)

    // Then: Verify the error is correctly converted
    let expectedError = SimctlError.commandFailed(
      command: "xcrun simctl list devices",
      description: "Command timed out",
    )
    #expect(simctlError == expectedError)
  }
}
