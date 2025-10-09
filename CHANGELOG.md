# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

[1.1.0]: https://github.com/ttscoff/ruby-progress/releases/tag/v1.1.0
[1.0.1]: https://github.com/ttscoff/ruby-progress/releases/tag/v1.0.1
[1.0.0]: https://github.com/ttscoff/ruby-progress/releases/tag/v1.0.0