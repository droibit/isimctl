import ArgumentParser

@main
struct Isimctl: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "isimctl",
    abstract: "Interactive wrapper for xcrun simctl command",
    discussion: "isimctl provides an interactive and user-friendly way to browse simulators. It simplifies interaction with Xcode's simulator control (simctl) command through an intuitive interface.",
    version: "0.0.1",
    subcommands: [
      ListCommand.self,
      BootCommand.self,
    ],
  )
}
