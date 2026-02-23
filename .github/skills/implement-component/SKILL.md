---
name: implement-component
description: 'Guide for implementing new components, protocols, services, and UI elements in isimctl. Use when asked to create a new struct, protocol, service, wrapper, error type, or Noora UI component. Covers target placement decisions, protocol-oriented design, dependency injection, error naming, and file organization across all five source targets.'
---

# Implement Component

Comprehensive guide for implementing new components in isimctl, covering target placement decisions, protocol design, dependency injection, and Noora UI integration.

## When to Use This Skill

- Creating a new struct, protocol, or service
- Adding a new wrapper for external tools or system commands
- Implementing a new Noora UI element (table, prompt, alert, message)
- Adding error types to existing or new targets
- Deciding which target a new file belongs in

## Target Placement Guide

### Sources/ Directory Targets

**1. Isimctl** (Executable Target — `Sources/Isimctl/`)

CLI entry point with ArgumentParser integration. Minimal logic — delegates to IsimctlUI.

- Structure: `Isimctl.swift` (main entry), `Commands/` (subcommand definitions)
- **Decision rule**: Isimctl should only parse arguments and delegate to IsimctlUI. No business logic or UI rendering here.

**2. IsimctlUI** (Library Target — `Sources/IsimctlUI/`)

Interactive terminal UI components using Noora and command business logic.

- `Shared/` — Reusable UI components shared across multiple commands
  - Noora library extensions following `<Type>+Shared.swift` pattern
  - One component per file, named after the component
- `Commands/<Feature>/` — Command-specific implementations
  - Pattern: `<Feature>Command.swift` and optional `<Feature>Message.swift`
  - Contains orchestration logic, feature-specific messages, and single-use UI components

**Decision rule**: Multiple commands use it → `Shared/` | Single command uses it → `Commands/<Feature>/`

**3. SimctlKit** (Library Target — `Sources/SimctlKit/`)

Core simctl wrapper and data models. Platform-agnostic and reusable.

- Main protocol and implementation (e.g., `Simctlable` protocol in `Simctl.swift`)
- Error types, data models for JSON responses, domain types (search terms, filters)

**Decision rule**: If code wraps `xcrun simctl` or defines platform-agnostic models, it belongs in SimctlKit. No UI dependencies allowed.

**4. SimulatorKit** (Library Target — `Sources/SimulatorKit/`)

macOS-specific simulator operations. Wraps macOS commands for simulator management.

- Protocol and implementation pairs (e.g., `SimulatorOpenable` in `OpenSimulator.swift`)

**Decision rule**: If code uses macOS-specific commands (like `open`) for simulator management, it belongs in SimulatorKit. Built on SubprocessKit for process execution.

**5. SubprocessKit** (Library Target — `Sources/SubprocessKit/`)

Subprocess execution abstraction wrapping swift-subprocess package. Provides `Executing` protocol for mockable command execution and `ExecutionError` for unified error handling.

- The swift-subprocess types (Executable, Arguments) are internal implementation details not exposed in the public API.

**Decision rule**: If code executes external processes via the Subprocess package, it belongs in SubprocessKit.

## Protocol-Oriented Design

All mockable components follow this pattern:

```swift
/// Protocol description
/// @mockable
protocol DeviceTableDisplaying: Sendable {
  func display(_ devices: [Device])
}

struct DeviceTable: DeviceTableDisplaying {
  private let noora: any Noorable

  init(noora: any Noorable) {
    self.noora = noora
  }

  func display(_ devices: [Device]) {
    // Implementation
  }
}
```

**When to create a protocol:**
- Component needs mocking for testing
- Component is a public API in SimctlKit
- Component wraps external dependencies (Noora, or provides abstraction over system tools)

## Dependency Injection Pattern

All components use dual initializers:

```swift
public struct ListDevicesCommand: Sendable {
  private let simctl: any Simctlable
  private let deviceTable: any DeviceTableDisplaying

  // Public init - creates real dependencies
  public init(noora: any Noorable) {
    self.init(
      simctl: Simctl(),
      deviceTable: DeviceTable(noora: noora)
    )
  }

  // Internal init - for testing with mocks
  init(
    simctl: any Simctlable,
    deviceTable: any DeviceTableDisplaying,
  ) {
    self.simctl = simctl
    self.deviceTable = deviceTable
  }
}
```

## Error Type Conventions

All targets follow a consistent error naming pattern:

- **Pattern**: `<ImplementationName>Error` (e.g., `Simctl` → `SimctlError`, `OpenSimulator` → `OpenSimulatorError`)
- **File naming**: Separate file as `<ErrorType>.swift`
- **Conformance**: All error types must conform to `LocalizedError` and `Equatable`

Example chain: `Simctlable` protocol → `Simctl` implementation → `SimctlError` error type

## Noora UI Component Naming

Components that wrap Noora terminal UI elements follow a consistent naming convention:

- **Component name**: `<Domain><UIElement>` (e.g., `DeviceTable`, `DeviceSelectionPrompt`, `SimctlErrorAlert`)
- **Protocol name**: `<Domain><UIElement>ing` (e.g., `DeviceTableDisplaying`, `DeviceSelectionPrompting`, `SimctlErrorAlerting`)
- **File name**: `<Component>.swift` (e.g., `DeviceTable.swift`)

**Naming rules:**
- Use a domain prefix that describes the feature or responsibility (e.g., `Device`, `SimctlError`)
- Use a simple, direct name for the UI element purpose (e.g., `Table`, `Prompt`, `Alert`, `Message`)
- Protocol names always append `-ing` suffix for UI components
- Avoid redundant suffixes like "Component" or "UI"

## File Organization Convention

- Feature-based directories: Group related files under `Commands/<Feature>/`
- Component files: One component per file, named after the component
- Test files: Mirror source structure with `Tests` suffix (e.g., `SimctlTests.swift`)

## Troubleshooting

| Issue | Solution |
| --- | --- |
| Unsure which target to use | Apply the decision rules above — each rule is a simple if-then check |
| Need to add a dependency | Update `Package.swift` — it is the single source of truth for targets and dependencies |
| Mock not generated after adding `@mockable` | Run `make gen-mocks` to regenerate all mock files |
| Error type not conforming | Ensure conformance to both `LocalizedError` and `Equatable` |
