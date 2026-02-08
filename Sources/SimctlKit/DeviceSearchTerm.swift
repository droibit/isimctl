/// Represents the search term for filtering devices with `xcrun simctl list`
public struct DeviceSearchTerm: Equatable, Sendable {
  /// The string value to pass to xcrun
  public let value: String

  public init?(_ value: String?) {
    guard let value, !value.isEmpty else {
      return nil
    }
    self.value = value
  }

  /// Predefined search term for "booted" devices
  public static var booted: DeviceSearchTerm {
    DeviceSearchTerm("booted")!
  }

  /// Predefined search term for "available" devices
  public static var available: DeviceSearchTerm {
    DeviceSearchTerm("available")!
  }
}
