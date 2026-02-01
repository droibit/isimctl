import Testing
@testable import SimctlKit

struct XcrunIntegrationTests {
  private let xcrun = Xcrun()

  @Test
  func run_shouldExecuteSimctlListDevicesCommand() async throws {
    try #require(xcrun.isAvailable(), "xcrun is not available")

    let output = try await xcrun.run(arguments: ["simctl", "list", "devices", "--json"])
    #expect(!output.isEmpty)
    #expect(output.contains("\"devices\""))
  }

  @Test
  func run_shouldExecuteXcrunVersionCommand() async throws {
    try #require(xcrun.isAvailable(), "xcrun is not available")

    let output = try await xcrun.run(arguments: ["--version"])
    #expect(!output.isEmpty)
    #expect(output.contains("xcrun"))
  }

  @Test
  func run_shouldThrowXcrunErrorWhenInvalidCommandProvided() async throws {
    try #require(xcrun.isAvailable(), "xcrun is not available")

    await #expect(throws: XcrunError.self) {
      try await xcrun.run(arguments: ["nonexistent-command"])
    }
  }
}
