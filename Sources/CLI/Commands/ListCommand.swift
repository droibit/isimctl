import ArgumentParser
import Core
import Noora

struct ListCommand: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "list",
    // TODO: Add abstract, usage, discussion
  )
    
  mutating func run() async throws {
    print("Hello, world!")
  }
}
