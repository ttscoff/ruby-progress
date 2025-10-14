# CHANGELOG

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 1.3.0 - 2025-10-12

### Added

- PTY-based output capture: `RubyProgress::OutputCapture` now allows running commands under a PTY, keeps a rolling buffer of the last N lines for live redraw, and optionally writes the full streamed output to a `log_path` file.
- File-based daemon job queue: `RubyProgress::Daemon.process_jobs` implements atomic job enqueue/claim/processing with `.processing.result` metadata files and processed-archive behavior.
- `prg job send` CLI helper: atomically writes jobs to daemon job dirs and supports `--wait` to poll for results, `--daemon-name`, `--pid-file`, `--stdin`, and `--timeout`.
- Integration of job processing into Ripple/Twirl/Worm daemon modes so a running daemon can accept and display job output without interrupting animations.
- CLI options for output handling: `--output-position` and `--output-lines` to reserve terminal rows for captured output.

### Changed

- Job result files now merge any Hash returned by the job handler into the `.processing.result` JSON (e.g., `exit_status`, `output`, `log_path`).

### Tests

- Added unit and integration tests covering job enqueueing, processing, and result persistence.

### Release notes

- Merge commit: 99d9c39 (squash-merge of feature/output-handling)

## Unreleased

### Fixed

- Output capture: ensure `--output-lines N` is honored when reserving terminal rows for captured output; coerce the `lines` option to an integer and stabilize the reserve/redraw logic so live captured output does not overwrite the prompt or animation.

### Changed

- Prepared for next patch release.

## 1.3.3 - 2025-10-14

### Fixed

- Output capture: ensure `--output-lines N` is honored when reserving terminal rows for captured output; coerce the `lines` option to an integer and stabilize the reserve/redraw logic so live captured output does not overwrite the prompt or animation.

### Changed

- Removed one-off init trace writes and cleaned debug logging. Bumped main gem `VERSION` to 1.3.3 during intermediate fixes.

## 1.3.2 - 2025-10-13

### Added

- `fill` subcommand: added `-c, --command COMMAND` so the determinate progress bar can run and capture command output like the other subcommands. This includes `--output-lines` and `--output-position` support for reserving terminal rows during capture.

### Changed

- Added `--stop-id NAME` shorthand for targeting named daemons (implies `--stop` and normalizes the name to the canonical PID filename). This is a small convenience used by the demo and scripts.
- Demo: updated `demo_screencast.rb` to call the local `bin/prg` when stopping the demo daemon to avoid conflicts with system-installed versions.

# CHANGELOG

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

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


