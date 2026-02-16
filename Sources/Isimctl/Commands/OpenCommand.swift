import ArgumentParser
import IsimctlUI
import Noora

struct OpenCommand: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "open",
    abstract: "Interactively open a simulator in Simulator.app",
    usage: "isimctl open [options]",
    discussion: """
    Opens a simulator in Simulator.app using an interactive interface.

    First, you will be prompted to select a runtime environment.
    Then, you select a specific device to open.

    Only devices that are currently shut down and available are shown.
    """,
  )

  @Flag(name: [.short, .long], help: "Prompt for confirmation before opening.")
  var confirm: Bool = false

  mutating func run() async throws {
    let command = OpenDeviceCommand(noora: Noora.current)
    try await command.run(shouldConfirm: confirm)
  }
}
