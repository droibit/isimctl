# Copilot Instructions for isimctl

## Summary

`isimctl` is an interactive simulator management tool written in Swift.
Its primary goal is to provide an interactive and user-friendly way to browse and manage Xcode simulators through a conversational terminal interface.

The name `isimctl` is derived from "interactive simctl".

### Architectural Layers

The codebase maintains clear architectural boundaries across five layers:

- **SubprocessKit** (Infrastructure Layer): Subprocess execution abstraction with `Executing` protocol wrapping swift-subprocess.
- **SimulatorKit** (macOS Integration Layer): macOS-specific simulator operations (e.g., opening Simulator.app). Built on SubprocessKit.
- **SimctlKit** (Core Layer): Pure `xcrun simctl` command wrapper. Built on SubprocessKit.
- **IsimctlUI** (UI Layer): Interactive terminal UI and operation orchestration using Noora. Delegates to SimulatorKit and SimctlKit.
- **Isimctl** (CLI Layer): Command-line interface and argument parsing using swift-argument-parser.

## Environment & Compatibility

- **Development OS:** macOS
- **macOS Deployment Target:** 15.0 or later
- **Swift Version:** 6.0 or later

## Technical Stack and Architecture

- **Project Structure**: Swift Package managed entirely by SPM. `Package.swift` is the single source of truth.
- **Language**: Modern Swift 6 language features where they improve clarity and safety.
- **Concurrency**: Swift Concurrency (`async/await`, `Task`, `Actor`) for all asynchronous operations.
- **Testing**: [Swift Testing](https://github.com/swiftlang/swift-testing) framework for all new unit tests.
- **Mocking**: [Mockolo](https://github.com/uber/mockolo) for mock generation.
- **Key Dependencies**:
  - [`swift-argument-parser`](https://github.com/apple/swift-argument-parser): CLI argument and subcommand parsing.
  - [`swift-subprocess`](https://github.com/swiftlang/swift-subprocess): External process execution.
  - [`Noora`](https://github.com/tuist/Noora): Interactive terminal UI elements.

### Project Structure

```plaintext
Isimctl (CLI Layer)
    ↓ depends on
IsimctlUI (UI Layer)
    ↓ depends on (both)
SimulatorKit (macOS Integration) | SimctlKit (Core Layer)
    ↓                                ↓
    └────────────────────────────────┘
                    ↓
         SubprocessKit (Infrastructure Layer)
```

Use `list_dir` or `file_search` to discover current files rather than relying on documentation listings.

For detailed target responsibilities, decision rules, development patterns, naming conventions, testing guidelines, and build commands, refer to the Agent Skills in `.github/skills/`.
