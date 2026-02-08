import ArgumentParser
import IsimctlUI
import Noora

struct BootCommand: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "boot",
    abstract: "Interactively boot a simulator",
    usage: "isimctl boot",
    discussion: """
    Boots a simulator using an interactive interface.

    First, you will be prompted to select a runtime environment.
    Then, you select a specific device to boot.

    Only devices that are currently shut down and available are shown.
    """,
  )

  mutating func run() async throws {
    let command = BootDeviceCommand(noora: Noora.current)
    try await command.run()
  }
}
