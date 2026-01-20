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
- **Testing**: Write all new unit tests using the official Swift Testing framework.
- **Key Dependencies**:
    - **`swift-argument-parser`**: Implement command-line argument and subcommand parsing with [`swift-argument-parser`](https://github.com/apple/swift-argument-parser) to ensure type safety.
    - **`swift-subprocess`**: Execute and manage external processes (specifically `xcrun`) using the [`swift-subprocess`](https://github.com/swiftlang/swift-subprocess) package.
    - **`Noora`**: Construct all interactive terminal UI elements, such as lists and prompts, with the [`Noora`](https://github.com/tuist/Noora) package.

## Coding Style and Linting

Adhere strictly to the project's established coding style and conventions. All generated code must be consistent with the rules defined in the following configuration files:

- **SwiftLint (`.swiftlint.yml`):** Follow all linting rules defined in this file. This includes conventions for naming, spacing, and identifying potential code smells.
- **SwiftFormat (`.swiftformat`):** Ensure all code is formatted according to the rules in this file. Pay close attention to line length, indentation, and import ordering. Before completing your work, assume a formatting pass will be run with SwiftFormat.
- **EditorConfig ([`.editorconfig`](../.editorconfig)):** Respect the basic text and whitespace settings defined here, such as indent style and size.

Your goal is to produce code that is indistinguishable from the existing code in the project. Avoid reformatting files or code sections that are unrelated to your immediate task.

## Build and Test Information

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
