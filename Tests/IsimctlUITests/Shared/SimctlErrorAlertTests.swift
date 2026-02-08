import Noora
import SimctlKit
import Testing
@testable import IsimctlUI

struct SimctlErrorAlertTests {
  private let noora: NooraMock
  private let errorAlert: SimctlErrorAlert

  init() {
    noora = NooraMock()
    errorAlert = SimctlErrorAlert(noora: noora)
  }

  @Test
  func show_xcrunNotFound_shouldContainCorrectMessageAndTakeaways() {
    let error = SimctlError.xcrunNotFound
    errorAlert.show(error)

    let output = noora.description
    // swiftlint:disable trailing_whitespace
    #expect(output == """
    stderr: ✖ Error
    stderr:   xcrun command not found. Please ensure Xcode is installed.
    stderr: 
    stderr:   Sorry this didn’t work. Here’s what to try next:
    stderr:    ▸ You can download Xcode from the Mac App Store
    stderr:    ▸ After installing Xcode, you may need to run 'xcode-select --install' to install command line tools
    """)
    // swiftlint:enable trailing_whitespace
  }

  @Test
  func show_commandFailed_shouldContainCommandAndErrorDetails() {
    let error = SimctlError.commandFailed(
      command: "xcrun simctl list devices",
      description: "Command execution failed with exit code 1",
    )
    errorAlert.show(error)

    let output = noora.description
    // swiftlint:disable trailing_whitespace
    #expect(output == """
    stderr: ✖ Error
    stderr:   Command Failed: 'xcrun simctl list devices'
    stderr:   Command execution failed with exit code 1
    stderr: 
    stderr:   Sorry this didn’t work. Here’s what to try next:
    stderr:    ▸ Please report this issue at: https://github.com/droibit/isimctl
    stderr:    ▸ Include error details and the output of 'xcrun --version'
    """)
    // swiftlint:enable trailing_whitespace
  }

  @Test
  func show_invalidOutput_shouldContainSummaryAndDescription() {
    let error = SimctlError.invalidOutput(
      summary: "Failed to parse device information.",
      description: "The data couldn't be read because it isn't in the correct format.",
    )
    errorAlert.show(error)

    let output = noora.description
    // swiftlint:disable trailing_whitespace
    #expect(output == """
    stderr: ✖ Error
    stderr:   Failed to parse device information.
    stderr:   The data couldn't be read because it isn't in the correct format.
    stderr: 
    stderr:   Sorry this didn’t work. Here’s what to try next:
    stderr:    ▸ Please report this issue at: https://github.com/droibit/isimctl
    stderr:    ▸ Include error details and the output of 'xcrun --version'
    """)
    // swiftlint:enable trailing_whitespace
  }
}
