---
name: add-new-command
description: 'Workflow for adding new CLI commands and subcommands to isimctl. Use when asked to create a new command, add a subcommand, implement a new CLI feature, or add a new user-facing operation. Covers Isimctl CLI layer (ArgumentParser), IsimctlUI command implementation, messaging, and registration checklist.'
---

# Add New Command

Step-by-step workflow for adding new CLI commands to isimctl, covering the Isimctl CLI layer (argument parsing) and IsimctlUI layer (command logic and UI).

## When to Use This Skill

- Adding a new CLI command or subcommand (e.g., `isimctl delete`, `isimctl rename`)
- Implementing a new user-facing operation end-to-end
- Extending existing commands with new flags or options

## Prerequisites

- Familiarity with the 5-layer architecture (see `copilot-instructions.md` for overview)
- `swift-argument-parser` for CLI definitions
- `Noora` package for terminal UI elements

## Step-by-Step Workflow

### Step 1: Create the CLI Command (Isimctl Layer)

Create a command file in `Sources/Isimctl/Commands/<CommandName>.swift`:

- Define an `AsyncParsableCommand` with `CommandConfiguration`
- Add flags/options as needed
- Delegate to IsimctlUI in the `run()` method

**Rule**: Isimctl should only parse arguments and delegate to IsimctlUI. No business logic or UI rendering here.

### Step 2: Register the Command

**REQUIRED** — Register the command in `Sources/Isimctl/Isimctl.swift`:

- Add `<CommandName>.self` to `CommandConfiguration.subcommands` array
- Without this step, the command will not be accessible via CLI

### Step 3: Verify Registration

Run `swift run isimctl --help` and confirm the new command appears in the list.

### Step 4: Implement Command Logic (IsimctlUI Layer)

Create a feature directory and command implementation:

**Directory structure**: `Sources/IsimctlUI/Commands/<Feature>/`

Required files:
- `<Feature>Command.swift` — Orchestration logic (main entry point from CLI)
- `<Feature>Message.swift` — Optional: command-specific user-facing messages

**Subdirectory placement rule**:
- Components used by **multiple commands** → `Sources/IsimctlUI/Shared/`
- Components used by a **single command** → `Sources/IsimctlUI/Commands/<Feature>/`

### Step 5: Apply Dependency Injection

All command implementations use dual initializers:

```swift
public struct FeatureCommand: Sendable {
  private let simctl: any Simctlable
  private let featureMessage: any FeatureMessaging

  // Public init - creates real dependencies
  public init(noora: any Noorable) {
    self.init(
      simctl: Simctl(),
      featureMessage: FeatureMessage(noora: noora)
    )
  }

  // Internal init - for testing with mocks
  init(
    simctl: any Simctlable,
    featureMessage: any FeatureMessaging,
  ) {
    self.simctl = simctl
    self.featureMessage = featureMessage
  }
}
```

### Step 6: Implement Messages

Create protocol-based message components for user-facing messages:

```swift
/// @mockable
protocol FeatureMessaging: Sendable {
  func showSuccess(_ device: Device)
}

struct FeatureMessage: FeatureMessaging {
  private let noora: any Noorable

  init(noora: any Noorable) {
    self.noora = noora
  }

  func showSuccess(_ device: Device) {
    noora.success(...)
  }
}
```

**Messaging principles** (isimctl uses a conversational tone):

- Use second-person questions to guide user actions
  - Preferred: `"Which device would you like to boot?"`
  - Avoid: `"Select a device"`, `"Select a device to boot"`
- Noora component usage:
  - `noora.success()` — Operation completed successfully
  - `noora.info()` — General information or alerts requiring user attention
  - `.alert()` — Important messages with optional `takeaways` for guidance

### Step 7: Generate Mocks and Write Tests

After adding `@mockable` protocols:

1. Run `make gen-mocks` to generate mock files
1. Write unit tests following project conventions (see `write-unit-tests` skill)

## Troubleshooting

| Issue | Solution |
| --- | --- |
| Command not shown in `--help` | Ensure Step 2 is completed — register in `Isimctl.swift` subcommands array |
| Build error in IsimctlUI | Check that `Package.swift` includes required dependencies for the IsimctlUI target |
| Mock not generated | Run `make gen-mocks` after adding `@mockable` annotation to protocols |
