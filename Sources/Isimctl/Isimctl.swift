import ArgumentParser

@main
struct Isimctl: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "isimctl",
    abstract: "Interactive simulator management tool",
    discussion: "isimctl provides an interactive and user-friendly way to manage Xcode simulators. It simplifies simulator operations through a conversational terminal interface, guiding you through device selection and management tasks.",
    version: "0.0.1",
    subcommands: [
      ListCommand.self,
      BootCommand.self,
    ],
  )
}
