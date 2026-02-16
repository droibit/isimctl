import Noora
import SimulatorKit

/// Protocol for displaying OpenSimulatorError as an alert using Noora
/// @mockable
protocol OpenSimulatorErrorAlerting: Sendable {
  /// Shows an error alert for the given ``OpenSimulatorError``
  ///
  /// - Parameter error: The ``OpenSimulatorError`` to display as an alert
  func show(_ error: OpenSimulatorError)
}

/// Component for displaying OpenSimulatorError alerts using Noora
struct OpenSimulatorErrorAlert: OpenSimulatorErrorAlerting {
  private let noora: any Noorable

  init(noora: any Noorable) {
    self.noora = noora
  }

  func show(_ error: OpenSimulatorError) {
    noora.error(.alert(
      "Command Failed: \(.command(error.command))\n\(.muted(error.description))",
      takeaways: [
        "Please ensure Simulator.app is installed",
        "Please report this issue at: https://github.com/droibit/isimctl",
      ],
    ))
  }
}
