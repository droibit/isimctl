import ArgumentParser
import IsimctlUI
import Noora

struct ShutdownCommand: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "shutdown",
    abstract: "Interactively shutdown a simulator",
    usage: "isimctl shutdown [options]",
    discussion: """
    Shuts down a simulator using an interactive interface.

    First, you will be prompted to select a runtime environment.
    Then, you select a specific device to shut down.

    Only devices that are currently booted are shown.

    - With `--all-devices`: Shuts down all currently running devices without selection.
    """,
  )

  @Flag(name: .shortAndLong, help: "Shutdown all running devices.")
  var allDevices = false

  @Flag(name: [.short, .long], help: "Prompt for confirmation before shutting down.")
  var confirm: Bool = false

  mutating func run() async throws {
    let command = ShutdownDeviceCommand(noora: Noora.current)
    try await command.run(allDevices: allDevices, shouldConfirm: confirm)
  }
}
