---
name: write-unit-tests
description: 'Guide for writing unit tests in isimctl using Swift Testing and Mockolo. Use when asked to create tests, add test coverage, write test cases, generate stubs, fix failing tests, or work with mocks. Covers test planning, naming conventions, Given-When-Then pattern, mock argument verification, stub creation, and test-specific linting.'
---

# Write Unit Tests

Comprehensive guide for writing unit tests in isimctl using the Swift Testing framework and Mockolo-generated mocks.

## When to Use This Skill

- Writing new unit tests for any component
- Adding test coverage to existing code
- Creating test stubs or mock configurations
- Fixing or updating failing tests
- Setting up test infrastructure for a new module

## Prerequisites

- [Swift Testing](https://github.com/swiftlang/swift-testing) framework (not XCTest)
- [Mockolo](https://github.com/uber/mockolo) for mock generation
- Run `make gen-mocks` after adding/modifying `@mockable` protocols

## Test Target Structure

### Unit Test Targets (`Tests/<Module>Tests/`)

- Each source module has a corresponding test target (e.g., `Sources/IsimctlUI/` → `Tests/IsimctlUITests/`)
- **File placement**: `Sources/<Target>/<Path>/<File>.swift` → `Tests/<Target>Tests/<Path>/<File>Tests.swift`
  - Example: `DeviceSelectionPrompt.swift` in `Sources/IsimctlUI/Shared/` → `DeviceSelectionPromptTests.swift` in `Tests/IsimctlUITests/Shared/`
- Test files mirror the exact source directory structure with `Tests` suffix.

**Decision rule**: Use unit tests for business logic and UI components with mocked dependencies.

### Integration Tests (`Tests/SimctlKitIntegrationTests/`)

- Execute real `xcrun simctl` commands without mocks.

**Decision rule**: Use integration tests sparingly for critical simctl interactions requiring real system validation.

### Mock Targets (`Tests/<Module>Mocks/`)

- Auto-generated mocks from `@mockable` protocols via Mockolo.
- Location: `Tests/<Module>Mocks/<Module>Mocks.generated.swift`
- Run `make gen-mocks` after adding/modifying `@mockable` protocols.

**Decision rule**: Never edit mock files manually. Always regenerate with `make gen-mocks`.

## Test Planning

### Comprehensive Coverage

Before generating test code, identify all test scenarios covering normal cases, edge cases, and error handling paths. When asked to create a test pattern list, enumerate scenarios systematically based on code branches and conditions.

### Organized Structure

Group related test cases using MARK comments:

```swift
// MARK: - Normal Cases

// MARK: - Edge Cases

// MARK: - Error Handling
```

### Error Handling Tests

- **Simplicity Principle**: Unless the code under test handles multiple error types differently, write only one representative error handling test case.
- **Rationale**: If the implementation simply passes errors to another component (e.g., `errorAlert.show(error)`), testing each error variant separately adds no value.
- **Exception**: When error-specific logic exists (e.g., different recovery strategies per error type), test each path independently.

## Naming Conventions

### Test File and Struct Naming

All test files and test struct names must use the `Tests` suffix (plural form):

- **File naming**: `<TargetName>Tests.swift`
- **Struct naming**: `<TargetName>Tests`

```swift
// SimctlTests.swift
struct SimctlTests {
  // Test implementations
}
```

Rules:
- Replace `<TargetName>` with the name of the component, type, or functionality being tested
- The struct name and file name must match (excluding `.swift`)
- Use PascalCase for the component name
- Always append `Tests` (plural) as the suffix

### Test Case Naming

Test case names must start with the function name under test, followed by a description in camel case.

**Do not use the `displayName` parameter in the `@Test` attribute.** The function name itself should be descriptive enough.

Good:
```swift
@Test
func functionName_shouldDoSomethingWhenConditionIsMet() {
  // Test implementation
}
```

Bad (avoid this):
```swift
@Test("functionName_shouldDoSomethingWhenConditionIsMet")
func functionName_shouldDoSomethingWhenConditionIsMet() {
  // Test implementation
}
```

## Test Code Patterns

### Given-When-Then Pattern

Use the Given-When-Then structure for complex test scenarios:

```swift
// Given: Setup test data and mock behaviors
let device = Device(name: "iPhone 16 Pro")
mock.handler = { _ in device }

// When: Execute the code under test
let result = try await service.fetchDevice()

// Then: Verify expectations
#expect(result == device)
#expect(mock.fetchDeviceCallCount == 1)
```

- Use inline comments (`// Given:`, `// When:`, `// Then:`) to document intent
- Configure mock return values and behaviors using handler closures

### Argument Verification in Mock-Based Tests

When using Mockolo-generated mocks, verify that methods are called with the correct arguments:

- **Scope**: Focus argument verification primarily on **Normal Cases**. Edge cases and error handling tests may omit detailed argument checks.
- **Method**: Prefer **complete array equality checks**:

```swift
// Then: Verify method was called with correct arguments
#expect(simctl.listDevicesArgValues == ["booted"])
```

This ensures both the count and content of arguments match expectations.

## Test Data Generation (Stub)

Test data helpers are centralized in dedicated stub files within Mocks targets.

### Placement & Naming

- Location: `Tests/<Target>Mocks/Stub/`
- File naming: `<TypeName or FileName>+Stub.swift` (e.g., `RuntimeDeviceGroupOption+Stub.swift`, `SimulatorList+Stub.swift`)

### Implementation

```swift
extension TargetType {
  /// Creates a test stub with customizable parameters.
  static func stub(
    param1: String = "default",
    param2: Int = 0,
  ) -> Self {
    .init(param1: param1, param2: param2)
  }
}
```

### Guidelines

- Use extension methods on the target type (not top-level functions)
- Provide sensible defaults for all parameters
- Place in the Mocks target corresponding to the source layer

## Test-Specific Linting Exceptions

When writing test code, it is acceptable to disable specific SwiftLint rules:

- **`type_body_length`**: Test structs often exceed body length limits.
- **`file_length`**: Test files may grow large when covering all scenarios.

Add a `swiftlint:disable` comment at the top of the test file:

```swift
// swiftlint:disable type_body_length file_length

import Testing
@testable import YourModule
```

Only disable these rules when the violation is unavoidable and justified by comprehensive test coverage.

## Commands Reference

| Task | Command |
| --- | --- |
| Run all unit tests | `swift test 2>&1` |
| Run specific test target | `swift test --filter <TestTargetName> 2>&1` |
| Regenerate mocks | `make gen-mocks` |

## Troubleshooting

| Issue | Solution |
| --- | --- |
| Mock type not found | Run `make gen-mocks` after adding `@mockable` to the protocol |
| Test not discovered | Ensure test struct/function naming follows conventions above |
| Handler not called | Check that the mock's handler property is set before executing the code under test |
| argValues is empty | Verify the mock was injected correctly via the internal initializer |
