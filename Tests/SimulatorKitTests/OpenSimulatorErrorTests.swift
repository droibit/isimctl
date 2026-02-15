import Testing
@testable import SimulatorKit
@testable import SubprocessKit

struct OpenSimulatorErrorTests {
  // MARK: - Initializer from ExecutionError

  @Test
  func init_shouldConvertExecutionErrorWithValidData() {
    // Given: An ExecutionError with command and description
    let execError = ExecutionError(
      command: "open -a \"Simulator\"",
      description: "Application not found",
    )

    // When: Creating OpenSimulatorError from ExecutionError
    let error = OpenSimulatorError(execError)

    // Then: Verify the error is correctly created
    #expect(error.command == "open -a \"Simulator\"")
    #expect(error.description == "Application not found")
  }

  // MARK: - Equivalence with Designated Initializer

  @Test
  func init_fromExecutionError_shouldBeEquivalentToDesignatedInitializer() {
    // Given: An ExecutionError
    let execError = ExecutionError(
      command: "open -a \"Simulator\"",
      description: "Failed",
    )

    // When: Creating OpenSimulatorError using both methods
    let errorFromConvenience = OpenSimulatorError(execError)
    let errorFromDesignated = OpenSimulatorError(
      command: execError.command,
      description: execError.description,
    )

    // Then: Verify both are equal
    #expect(errorFromConvenience == errorFromDesignated)
  }
}
