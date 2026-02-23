/// Represents the target for a shutdown operation
public enum ShutdownTarget: Equatable, Sendable {
  /// Shuts down the device with the specified UDID
  case device(udid: String)
  /// Shuts down all currently running devices
  case all

  /// Returns the argument string to pass to `xcrun simctl shutdown`
  var xcrunArgument: String {
    switch self {
    case let .device(udid):
      udid
    case .all:
      "all"
    }
  }
}
