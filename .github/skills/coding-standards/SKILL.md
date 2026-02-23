---
name: coding-standards
description: 'Code style, naming conventions, documentation rules, and build/lint/format commands for isimctl. Use when writing new code, reviewing code style, fixing lint errors, running builds, formatting code, applying naming conventions for protocols or UI components, or checking documentation standards. Also use when writing or editing Markdown documents to ensure consistent style. Covers SwiftLint, SwiftFormat, EditorConfig, markdownlint, protocol naming, and Noora UI component naming.'
---

# Coding Standards

Code style rules, naming conventions, documentation guidelines, and build/lint/format commands for isimctl.

## When to Use This Skill

- Writing or reviewing Swift code in this project
- Writing or editing Markdown documents
- Fixing linting or formatting errors
- Naming new protocols, types, or UI components
- Writing documentation comments (DocC)
- Running build, lint, or format commands

## Coding Style and Linting

Adhere strictly to the project's established coding style. All generated code must be consistent with the rules defined in the following configuration files:

- **SwiftLint (`.swiftlint.yml`)**: Follow all linting rules. Includes conventions for naming, spacing, and identifying potential code smells.
- **SwiftFormat (`.swiftformat`)**: Ensure all code is formatted per the rules in this file. Key settings: 2-space indent, LF line breaks, max width 200, testable imports at bottom.
- **EditorConfig (`.editorconfig`)**: Respect text and whitespace settings — indent style (spaces), size (2), LF line endings, UTF-8 charset.

**Goal**: Produce code indistinguishable from the existing codebase. Avoid reformatting files or code sections unrelated to the immediate task.

## Markdown Linting

This project uses [markdownlint](https://github.com/DavidAnson/markdownlint) to enforce consistent Markdown style across all `.md` files (README, SKILL.md, custom instructions, etc.).

- **Configuration**: Rules are defined in `.markdownlint-cli2.yaml` at the repository root.
- **Lint command**: `markdownlint-cli2 "**/*.md"`

When writing or editing Markdown documents, ensure the output conforms to the rules in `.markdownlint-cli2.yaml`.

## Documentation

- **Language**: All documentation and inline comments must be written in English.
- **Content**: DocC should focus on the purpose and contract of the function or class from the perspective of its caller.
- **Rule**: Avoid documenting internal implementation details. Documentation should be brief and meaningful — explain *what* a component does, not *how*.

## Naming Conventions

### Protocol Naming

All mockable protocols follow suffix-based naming conventions based on semantic purpose.

**Default Pattern: `-ing` Suffix (Behavior/Action)**

Use when the protocol describes what a type *does* or what action it performs.

| Example | Meaning |
| --- | --- |
| `DeviceTableDisplaying` | Performs device table display |
| `DeviceSelectionPrompting` | Performs device selection prompting |
| `SimctlErrorAlerting` | Performs error alerting |
| `BootDeviceMessaging` | Performs boot device messaging |
| `Executing` | Performs command execution |

**Alternative Pattern: `-able` Suffix (Capability/Feature)**

Use when the protocol describes what a type *can do*. Aligns with Swift standard library conventions (`Codable`, `Equatable`).

| Example | Meaning |
| --- | --- |
| `Simctlable` | Has capability to perform simctl operations |
| `SimulatorOpenable` | Has capability to open simulators |

**Decision guideline:**
- "Does this protocol describe an action being performed?" → Use `-ing`
- "Does this protocol describe a capability or feature?" → Use `-able`

The `-ing` suffix is preferred as the default unless the protocol clearly represents a capability or feature.

### Noora UI Component Naming

Components wrapping Noora terminal UI elements:

- **Component name**: `<Domain><UIElement>` (e.g., `DeviceTable`, `SimctlErrorAlert`)
- **Protocol name**: `<Domain><UIElement>ing` (e.g., `DeviceTableDisplaying`, `SimctlErrorAlerting`)
- **File name**: `<Component>.swift`

**Rules:**
- Domain prefix describes the feature or responsibility (e.g., `Device`, `SimctlError`)
- Simple, direct name for UI element purpose (e.g., `Table`, `Prompt`, `Alert`, `Message`)
- Protocol names always append `-ing` suffix for UI components
- Avoid redundant suffixes like "Component" or "UI"

## Build and Development Commands

| Task | Command |
| --- | --- |
| Build project | `swift build --build-tests` |
| Run all tests | `swift test 2>&1` |
| Run specific tests | `swift test --filter <TestTargetName> 2>&1` |
| Regenerate mocks | `make gen-mocks` |
| Lint Swift code | `make lint` |
| Format Swift code | `make format` |
| Lint Markdown | `markdownlint-cli2 "**/*.md"` |

## Troubleshooting

| Issue | Solution |
| --- | --- |
| SwiftLint violation | Check `.swiftlint.yml` for the specific rule and fix accordingly |
| SwiftFormat changes unexpected code | Verify `.swiftformat` rules; avoid formatting unrelated files |
| markdownlint violation | Check `.markdownlint-cli2.yaml` for the specific rule and fix accordingly |
| Naming conflict | Apply protocol naming decision guideline above |
| Build failure | Run `swift build --build-tests` to see detailed errors |
