import Noora
import SimctlKit

/// Protocol for displaying device information in a table format
/// @mockable
protocol DeviceTableDisplaying: Sendable {
  /// Displays a single device in a table format
  func display(_ device: Device)

  /// Displays multiple devices in a table format
  func display(in runtime: RuntimeDeviceGroupOption)

  /// Displays devices with runtime information in a table format
  func display(_ devicesWithRuntime: [DeviceWithRuntime])
}

/// Component for displaying device information in a table format
struct DeviceTable: DeviceTableDisplaying {
  private let noora: any Noorable

  init(noora: any Noorable) {
    self.noora = noora
  }

  // MARK: - Table Display

  func display(_ device: Device) {
    noora.table(makeTableData(for: [device]))
  }

  func display(in runtime: RuntimeDeviceGroupOption) {
    precondition(!runtime.devices.isEmpty, "No devices to display")
    noora.table(makeTableData(for: runtime.devices))
  }

  func display(_ devicesWithRuntime: [DeviceWithRuntime]) {
    precondition(!devicesWithRuntime.isEmpty, "No devices to display")
    noora.table(makeTableData(for: devicesWithRuntime))
  }

  // MARK: - Table Data Generation

  private func makeTableData(for devices: [Device]) -> TableData {
    let columns = [
      DeviceTableColumn.name.column,
      DeviceTableColumn.state.column,
      DeviceTableColumn.udid.column,
      DeviceTableColumn.deviceTypeIdentifier.column,
    ]

    let rows: [TableRow] = devices.map { device in
      [
        TerminalText(stringLiteral: device.name),
        TerminalText(stringLiteral: device.state),
        TerminalText(stringLiteral: device.udid),
        TerminalText(stringLiteral: device.deviceTypeIdentifier),
      ]
    }
    return TableData(columns: columns, rows: rows)
  }

  private func makeTableData(for devicesWithRuntime: [DeviceWithRuntime]) -> TableData {
    let columns = [
      DeviceTableColumn.runtime.column,
      DeviceTableColumn.name.column,
      DeviceTableColumn.state.column,
      DeviceTableColumn.udid.column,
      DeviceTableColumn.deviceTypeIdentifier.column,
    ]
    let rows: [TableRow] = devicesWithRuntime.map { deviceWithRuntime in
      [
        TerminalText(stringLiteral: deviceWithRuntime.runtime),
        TerminalText(stringLiteral: deviceWithRuntime.device.name),
        TerminalText(stringLiteral: deviceWithRuntime.device.state),
        TerminalText(stringLiteral: deviceWithRuntime.device.udid),
        TerminalText(stringLiteral: deviceWithRuntime.device.deviceTypeIdentifier),
      ]
    }
    return TableData(columns: columns, rows: rows)
  }
}

/// Defines table columns for device display
private enum DeviceTableColumn: String, Sendable {
  case runtime = "Runtime"
  case name = "Name"
  case state = "State"
  case udid = "UDID"
  case deviceTypeIdentifier = "Device Type Identifier"

  var column: TableColumn {
    TableColumn(title: rawValue)
  }
}
