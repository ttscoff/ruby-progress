# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.7] - 2025-10-10

### Added

- **Visual style previews**: Added `--show-styles` flag to all subcommands showing visual previews of animation styles
  - Global `prg --show-styles` displays all styles for all subcommands with visual examples  
  - Subcommand-specific `prg <subcommand> --show-styles` shows only relevant styles
  - Ripple styles show "Progress" text with actual color/effect rendering
  - Worm styles display wave patterns like `··●⬤●··` for circles style
  - Twirl styles show spinner character sequences like `◜ ◠ ◝ ◞ ◡ ◟` for arc style
- **Process management**: Added `--stop-all` flag for comprehensive process control
  - Global `prg --stop-all` stops all prg processes across all subcommands
  - Subcommand-specific `prg <subcommand> --stop-all` stops only processes for that animation type
  - Smart process detection excludes current process to prevent self-termination
  - Graceful termination using TERM signal for proper cleanup

### Improved

- **Error handling**: Replaced verbose Ruby stack traces with clean, user-friendly error messages
  - Invalid command-line options now show simple "Invalid option: --flag-name" messages
  - Each error includes appropriate usage information and help guidance
  - Consistent error format across all subcommands (ripple, worm, twirl)
- **Style discovery**: Enhanced distinction between `--list-styles` (simple name lists) and `--show-styles` (visual previews)

## [1.1.4] - 2025-10-09

### Fixed

- **Worm default message behavior**: Removed default "Processing" message from worm subcommand when no `--message` is provided for consistent behavior across all progress indicators
- **Development environment**: Fixed `bin/prg` to use local library files instead of installed gem versions during development

## [1.1.3] - 2025-10-09

### Fixed

- **Twirl spinner animation**: Fixed spinner freezing during command execution by ensuring continuous animation loop
- **Default message behavior**: Removed default "Processing" message when no `--message` is provided - now shows only spinner
- **Daemon termination output**: Removed verbose "Stop signal sent to process" message for cleaner daemon workflows

## [1.1.2] - 2025-10-09

### Fixed

- **Critical gem execution issue**: Fixed installed gem binaries not executing due to `__FILE__ == $PROGRAM_NAME` check failing when paths differ between gem binary location and RubyGems wrapper script

## [1.1.1] - 2025-10-09

### Added

- **New Twirl subcommand**: Extracted spinner functionality into dedicated `prg twirl` subcommand with 35+ spinner styles
- **Enhanced daemon management**: Added `--daemon-as NAME` for named daemon instances creating `/tmp/ruby-progress/NAME.pid`
- **Simplified daemon control**: Added `--stop-id NAME` and `--status-id NAME` for controlling named daemons
- **Automatic flag implications**: `--stop-success`, `--stop-error`, and `--stop-id` now automatically imply `--stop`
- **Global style listing**: Added `prg --list-styles` to show all available styles across all subcommands
- **Unified style system**: Replaced ripple's `--rainbow` and `--inverse` flags with `--style` argument supporting `--style rainbow,inverse`
- **Integrated case transformation**: Converted `--caps` flag to `--style caps` for consistent style system, supports combinations like `--style caps,inverse`

### Changed

- **Refactored CLI architecture**: Three-subcommand structure (ripple, worm, twirl) with consistent daemon management
- **Improved option parsing**: Eliminated OptionParser ambiguities by using explicit `--stop-id`/`--status-id` instead of optional arguments
- **Updated documentation**: Comprehensive README updates with new examples and cleaner daemon workflow syntax
- **Enhanced gemspec**: Updated description from "Two different animated progress indicators" to "Animated progress indicators"

### Deprecated

- **Ripple style flags**: `--spinner`, `--rainbow`, `--inverse`, and `--caps` flags deprecated in favor of unified `--style` system (backward compatibility maintained)

### Fixed

- **OptionParser conflicts**: Resolved parsing issues with optional arguments that could consume following flags
- **Daemon workflow**: Streamlined daemon start/stop workflow eliminating need for redundant flag combinations

## [1.0.1] - 2025-01-01

## [1.1.0] - 2025-10-09

### Added

- Shared daemon helpers module `RubyProgress::Daemon` for default PID file, control message file, status, and stop logic
- Unified daemon flags across ripple and worm: `--daemon`, `--status`, `--stop`, `--pid-file`, `--stop-success`, `--stop-error`, `--stop-checkmark`
- Ripple: daemon parity with worm, including clean shutdown on SIGUSR1/TERM/HUP/INT

### Changed

- `bin/prg` now delegates status/stop/default PID handling to `RubyProgress::Daemon`
- README updated with new daemon usage examples and flag descriptions

### Deprecated

- `--stop-pid` remains available but is deprecated in favor of `--stop [--pid-file FILE]`

### Added

- Packaged as proper Ruby gem with library structure
- Added RSpec test suite with comprehensive coverage
- Added Rake tasks for version management and packaging
- Added --checkmark and --stdout flags to Worm (ported from Ripple)
- Added infinite mode to Worm (runs indefinitely without command like Ripple)
- **Added unified `prg` binary with subcommands for both `ripple` and `worm`**
- **Enhanced command-line interface with consistent flag support across both tools**
- **Added `RubyProgress::Utils` module with universal terminal control utilities**
- **Centralized cursor control, line clearing, and completion message functionality**
- **Added daemon mode for background progress indicators in bash scripts**
- **Implemented signal-based control (SIGUSR1) for clean daemon shutdown**

### Changed

- Moved classes into RubyProgress module
- Separated logic into lib/ruby-progress/ structure
- Created proper bin/ executables for ripple and worm
- Updated README with gem installation and usage instructions

### Fixed

- Fixed duplicate error messages in Worm error handling
- Improved signal handling and cursor management

## [1.0.0] - 2025-10-09

### Added

- Initial release with two progress indicators:
  - Ripple: Text ripple animation with 30+ spinner styles, rainbow effects, and command execution
  - Worm: Unicode wave animation with multiple styles and configurable options
- Command-line interfaces for both tools
- Support for custom speeds, messages, and styling options
- Integration with system commands and process monitoring

[1.1.1]: https://github.com/ttscoff/ruby-progress/releases/tag/v1.1.1
[1.1.0]: https://github.com/ttscoff/ruby-progress/releases/tag/v1.1.0
[1.0.1]: https://github.com/ttscoff/ruby-progress/releases/tag/v1.0.1
[1.0.0]: https://github.com/ttscoff/ruby-progress/releases/tag/v1.0.0
