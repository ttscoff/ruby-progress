
# CHANGELOG

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 1.2.3 - 2025-10-11

### Added

- Dedicated `fill` shim: added `bin/fill` that delegates to `prg fill`.

### Changed

- Version bumps: prg 1.2.2 → 1.2.3, fill 1.0.0 → 1.0.1

## 1.2.2 - 2025-10-11

### Improved

- Demo script enhancements: updated quick demo with better visual examples.

### Technical

- Version alignment: synchronized demo script version display with actual gem version.
    - Messages now display cleanly at the beginning of a new line
    - Affects all three commands: ripple, worm, and twirl
    - Resolves issue where completion messages appeared mid-line after animation ended
    - Improved professional appearance of CLI output

Technical

- **Enhanced display_completion method**: Added proper line clearing and cursor positioning
    - Uses `re[2K` sequence followed by clean message display
    - Updated test expectations to match new output format
    - Maintains backward compatibility with existing functionality

## 1.2.0 - 2025-10-11

### Added

- **--ends flag for all commands**: New universal option to add start/end characters around animations
    - Accepts even-length strings split in half for start and end characters
    - Works across all three commands: ripple, worm, and twirl
    - Examples: `--ends "[]"` → `[animation]`, `--ends "<<>>"` → `<<animation>>`
    - Multi-byte character support for emojis: `--ends "🎯🎪"` → `🎯animation🎪`
    - Graceful fallback for invalid input (odd-length strings)

- **Comprehensive test coverage for new features**: Added extensive test suites
    - Direction control tests: Forward-only vs bidirectional animation behavior
    - Custom style tests: ASCII, Unicode, emoji, and mixed character pattern validation
    - CLI integration tests: End-to-end testing for all new command-line options
    - Ends functionality tests: Multi-byte character handling, error cases, help documentation
    - Total: 58 new test examples covering all edge cases

- **Worm direction control**: Fine-grained animation movement control
    - `--direction forward` (or `-d f`): Animation moves only forward, resets at end
    - `--direction bidirectional` (or `-d b`): Default back-and-forth movement
    - Compatible with all worm styles including custom patterns

- **Worm custom styles**: User-defined 3-character animation patterns
    - Format: `--style custom=abc` where `abc` defines baseline, midline, peak characters
    - ASCII support: `--style custom=_-=` → `___-=___`
    - Unicode support: `--style custom=▫▪■` → geometric patterns
    - Emoji support: `--style custom=🟦🟨🟥` → colorful animations
    - Mixed characters: `--style custom=.🟡*` → combined ASCII and emoji
    - Proper multi-byte character counting for accurate 3-character validation
- **Ripple style flags**: `--spinner`, `--rainbow`, `--inverse`, and `--caps` flags deprecated in favor of unified `--style` system (backward
compatibility maintained)

### Fixed

- **OptionParser conflicts**: Resolved parsing issues with optional arguments that could consume following flags
- **Daemon workflow**: Streamlined daemon start/stop workflow eliminating need for redundant flag combinations

## 1.0.1 - 2025-01-01

## 1.1.0 - 2025-10-09

### Added

- Shared daemon helpers module `RubyProgress::Daemon` for default PID file, control message file, status, and stop logic
- Unified daemon flags across ripple and worm: `--daemon`, `--status`, `--stop`, `--pid-file`, `--stop-success`, `--stop-error`,
`--stop-checkmark`
- Ripple: daemon parity with worm, including clean shutdown on SIGUSR1/TERM/HUP/INT

### Changed

- `bin/prg` now delegates status/stop/default PID handling to `RubyProgress::Daemon`
- README updated with new daemon usage examples and flag descriptions

Deprecated

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

## 1.0.0 - 2025-10-09

### Added

- Initial release with two progress indicators:
    - Ripple: Text ripple animation with 30+ spinner styles, rainbow effects, and command execution
    - Worm: Unicode wave animation with multiple styles and configurable options
- Command-line interfaces for both tools
- Support for custom speeds, messages, and styling options
- Integration with system commands and process monitoring


