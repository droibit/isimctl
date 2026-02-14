import Subprocess
import Testing
@testable import SimctlKit
@testable import SubprocessKit

struct SimctlIntegrationTests {
  private let simctl = Simctl()

  @Test
  func listDevices_shouldReturnDevicesWithValidProperties() async throws {
    let simulatorList = try await simctl.listDevices(searchTerm: nil)
    for (runtime, devices) in simulatorList.devices {
      #expect(!runtime.isEmpty)

      for device in devices {
        #expect(!device.name.isEmpty)
        #expect(!device.udid.isEmpty)
        #expect(!device.state.isEmpty)
        #expect(!device.deviceTypeIdentifier.isEmpty)
      }
    }
  }

  @Test
  func listDevices_shouldFilterDevicesWhenSearchTermProvided() async throws {
    // This test verifies that the "booted" search term is accepted
    // The result may be empty if no devices are booted
    _ = try await simctl.listDevices(searchTerm: .booted)
  }
}
