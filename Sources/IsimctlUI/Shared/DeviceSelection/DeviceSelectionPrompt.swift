import Noora

/// Enum representing the purpose of device selection
/// Provides appropriate question text based on the context in which device selection occurs
enum DeviceSelectionPurpose: Sendable {
  /// Device selection for listing and viewing available devices
  case listDevices
  /// Device selection for booting a device
  case bootDevice

  /// Returns the question text for both runtime and device selection
  var questions: (runtime: String, device: String) {
    switch self {
    case .listDevices:
      (
        runtime: "Which runtime's devices would you like to see?",
        device: "Which device would you like to view?",
      )
    case .bootDevice:
      (
        runtime: "Which runtime contains the device to boot?",
        device: "Which device would you like to boot?",
      )
    }
  }
}

/// Protocol for selecting runtime and device options using interactive prompts
/// @mockable
protocol DeviceSelectionPrompting: Sendable {
  /// Prompts the user to select a runtime from the provided options
  ///
  /// - Parameters:
  ///   - options: The list of runtime options to choose from
  ///   - autoselectSingleChoice: Whether to automatically select if only one option exists
  /// - Returns: The selected runtime option
  func selectRuntime(
    from options: [RuntimeDeviceGroupOption],
    autoselectSingleChoice: Bool,
  ) -> RuntimeDeviceGroupOption

  /// Prompts the user to select a device from the provided options
  ///
  /// - Parameter options: The list of device options to choose from
  /// - Returns: The selected device option
  func selectDevice(from options: [DeviceOption]) -> DeviceOption
}

/// Component for selecting runtime and device options using Noora prompts
struct DeviceSelectionPrompt: DeviceSelectionPrompting {
  private let noora: any Noorable
  private let questions: (runtime: String, device: String)

  init(noora: any Noorable, purpose: DeviceSelectionPurpose) {
    questions = purpose.questions
    self.noora = noora
  }

  func selectRuntime(
    from options: [RuntimeDeviceGroupOption],
    autoselectSingleChoice: Bool,
  ) -> RuntimeDeviceGroupOption {
    noora.singleChoicePrompt(
      question: TerminalText(stringLiteral: questions.runtime),
      options: options,
      collapseOnSelection: true,
      filterMode: .disabled,
      autoselectSingleChoice: autoselectSingleChoice,
    )
  }

  func selectDevice(from options: [DeviceOption]) -> DeviceOption {
    noora.singleChoicePrompt(
      question: TerminalText(stringLiteral: questions.device),
      options: options,
      collapseOnSelection: true,
      filterMode: .enabled,
      autoselectSingleChoice: false,
    )
  }
}
