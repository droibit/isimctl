# isimctl

An interactive simulator management tool for macOS.

## Overview

`isimctl` provides an interactive and user-friendly way to manage Xcode simulators through a conversational terminal interface. Instead of remembering device UUIDs or runtime identifiers, `isimctl` guides you through simulator operations with intuitive prompts and selections.

## Features

- **Interactive Device Selection**: Browse and select simulators through guided prompts
- **Runtime Filtering**: Easily navigate between different iOS, iPadOS, watchOS, and tvOS versions
- **Conversational Interface**: User-friendly questions instead of complex command syntax
- **Device Operations**: Boot, list, and manage simulators (more commands coming soon)

## Installation

TBD

## Usage

### List Devices

Display all available simulators:

```bash
isimctl list
```

Filter by search term (e.g., "booted", "available"):

```bash
isimctl list booted
```

### Boot Device

Interactively select and boot a simulator:

```bash
isimctl boot
```

With confirmation prompt:

```bash
isimctl boot --confirm
```

## Architecture

`isimctl` is built on a layered architecture:

- **Isimctl** (CLI Layer): Command-line interface and argument parsing
- **IsimctlUI** (UI Layer): Interactive terminal UI components using Noora
- **SimulatorKit** (macOS Integration Layer): macOS-specific simulator operations (e.g., opening Simulator.app)
- **SimctlKit** (Core Layer): Pure wrapper for `xcrun simctl` commands
- **SubprocessKit** (Infrastructure Layer): Subprocess execution abstraction

While `isimctl` provides comprehensive simulator management capabilities, the codebase maintains clear architectural boundaries. The `SimctlKit` layer strictly wraps only `xcrun simctl` commands, while `SimulatorKit` handles macOS-specific operations such as opening Simulator.app using the `open` command. Both layers are built on `SubprocessKit` for process execution.

## Requirements

- macOS 15.0 or later
- Xcode (for simulator support)
- Swift 6.0 or later (for development)

## License

TBD
