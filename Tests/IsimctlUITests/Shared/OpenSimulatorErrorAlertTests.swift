import Noora
import SimulatorKit
import Testing
@testable import IsimctlUI

struct OpenSimulatorErrorAlertTests {
  private let noora: NooraMock
  private let errorAlert: OpenSimulatorErrorAlert

  init() {
    noora = NooraMock()
    errorAlert = OpenSimulatorErrorAlert(noora: noora)
  }

  @Test
  func show_shouldContainCommandAndErrorDetails() {
    let error = OpenSimulatorError(
      command: "open -a \"Simulator\" --args -CurrentDeviceUDID ABC123",
      description: "Command execution failed with exit code 1",
    )
    errorAlert.show(error)

    let output = noora.description
    // swiftlint:disable trailing_whitespace
    #expect(output == """
    stderr: ✖ Error
    stderr:   Command Failed: 'open -a \"Simulator\" --args -CurrentDeviceUDID ABC123'
    stderr:   Command execution failed with exit code 1
    stderr: 
    stderr:   Sorry this didn’t work. Here’s what to try next:
    stderr:    ▸ Please ensure Simulator.app is installed
    stderr:    ▸ Please report this issue at: https://github.com/droibit/isimctl
    """)
    // swiftlint:enable trailing_whitespace
  }
}
