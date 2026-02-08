import Foundation

/// Internal error type for xcrun command execution failures
struct XcrunError: LocalizedError, Equatable {
  let command: String
  let description: String

  var errorDescription: String {
    "Command failed: \(command)\n\(description)"
  }
}
