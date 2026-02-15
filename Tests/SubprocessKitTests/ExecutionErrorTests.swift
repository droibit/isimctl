import Testing
@testable import Subprocess
@testable import SubprocessKit

struct ExecutionErrorTests {
  // MARK: - StringOutput Initializer Tests

  @Test
  func initFromStringOutputResult_shouldUseStandardErrorWhenAvailable() {
    // Given
    let command = "xcrun simctl list"
    let standardError = "Error: Invalid JSON"
    let standardOutput = "Some output"
    let result = makeStringOutputResult(
      standardOutput: standardOutput,
      standardError: standardError,
      terminationStatus: .failure,
    )

    // When
    let error = ExecutionError(command: command, from: result)

    // Then
    #expect(error.command == command)
    #expect(error.description == standardError)
  }

  @Test
  func initFromStringOutputResult_shouldUseStandardOutputWhenStandardErrorIsNil() {
    // Given
    let command = "xcrun simctl list"
    let standardOutput = "Output message"
    let result = makeStringOutputResult(
      standardOutput: standardOutput,
      standardError: nil,
      terminationStatus: .failure,
    )

    // When
    let error = ExecutionError(command: command, from: result)

    // Then
    #expect(error.command == command)
    #expect(error.description == standardOutput)
  }

  @Test
  func initFromStringOutputResult_shouldUseTerminationStatusWhenBothOutputsAreNil() {
    // Given
    let command = "xcrun simctl list"
    let terminationStatus = TerminationStatus.failure
    let result = makeStringOutputResult(
      standardOutput: nil,
      standardError: nil,
      terminationStatus: terminationStatus,
    )

    // When
    let error = ExecutionError(command: command, from: result)

    // Then
    #expect(error.command == command)
    #expect(error.description == terminationStatus.description)
  }

  // MARK: - DiscardedOutput Initializer Tests

  @Test
  func initFromDiscardedOutputResult_shouldUseStandardErrorWhenAvailable() {
    // Given
    let command = "open -a Simulator"
    let standardError = "Error: Application not found"
    let result = makeDiscardedOutputResult(
      standardError: standardError,
      terminationStatus: .failure,
    )

    // When
    let error = ExecutionError(command: command, from: result)

    // Then
    #expect(error.command == command)
    #expect(error.description == standardError)
  }

  @Test
  func initFromDiscardedOutputResult_shouldUseTerminationStatusWhenStandardErrorIsNil() {
    // Given
    let command = "open -a Simulator"
    let terminationStatus = TerminationStatus.exited(127)
    let result = makeDiscardedOutputResult(
      standardError: nil,
      terminationStatus: terminationStatus,
    )

    // When
    let error = ExecutionError(command: command, from: result)

    // Then
    #expect(error.command == command)
    #expect(error.description == terminationStatus.description)
  }

  // MARK: - Test Helpers

  private func makeStringOutputResult(
    standardOutput: String?,
    standardError: String?,
    terminationStatus: TerminationStatus,
  ) -> CollectedResult<StringOutput<Unicode.UTF8>, StringOutput<Unicode.UTF8>> {
    CollectedResult(
      processIdentifier: .init(value: 1),
      terminationStatus: terminationStatus,
      standardOutput: standardOutput,
      standardError: standardError,
    )
  }

  private func makeDiscardedOutputResult(
    standardError: String?,
    terminationStatus: TerminationStatus,
  ) -> CollectedResult<DiscardedOutput, StringOutput<Unicode.UTF8>> {
    CollectedResult(
      processIdentifier: .init(value: 2),
      terminationStatus: terminationStatus,
      standardOutput: (),
      standardError: standardError,
    )
  }
}

extension TerminationStatus {
  static var failure: Self {
    .exited(1)
  }
}
