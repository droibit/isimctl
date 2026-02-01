import Noora
import SimctlKit

/// Protocol for displaying SimctlError as an alert using Noora
/// @mockable
protocol SimctlErrorAlerting: Sendable {
  /// Shows an error alert for the given ``SimctlError``
  ///
  /// - Parameter error: The ``SimctlError`` to display as an alert
  func show(_ error: SimctlError)
}

/// Component for displaying SimctlError alerts using Noora
struct SimctlErrorAlert: SimctlErrorAlerting {
  private let noora: any Noorable

  init(noora: any Noorable) {
    self.noora = noora
  }

  func show(_ error: SimctlError) {
    noora.error(toErrorAlert(error))
  }

  private func toErrorAlert(_ error: SimctlError) -> ErrorAlert {
    switch error {
    case .xcrunNotFound:
      .alert(
        "xcrun command not found. Please ensure Xcode is installed.",
        takeaways: [
          "You can download Xcode from the Mac App Store",
          "After installing Xcode, you may need to run \(.command("xcode-select --install")) to install command line tools",
        ],
      )
    case let .commandFailed(command, description):
      .alert(
        "Command Failed: \(.command(command))\n\(.muted(description))",
        takeaways: [
          "Please report this issue at: https://github.com/droibit/isimctl",
          "Include error details and the output of \(.command("xcrun --version"))",
        ],
      )
    case let .invalidOutput(summary, description):
      .alert(
        "\(summary)\n\(.muted(description))",
        takeaways: [
          "Please report this issue at: https://github.com/droibit/isimctl",
          "Include error details and the output of \(.command("xcrun --version"))",
        ],
      )
    }
  }
}
