import Noora

/// A test implementation of `Terminaling` that provides a fixed terminal size
/// to prevent content truncation in table displays during testing.
struct MockTerminal: Terminaling {
  private let terminal: Terminal
  private let terminalSize: TerminalSize

  var isInteractive: Bool {
    terminal.isInteractive
  }

  var isColored: Bool {
    terminal.isColored
  }

  var signalBehavior: SignalBehavior {
    terminal.signalBehavior
  }

  init(
    isInteractive: Bool = false,
    isColored: Bool = false,
    signalBehavior: SignalBehavior = .none,
    terminalSize: TerminalSize = TerminalSize(rows: 100, columns: 200),
  ) {
    terminal = Terminal(
      isInteractive: isInteractive,
      isColored: isColored,
      signalBehavior: signalBehavior,
    )
    self.terminalSize = terminalSize
  }

  func withoutCursor(_ body: () throws -> Void) rethrows {
    try terminal.withoutCursor(body)
  }

  func inRawMode(_ body: @escaping () throws -> Void) rethrows {
    try terminal.inRawMode(body)
  }

  func readRawCharacter() -> Int32? {
    terminal.readRawCharacter()
  }

  func readCharacter() -> Character? {
    terminal.readCharacter()
  }

  func readRawCharacterNonBlocking() -> Int32? {
    terminal.readRawCharacterNonBlocking()
  }

  func readCharacterNonBlocking() -> Character? {
    terminal.readCharacterNonBlocking()
  }

  func size() -> TerminalSize? {
    terminalSize
  }
}
