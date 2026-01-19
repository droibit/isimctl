import ArgumentParser

@main
struct CLI: ParsableCommand {
  mutating func run() throws {
    print("Hello, world!")
  }
}
