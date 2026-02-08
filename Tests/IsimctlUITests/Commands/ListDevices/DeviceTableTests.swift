import Noora
import SimctlKit
import Testing
@testable import IsimctlUI

struct DeviceTableTests {
  private let noora: NooraMock
  private let deviceTable: DeviceTable

  init() {
    noora = NooraMock(terminal: MockTerminal(
      terminalSize: TerminalSize(rows: 100, columns: 300),
    ))
    deviceTable = DeviceTable(noora: noora)
  }

  // MARK: - display Tests

  @Test
  func display_deviceShouldDisplayTableWithCorrectStructure() throws {
    let device = Device(
      name: "iPhone 16 Pro",
      state: "Shutdown",
      udid: "12345678-1234-1234-1234-123456789012",
      deviceTypeIdentifier: "com.apple.CoreSimulator.SimDeviceType.iPhone-16-Pro",
    )
    deviceTable.display(device)

    let table = NooraTableAssertion(output: noora.description)
    // Verify header row contains all column names
    try table.assertHeader(containsInOrder: ["Name", "State", "UDID", "Device Type Identifier"])
    let headerRow = try #require(table.headerRow)
    #expect(headerRow.contains("Runtime") == false)

    // Verify device data row contains all device information
    try table.assertRow(at: 0, containsInOrder: [
      "iPhone 16 Pro",
      "Shutdown",
      "12345678-1234-1234-1234-123456789012",
      "com.apple.CoreSimulator.SimDeviceType.iPhone-16-Pro",
    ])
  }

  @Test
  func display_inRuntimeShouldDisplayTableWithoutRuntimeColumn() throws {
    let devices = [
      Device(
        name: "iPhone 16 Pro",
        state: "Booted",
        udid: "11111111-1111-1111-1111-111111111111",
        deviceTypeIdentifier: "com.apple.CoreSimulator.SimDeviceType.iPhone-16-Pro",
      ),
      Device(
        name: "iPhone SE (3rd generation)",
        state: "Shutdown",
        udid: "22222222-2222-2222-2222-222222222222",
        deviceTypeIdentifier: "com.apple.CoreSimulator.SimDeviceType.iPhone-SE-3rd-generation",
      ),
    ]
    let runtime = RuntimeDeviceGroupOption(
      runtime: "iOS 18.2",
      devices: devices,
    )
    deviceTable.display(in: runtime)

    let table = NooraTableAssertion(output: noora.description)
    // Verify header row contains all column names
    try table.assertHeader(containsInOrder: ["Name", "State", "UDID", "Device Type Identifier"])
    let headerRow = try #require(table.headerRow)
    #expect(headerRow.contains("Runtime") == false)

    // Verify first device data row (index 0)
    try table.assertRow(at: 0, containsInOrder: [
      "iPhone 16 Pro",
      "Booted",
      "11111111-1111-1111-1111-111111111111",
      "com.apple.CoreSimulator.SimDeviceType.iPhone-16-Pro",
    ])
    // Verify second device data row (index 1)
    try table.assertRow(at: 1, containsInOrder: [
      "iPhone SE (3rd generation)",
      "Shutdown",
      "22222222-2222-2222-2222-222222222222",
      "com.apple.CoreSimulator.SimDeviceType.iPhone-SE-3rd-generation",
    ])
  }

  @Test
  func display_devicesWithRuntimeShouldDisplayTableWithRuntimeColumn() throws {
    let devicesWithRuntime = [
      DeviceWithRuntime(
        device: Device(
          name: "iPhone 16 Pro",
          state: "Booted",
          udid: "11111111-1111-1111-1111-111111111111",
          deviceTypeIdentifier: "com.apple.CoreSimulator.SimDeviceType.iPhone-16-Pro",
        ),
        runtime: "iOS 18.2",
      ),
      DeviceWithRuntime(
        device: Device(
          name: "Apple Watch Series 10 (46mm)",
          state: "Shutdown",
          udid: "33333333-3333-3333-3333-333333333333",
          deviceTypeIdentifier: "com.apple.CoreSimulator.SimDeviceType.Apple-Watch-Series-10-46mm",
        ),
        runtime: "watchOS 11.2",
      ),
    ]
    deviceTable.display(devicesWithRuntime)

    let table = NooraTableAssertion(output: noora.description)
    // Verify header row contains all column names including Runtime
    try table.assertHeader(containsInOrder: ["Runtime", "Name", "State", "UDID", "Device Type Identifier"])
    // Verify first device data row (index 0)
    try table.assertRow(at: 0, containsInOrder: [
      "iOS 18.2",
      "iPhone 16 Pro",
      "Booted",
      "11111111-1111-1111-1111-111111111111",
      "com.apple.CoreSimulator.SimDeviceType.iPhone-16-Pro",
    ])
    // Verify second device data row (index 1)
    try table.assertRow(at: 1, containsInOrder: [
      "watchOS 11.2",
      "Apple Watch Series 10 (46mm)",
      "Shutdown",
      "33333333-3333-3333-3333-333333333333",
      "com.apple.CoreSimulator.SimDeviceType.Apple-Watch-Series-10-46mm",
    ])
  }
}
