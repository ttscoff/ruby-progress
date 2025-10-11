# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.1] - 2025-10-11

### Fixed

- **Completion message display**: Fixed cursor positioning for success/error messages
  - Messages now display cleanly at the beginning of a new line
  - Affects all three commands: ripple, worm, and twirl
  - Resolves issue where completion messages appeared mid-line after animation ended
  - Improved professional appearance of CLI output

### Technical

- **Enhanced display_completion method**: Added proper line clearing and cursor positioning
  - Uses `\r\e[2K` sequence followed by clean message display
  - Updated test expectations to match new output format
  - Maintains backward compatibility with existing functionality

## [1.2.0] - 2025-10-11

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

### Enhanced

- **Centralized utility functions**: Moved common functionality to `RubyProgress::Utils`
  - `Utils.parse_ends()`: Universal start/end character parsing
  - Eliminates code duplication across animation classes
  - Consistent behavior and error handling

- **Documentation improvements**: Updated README with comprehensive examples
  - New common options section highlighting universal flags
  - Detailed --ends usage examples with various character patterns
  - Enhanced help output for all commands

### Technical

- **Version management**: Bumped all component versions to reflect new features
  - Main version: 1.1.9 → 1.2.0 (new feature addition)
  - Worm version: 1.0.4 → 1.1.0 (direction control + custom styles)
  - Ripple version: 1.0.5 → 1.1.0 (ends support)
  - Twirl version: 1.0.1 → 1.1.0 (ends support)

## [1.1.9] - 2025-10-10

### Fixed

- **Worm animation line clearing**: Resolved issue where completion messages appeared alongside animation characters
  - Fixed stream mismatch where animations used stderr but completion messages used stdout
  - Implemented atomic operation combining line clearing and message output on stderr
  - Ensured clean line clearing for all scenarios (success, error, no completion message)
  - Updated tests to match new stderr-based completion message output
  - Clean output format: animation disappears completely before completion message appears

### Technical

- **Stream consistency**: All worm animation output (including completion messages) now uses stderr consistently
- **Enhanced completion message display**: Single atomic stderr operation prevents race conditions between line clearing and message display

## [1.1.8] - 2025-10-10

### Added

- **Intelligent fuzzy matching for twirl styles**: Enhanced twirl style selector with sophisticated pattern matching
  - Exact matches: Direct style name matching (case-insensitive)
  - Prefix matches: `ar` matches `arc` instead of `arrow` (shortest match priority)
  - Character-by-character fuzzy matches: `cls` matches `classic` (sequential character matching)
  - Substring fallback: Comprehensive matching for partial inputs
  - Works dynamically against all available indicator styles in `RubyProgress::INDICATORS`

### Improved

- **Worm message spacing**: Enhanced visual formatting for worm animations
  - Automatic space insertion between `--message` text and animation
  - Clean formatting: `"Loading data ●··●·"` instead of `"Loading data●··●·"`
  - No extra spacing when no message is provided
  - Consistent behavior across all worm animation methods (standard, daemon, aggressive clearing)

### Technical

- **Enhanced test coverage**: Added comprehensive fuzzy matching test suite for twirl styles
  - 13 test cases covering exact, prefix, fuzzy, and edge case scenarios
  - Validation of shortest match priority and character-order matching
  - Integration with existing comprehensive test coverage (maintained at 70.47%)

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
- **Silent process management**: All `--stop` and `--stop-all` commands now operate silently
  - No status messages or confirmation output for cleaner automation
  - Exit code 0 when processes found and stopped successfully
  - Exit code 1 when no processes found to stop
- **Terminal output separation**: Moved all animations to stderr for proper stream handling
  - Animations and progress indicators use stderr (status information)
  - Application output remains on stdout (program data)
  - Fixes daemon mode output interruption issues
- **Enhanced process cleanup**: Improved daemon process termination reliability
  - Uses TERM signal first for graceful shutdown, followed by KILL if needed
  - Comprehensive process detection and cleanup across all subcommands
  - Better handling of orphaned processes
- **Version display**: Enhanced `--version` output to show individual subcommand versions
  - Main version: `prg version 1.1.7`
  - Component versions: `ripple (v1.0.5)`, `worm (v1.0.2)`, `twirl (v1.0.0)`
  - Enables tracking of individual component changes

### Technical

- **Test coverage**: Significantly improved test coverage from ~60% to 74.53%
  - Added comprehensive error handling tests
  - Enhanced daemon lifecycle testing
  - Improved edge case coverage for all animation types
  - Added version constant validation tests

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
