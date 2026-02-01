import ArgumentParser
import IsimctlUI
import Noora

struct ListCommand: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "list",
    abstract: "Interactively browse and list simulators",
    usage: "isimctl list [<search-term>] [options]",
    discussion: """
    Browses simulators installed on the system using an interactive interface.

    First, you will be prompted to select a runtime environment.
    - Default behavior: Select a specific device to view details.
    - With `--all`: Displays all devices available for the selected runtime.
    - With `<search-term>`: Filters devices by the search term (e.g., "booted", "available").
      When a search term is provided without `--all`, only the runtime selection is shown,
      followed by a list of all matching devices (no individual device selection).
    """,
  )

  @Argument(help: "Search term to filter devices (e.g., 'booted', 'available')")
  var searchTerm: String?

  @Flag(name: .shortAndLong, help: "Display all devices without selection")
  var allDevices = false

  mutating func run() async throws {
    let command = ListDevicesCommand(noora: Noora.current)
    try await command.run(searchTerm: searchTerm, showAll: allDevices)
  }
}
