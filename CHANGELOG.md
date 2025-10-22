# CHANGELOG

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.3.7] - 2025-10-22

### Fixed

- PTY command spawning now executes via the user's login shell to support shell aliases/functions and ensure PATH customizations are honored.
  - Uses `ENV['SHELL']` when available (fallback `/bin/sh`).
  - `bash`/`zsh`/`sh`: `-lc` is used; `fish`: `-l -c` is used.
  - Resolves `Errno::ENOENT` when running commands like `-c 'r fast'` under `--stdout-live`.

### Changed

- Refactored output capture internals:
  - Introduced `RubyProgress::ShellExec.build_shell_argv` for shell argv construction.
  - Extracted terminal reservation to `RubyProgress::OutputUI.reserve_space`.
  - Reduced method complexity and addressed linter warnings without behavior changes.

## [1.3.6] - 2025-10-15

### Fixed

- **Interrupt handling**: Fixed Twirl and Worm CLIs to exit cleanly on Ctrl+C (SIGINT) without displaying backtraces
  - Added top-level `trap('INT')` handlers to both `twirl_cli.rb` and `worm_cli.rb`
  - Added `rescue Interrupt` clauses to Twirl runner methods for graceful cleanup
  - All four progress indicators (Ripple, Worm, Twirl, Fill) now have consistent interrupt handling
  - Properly clean up (show cursor, clear line) and exit with code 130 on interrupt

## [1.3.5] - 2025-10-15

### Added

- **Job CLI refactoring**: Restructured `prg job` command to use proper subcommands instead of hardcoded send behavior
  - `prg job stop` - Stop a running progress indicator (replaces `prg job send`)
  - `prg job status` - Check if a daemon is running and show its PID
  - `prg job advance` - Advance a fill progress bar by a specified amount
- Backward compatibility: `prg job send` still works but shows deprecation warning
- Silent operation for job commands - no confirmation messages, only daemon output shown
- Control message framework using JSON files and USR2 signal for daemon communication
- Comprehensive test coverage improvements (from 10.63% to 31.38%)
  - 119 new tests across 8 new spec files
  - Unit tests for CLI options modules (twirl, ripple, fill, worm)
  - Job CLI subcommand tests
  - Custom icon propagation tests

### Changed

- **Daemon mode improvements**: All CLI subcommands now consistently use `PrgCLI.backgroundize`
- Removed `--no-detach` option from all CLIs (backgrounding is now always used)
- Fixed `backgroundize` method to use `Process.detach()` preventing shell job notifications
- Ripple completion messages now go to stderr (animation output stream) instead of stdout
- Enhanced `Utils.display_completion` to show custom icons even without checkmark flag
- Updated README with new job CLI subcommand documentation
- Updated documentation (DAEMON_MODE.md, JOB_CLI_REFACTOR.md)

### Fixed

- Ripple CLI tests updated to check stderr for completion messages (not stdout)
- Ripple CLI tests updated to require `--stdout` flag to see command output
- Output capture compatibility for older Ruby versions (added `wait_readable` fallback)
- Fixed daemon PID file cleanup and signal handling
- Custom success/error icons now display correctly with `--success-icon` and `--error-icon` flags

### Removed

- `--no-detach` option from all progress indicator CLIs (ripple, worm, twirl, fill)
- Confirmation output from job control commands for script-friendly silent operation

## 1.3.4 - 2024-10-14

### Fixed

- Output capture: ensure `--output-lines N` is honored when reserving terminal rows for captured output; coerce the `lines` option to an integer and stabilize the reserve/redraw logic so live captured output does not overwrite the prompt or animation.

### Changed

- Prepared for next patch release.

## 1.3.4 - 2025-10-14

### Fixed

- Ensure non-live (`--stdout`) capture does not stream output to the terminal during animation; captured output is now emitted at completion only.
- Stabilized PTY-based output capture redraw/reserve logic and cursor save/restore fallback.

### Changed

- Bumped main gem `VERSION` to 1.3.4.
- Cleaned up one-off debug/init traces written during development.

## 1.3.3 - 2025-10-14

### Fixed

- Output capture: ensure `--output-lines N` is honored when reserving terminal rows for captured output; coerce the `lines` option to an integer and stabilize the reserve/redraw logic so live captured output does not overwrite the prompt or animation.

### Changed

- Removed one-off init trace writes and cleaned debug logging.

## 1.3.2 - 2025-10-13

### Added

- `fill` subcommand: added `-c, --command COMMAND` so the determinate progress bar can run and capture command output like the other subcommands. This includes `--output-lines` and `--output-position` support for reserving terminal rows during capture.

### Changed

- Added `--stop-id NAME` shorthand for targeting named daemons (implies `--stop` and normalizes the name to the canonical PID filename). This is a small convenience used by the demo and scripts.
- Demo: updated `demo_screencast.rb` to call the local `bin/prg` when stopping the demo daemon to avoid conflicts with system-installed versions.

## 1.2.4 - 2025-10-12

### Added

- Small bug fixes and test stability improvements; ensured SimpleCov finalization runs reliably across Ruby versions during tests and minor CLI help clarifications.

## 1.2.3 - 2025-10-11

### Added

- Dedicated `fill` shim: added `bin/fill` that delegates to `prg fill`.

## 1.2.2 - 2025-10-11

### Improved

- Demo script enhancements: updated quick demo with better visual examples.

## 1.2.0 - 2025-10-11

### Added

- `--ends` flag for all commands and lots of smaller UX and testing improvements.

## 1.1.0 - 2025-10-09

### Added

- Shared daemon helpers module `RubyProgress::Daemon` and unified daemon flags across ripple and worm.

## 1.0.0 - 2025-10-09

### Added

- Initial release with two progress indicators (Ripple and Worm) and basic CLI tooling.


## 1.0.1 - 2025-01-01


