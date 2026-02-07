import Noora

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

  init(noora: any Noorable) {
    self.noora = noora
  }

  func selectRuntime(
    from options: [RuntimeDeviceGroupOption],
    autoselectSingleChoice: Bool,
  ) -> RuntimeDeviceGroupOption {
    noora.singleChoicePrompt(
      question: "Select a runtime",
      options: options,
      collapseOnSelection: true,
      filterMode: .disabled,
      autoselectSingleChoice: autoselectSingleChoice,
    )
  }

  func selectDevice(from options: [DeviceOption]) -> DeviceOption {
    noora.singleChoicePrompt(
      question: "Select a device",
      options: options,
      collapseOnSelection: true,
      filterMode: .enabled,
      autoselectSingleChoice: false,
    )
  }
}
