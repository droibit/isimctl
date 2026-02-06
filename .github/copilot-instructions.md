# Copilot Instructions for isimctl

## Summary

`isimctl` is a CLI tool written in Swift that acts as a wrapper for the `xcrun simctl list` command.   
Its primary goal is to provide an interactive and user-friendly way to browse and display formatted simulator information.

The name `isimctl` is derived from "interactive simctl".

## Environment & Compatibility

- **Development OS:** macOS
- **macOS Deployment Target:** 15.0 or later
- **Swift Version:** 6.0 or later

## Technical Stack and Architecture

- **Project Structure**: This project is a Swift Package managed entirely by SPM. The `Package.swift` manifest is the single source of truth for project structure, targets, and dependencies.
- **Language**: Leverage modern Swift 6 language features where they improve clarity and safety.
- **Concurrency**: Utilize Swift Concurrency (e.g., `async/await`, `Task`, `Actor`) for all asynchronous operations instead of older patterns like completion handlers.
- **Testing**: Write all new unit tests using the official [Swift Testing](https://github.com/swiftlang/swift-testing) framework.
- **Mocking**: Generate mocks for testing using [`Mockolo`](https://github.com/uber/mockolo).
- **Key Dependencies**:
    - **`swift-argument-parser`**: Implement command-line argument and subcommand parsing with [`swift-argument-parser`](https://github.com/apple/swift-argument-parser) to ensure type safety.
    - **`swift-subprocess`**: Execute and manage external processes (specifically `xcrun`) using the [`swift-subprocess`](https://github.com/swiftlang/swift-subprocess) package.
    - **`Noora`**: Construct all interactive terminal UI elements, such as lists and prompts, with the [`Noora`](https://github.com/tuist/Noora) package.

### Project Structure

The project follows a layered architecture with three main source targets and corresponding test infrastructure:

```
Isimctl (CLI Layer)
    ↓ depends on
IsimctlUI (UI Layer)
    ↓ depends on
SimctlKit (Core Layer)
```

#### Sources/ Directory Targets

**1. Isimctl** (Executable Target)

- **Responsibility**: CLI entry point with ArgumentParser integration. Minimal logic—delegates to IsimctlUI for implementation.
- **Location**: `Sources/Isimctl/`
- **When to use**: When adding command-line argument definitions or new subcommands.
- **Structure**:
  - `Isimctl.swift` - Main entry point with `@main`
  - `Commands/` - Subcommand definitions (e.g., `ListCommand.swift`)

**Decision rule**: Isimctl should only parse arguments and delegate to IsimctlUI. No business logic or UI rendering here.

**2. IsimctlUI** (Library Target)

- **Responsibility**: Interactive terminal UI components using Noora and command business logic.
- **Location**: `Sources/IsimctlUI/`
- **When to use**:
  - When adding terminal UI components (e.g. tables, prompts, messages)
  - When implementing command orchestration logic
  - When creating UI-specific data models or extensions
- **Structure**:
  - `Commands/<Feature>/` - Feature-based organization (e.g., `ListDevice/` contains all list-related UI components)
  - `Noora/` - Shared UI components and Noora wrapper
  - UI extensions use `+UI.swift` suffix (e.g., `SimulatorList+UI.swift`)

**Decision rule**: If code involves user interaction or Noora components, it belongs in IsimctlUI.

**3. SimctlKit** (Library Target)

- **Responsibility**: Core simctl wrapper, subprocess execution, and data models. Platform-agnostic and reusable.
- **Location**: `Sources/SimctlKit/`
- **When to use**:
  - When adding new simctl command wrappers
  - When adding data models for simctl JSON responses
  - When modifying subprocess execution logic
- **Structure**:
  - `Simctl.swift` - Main `Simctlable` protocol and implementation
  - `Xcrun/` - Subprocess execution layer (internal)

**Decision rule**: If code wraps `xcrun simctl` or defines platform-agnostic models, it belongs in SimctlKit. No UI dependencies allowed.

#### Tests/ Directory Targets

**1. IsimctlUITests** and **SimctlKitTests** (Unit Test Targets)

- **Responsibility**: Unit tests using Mockolo-generated mocks for isolated component testing.
- **Location**: `Tests/IsimctlUITests/` and `Tests/SimctlKitTests/`
- **File placement**: Mirror the source structure exactly:
  - Pattern: `Sources/<Target>/<Path>/<File>.swift` → `Tests/<Target>Tests/<Path>/<File>Tests.swift`
  - Example: `DeviceTable.swift` in `Sources/IsimctlUI/Commands/ListDevice/` → `DeviceTableTests.swift` in `Tests/IsimctlUITests/Commands/ListDevice/`

**Decision rule**: Use unit tests for business logic and UI components with mocked dependencies.

**2. SimctlKitIntegrationTests** (Integration Test Target)

- **Responsibility**: Integration tests executing real `xcrun simctl` commands without mocks.
- **Location**: `Tests/SimctlKitIntegrationTests/`
- **When to use**: When verifying actual simctl interaction and JSON parsing.

**Decision rule**: Use integration tests sparingly for critical simctl interactions requiring real system validation.

**3. IsimctlUIMocks and SimctlKitMocks** (Mock Targets)

- **Responsibility**: Auto-generated mocks from `@mockable` protocols via Mockolo.
- **Location**: `Tests/<Module>Mocks/<Module>Mocks.generated.swift`
- **Generation**: Run `make gen-mocks` after adding/modifying `@mockable` protocols

**Decision rule**: Never edit mock files manually. Always regenerate with `make gen-mocks`.

#### Key Development Patterns

**Protocol-Oriented Design**

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
- Component wraps external dependencies (Noora, Subprocess)

**Dependency Injection Pattern**

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
    deviceTable: any DeviceTableDisplaying
  ) {
    self.simctl = simctl
    self.deviceTable = deviceTable
  }
}
```

**File Organization Convention**

- Feature-based directories: Group related files under `Commands/<Feature>/`
- UI extensions: Use `<Type>+UI.swift` for UI-specific extensions of SimctlKit types
- Component files: One component per file, named after the component
- Test files: Mirror source structure with `Tests` suffix (e.g., `SimctlTests.swift`)

### Unit Testing Guidelines

When writing unit tests, follow these principles to ensure comprehensive coverage and maintainability:

#### Test Case Planning

- **Comprehensive Coverage**: Before generating test code, identify all test scenarios covering normal cases, edge cases, and error handling paths. When asked to create a test pattern list, enumerate scenarios systematically based on code branches and conditions.
- **Organized Structure**: Group related test cases using MARK comments (e.g., `// MARK: - Normal Cases`, `// MARK: - Edge Cases`, `// MARK: - Error Handling`).

#### Error Handling Tests

- **Simplicity Principle**: Unless the code under test handles multiple error types differently, write only one representative error handling test case.
- **Rationale**: If the implementation simply passes errors to another component (e.g., `errorAlert.show(error)`), testing each error variant separately adds no value.
- **Exception**: When error-specific logic exists (e.g., different recovery strategies per error type), test each path independently.

#### Argument Verification in Mock-Based Tests

- **Verify Call Arguments**: When using Mockolo-generated mocks, verify that methods are called with the correct arguments by inspecting `argValues` properties.
- **Scope of Verification**: Focus argument verification primarily on **Normal Cases**. Edge cases and error handling tests may omit detailed argument checks if they don't add meaningful value.
- **Verification Method**: Prefer **complete array equality checks** when applicable (e.g., `#expect(mock.methodArgValues == [expectedValue])`). This ensures both the count and content of arguments match expectations.
  - Example:
    ```swift
    // Then: Verify method was called with correct arguments
    #expect(simctl.listDevicesArgValues == ["booted"])
    ```

#### Test Code Patterns

- **Given-When-Then Pattern**: Use the Given-When-Then structure for complex test scenarios to improve readability:
  ```swift
  // Given: Setup test data and mock behaviors
  let device = makeDevice(name: "iPhone 16 Pro")
  mock.handler = { _ in device }

  // When: Execute the code under test
  let result = try await service.fetchDevice()

  // Then: Verify expectations
  #expect(result == device)
  #expect(mock.fetchDeviceCallCount == 1)
  ```
- **Clarity Through Comments**: Use inline comments (`// Then:`, `// Given:`) to explicitly document the intent of each test phase.
- **Mock Handler Setup**: Configure mock return values and behaviors using handler closures to simulate various scenarios.

## Code Style Guidelines

### Coding Style and Linting

Adhere strictly to the project's established coding style and conventions. All generated code must be consistent with the rules defined in the following configuration files:

- **SwiftLint (`.swiftlint.yml`):** Follow all linting rules defined in this file. This includes conventions for naming, spacing, and identifying potential code smells.
- **SwiftFormat (`.swiftformat`):** Ensure all code is formatted according to the rules in this file. Pay close attention to line length, indentation, and import ordering. Before completing your work, assume a formatting pass will be run with SwiftFormat.
- **EditorConfig ([`.editorconfig`](../.editorconfig)):** Respect the basic text and whitespace settings defined here, such as indent style and size.

Your goal is to produce code that is indistinguishable from the existing code in the project. Avoid reformatting files or code sections that are unrelated to your immediate task.

#### Test-Specific Linting Exceptions

When writing test code, it is acceptable to disable specific SwiftLint rules that are commonly violated due to the nature of comprehensive test coverage:

- **`type_body_length`**: Test structs often contain many test cases, naturally exceeding body length limits.
- **`file_length`**: Test files may grow large when covering all scenarios (normal cases, edge cases, error handling).

**How to disable rules in test files:**

Add a `swiftlint:disable` comment at the top of the test file, immediately after the file path comment:

```swift
// swiftlint:disable type_body_length file_length

import Testing
@testable import YourModule
```

**Guidelines**:

- Only disable these rules when the violation is unavoidable and justified by comprehensive test coverage.
- Do not disable other linting rules without a strong reason.
- Keep the disabled rules list minimal and explicit.

### Documentation

- **Language**: All documentation and inline comments must be written in English.
- **Content**: DocC should focus on the purpose and contract of the function or class from the perspective of its caller.
- **Rule**: Avoid documenting internal implementation details. The documentation should be brief and meaningful, explaining what a component does, not how it does it.

### Naming Conventions

#### Noora UI Component Naming

Components that wrap Noora terminal UI elements follow a consistent naming convention to ensure clarity and consistency across the codebase.

**Component Naming Pattern:**

- **Component name**: `<Domain><UIElement>` (e.g., `DeviceTable`, `DeviceSelectionPrompt`, `SimctlErrorAlert`)
- **Protocol name**: `<Domain><UIElement>ing` (e.g., `DeviceTableDisplaying`, `DeviceSelectionPrompting`, `SimctlErrorAlerting`)
- **File name**: `<Component>.swift` (e.g., `DeviceTable.swift`, `DeviceSelectionPrompt.swift`, `SimctlErrorAlert.swift`)

**Naming Rules:**

- Use a domain prefix that describes the feature or responsibility (e.g., `Device`, `SimctlError`)
- Use a simple, direct name for the UI element purpose (e.g., `Table`, `Prompt`, `Alert`, `Message`)
- Protocol names always append `-ing` suffix to indicate they describe capabilities
- Avoid redundant suffixes like "Component" or "UI"

#### Test File and Struct Naming

All test files and test struct names must use the `Tests` suffix (plural form) to align with Swift community conventions.

- **File naming**: `<TargetName>Tests.swift`
- **Struct naming**: `<TargetName>Tests`

Example:

```swift
// SimctlTests.swift
struct SimctlTests {
  // Test implementations
}
```

Naming Rules:
- Replace `<TargetName>` with the name of the component, type, or functionality being tested
- The struct name and file name must match (excluding the `.swift` extension)
- Use PascalCase for the component name
- Always append Tests (plural) as the suffix

#### Test Case Naming

Test case names must start with the function name under test, followed by a description in camel case.

**Do not use the `displayName` parameter in the `@Test` attribute.** The function name itself should be descriptive enough.

- Good Example: 
  ```swift
  @Test
  func functionName_shouldDoSomethingWhenConditionIsMet() {    
    // Test implementation
  }
  ```
- Bad Example (avoid this):
  ```swift
  @Test("functionName_shouldDoSomethingWhenConditionIsMet")
  func functionName_shouldDoSomethingWhenConditionIsMet() {
    // Test implementation
  }
  ```

## Build and Test Information

### Build Command

To build the project, run:

```bash
swift build --build-tests
```

### Mock Generation Command

This project uses [`Mockolo`](https://github.com/uber/mockolo) to generate mocks for testing.   
To regenerate all mock files, run:

```bash
make gen-mocks
```

### Local Test Commands

- To run the unit tests locally, use:
  ```bash
  swift test 2>&1
  ```
- To run a specific test case, use:
  ```bash
  swift test --filter <TestTargetName> 2>&1
  ```

Replace `<TestTargetName>` with the name of the test target or test case you want to run (e.g., `RuntimeDeviceGroupOptionTest`).

### Lint and Formatting Commands

You can use the following `make` commands to perform common development tasks:

- **Linting:** To check the code for style violations and potential errors, run:
  ```bash
  make lint
  ```

- **Formatting:** To automatically format the code according to the project's style guidelines, run:
  ```bash
  make format
  ```
