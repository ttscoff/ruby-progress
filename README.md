# Ruby Progress Indicators

[![Gem Version](https://badge.fury.io/rb/ruby-progress.svg)](https://badge.fury.io/rb/ruby-progress)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![RSpec Tests](https://github.com/ttscoff/ruby-progress/actions/workflows/rspec.yml/badge.svg)](https://github.com/ttscoff/ruby-progress/actions/workflows/rspec.yml)
[![Ruby](https://img.shields.io/badge/ruby-%3E%3D%202.5.0-ruby.svg)](https://www.ruby-lang.org/)
[![Coverage Status](https://img.shields.io/badge/coverage-55%25-yellow.svg)](#)

This repository contains three different Ruby progress indicator projects: **Ripple**, **Worm**, and **Twirl**. All provide animated terminal progress indicators with different visual styles and features.

## Table of Contents

- [Unified Interface](#unified-interface)
  - [Submitting jobs to a running daemon](#submitting-jobs-to-a-running-daemon)
- [Job result schema](#job-result-schema)
- [Example: start a daemon and send a job (simple)](#example-start-a-daemon-and-send-a-job-simple)
- [Ripple](#ripple)
  - [Ripple Features](#ripple-features)
  - [Ripple Usage](#ripple-usage)
- [Twirl](#twirl)
- [Worm](#worm)
  - [Daemon mode (background indicator)](#daemon-mode-background-indicator)
- [Requirements](#requirements)
- [Installation](#installation)
- [Universal Utilities](#universal-utilities)
  - [Terminal Control](#terminal-control)
  - [Completion Messages](#completion-messages)
- [Development](#development)
- [Contributing](#contributing)
- [License](#license)

## Unified Interface

The gem provides a unified `prg` command that supports all progress indicators through subcommands:

```bash
# Install the gem
gem install ruby-progress

# Use worm-style animation
prg worm --message "Processing data" --style blocks --checkmark

# Use ripple-style animation
prg ripple "Loading..." --style rainbow --speed fast

# Use twirl spinner animation
prg twirl --message "Working..." --style dots --speed fast

# Dedicated `fill` shim
# If you prefer a dedicated binary for the determinate progress bar, a thin `fill` shim is available that delegates to `prg fill`:

# Run fill directly (delegates to prg)
fill --report --percent 50

### With command execution
prg worm --command "sleep 5" --success "Completed!" --error "Failed!" --checkmark
prg ripple "Building..." --command "make build" --success "Build complete!" --stdout
prg twirl --command "npm install" --message "Installing packages" --style arc
prg fill --command "sleep 5" --success "Done!" --checkmark

### With start/end character decoration using --ends
prg ripple "Loading data" --ends "[]" --style rainbow
prg worm --message "Processing" --ends "()" --style blocks
prg twirl --message "Building" --ends "<<>>" --style dots

### Complex --ends patterns with emojis
prg worm --message "Magic" --ends "🎯🎪" --style "custom=🟦🟨🟥"
```

### Global Options

- `prg --help` - Show main help

Notes:

- The CLI detaches itself (double-fork); do not append `&`. This prevents shell job notifications like “job … has ended.” The command returns immediately.
- `--stop-success` and `--stop-error` are mutually exclusive; whichever you provide determines the success state and icon if `--stop-checkmark` is set.
- The indicator clears its line on shutdown and prints the final message to STDOUT.
- `--stop-pid` is still supported for backward compatibility, but `--stop [--pid-file FILE]` is preferred.

### Submitting jobs to a running daemon

When running a long-lived daemon (for example `prg worm --daemon`), you can submit additional commands to run and have their output displayed without disrupting the animation using the `prg job send` helper.

Basic usage:

```bash
# Enqueue a command to the default daemon PID
prg job send --command "./deploy-step.sh"

# Enqueue to a named daemon (creates /tmp/ruby-progress/<name>.pid)
prg job send --daemon-name mytask --command "rsync -av ./dist/ user@host:/srv/app"

# Read command from stdin (useful in scripts)
echo "bundle exec rake db:migrate" | prg job send --stdin --daemon-name mytask

# Wait for the job result and print the job result JSON (default timeout 10s)
prg job send --daemon-name mytask --command "./deploy-step.sh" --wait --timeout 30
```

You can also send control/action jobs (no shell command) to a running daemon. These are JSON payloads with an `action` key handled by the daemon's job processor. The helper supports a few common actions:

```bash
# Send a simple 'advance' action (no value)
prg job send --daemon-name demo --advance

# Send a 'percent' action with a numeric value
prg job send --daemon-name demo --percent 42

# Example using `fill` as a named daemon and sending percent updates
```bash
# Start a named fill worker (non-detaching so animation remains visible)
prg fill --daemon-as demo --no-detach --output-lines 3 --output-position top

# Send percent updates to the named worker
prg job send --daemon-name demo --percent 10 --wait
prg job send --daemon-name demo --percent 50 --wait
prg job send --daemon-name demo --percent 100 --wait
```

# Or use the generic action/value pair
prg job send --daemon-name demo --action percent --value 42
```

Note about stopping named daemons:

You can target named daemons directly using the `--stop-id NAME` shorthand which implies `--stop` and targets the named daemon (it is normalized to the canonical daemon name used for the PID file). This is convenient for scripts and demos. Example:

```bash
# Stop a named fill worker with a success message
prg fill --stop-id demo --stop-success 'Demo finished'
```

Behavior and file layout:

- Jobs are written as JSON files into the daemon's job directory, which is derived from the daemon PID file. For example, a PID file `/tmp/ruby-progress/mytask.pid` maps to the job directory `/tmp/ruby-progress/mytask.jobs`.
- The CLI writes the job atomically by first writing a `*.json.tmp` temporary file and then renaming it to `*.json`.
- The daemon's job processor claims jobs atomically by renaming the job file to `*.processing`, writes a `*.processing.result` JSON file when finished, and moves processed jobs to `processed-*`.

This mechanism allows you to submit many commands to a single running indicator and have their output shown in reserved terminal rows while the animation continues.

## Job result schema

When a job is processed the daemon writes a small JSON result file next to the claimed job with the suffix `.processing.result` containing at least these keys:

- `id` - the job id (string)
- `status` - `"done"` or `"error"`
- `time` - epoch seconds when the job finished (integer)

Depending on the job handler, additional keys may be present:

- `exit_status` - the numeric process exit status (integer or nil if unknown)
- `output` - a string with the last captured lines of output (if available)
- `error` - an error message when `status` is `error`

Example:

```json
{
  "id": "8a1f6c1e-4b7a-4f2c-b0a8-9e9f1c2f1a2b",
  "status": "done",
  "time": 1634044800,
  "exit_status": 0,
  "output": "Step 1 completed\nStep 2 completed"
}
```

This file is intended for short messages and small captured output snippets (the CLI captures the last N lines). If you need larger logs, write them to a persistent file from the command itself and include a reference in the job metadata.

## Example: start a daemon and send a job (simple)

Below is an example script that demonstrates starting a worm daemon, sending a job, waiting for the result, and stopping the daemon.
---

If you want the background worker to continue writing to the same terminal (so you can visually watch the animation while your script continues), use the non-detaching background mode:

```bash
# Start a named worm worker that backgrounds but does not fully detach
prg worm --daemon-as demo --no-detach

# In the same script or a subsequent command, enqueue a job to that worker
prg job send --daemon-name demo --command "echo hello; sleep 1; echo done" --wait

# Stop the worker with a success message
prg worm --stop-id demo --stop-success "Demo finished"
```

Note: Non-detaching mode keeps the child process attached to the controlling TTY. That means both the worker and the invoking shell may write to the terminal and outputs can interleave.

## Ripple

Ripple is a sophisticated text animation library that creates ripple effects across text strings in the terminal. It supports various animation modes including bidirectional movement, and rainbow colors.

### Ripple Features

- **Text ripple animations** with customizable speed and direction
- **Style system** supporting rainbow colors and inverse highlighting
- **Multiple animation formats**: forward-only, bidirectional
- **Command execution** with animated progress display
- **Custom success/failure messages** with optional checkmarks
- **Case transformation modes** (uppercase/lowercase rippling)
- **Composable styles** using comma-separated values

### Ripple Usage

#### Ripple CLI examples

```bash
### Basic text animation
prg ripple "Loading..."

### With style options
prg ripple "Processing Data" --speed fast --style rainbow --direction bidirectional

### Multiple styles combined
prg ripple "Loading..." --style rainbow,inverse

### Case transformation mode
prg ripple "Processing Text" --style caps,inverse

### Run a command with progress animation
prg ripple "Installing packages" --command "sleep 5" --success "Installation complete!" --checkmark
```

#### Ripple Command Line Options

| Option                  | Description                                                     |
| ----------------------- | --------------------------------------------------------------- |
| `-s, --speed SPEED`     | Animation speed (1-10, fast/medium/slow, or f/m/s)              |
| `-d, --direction DIR`   | Animation direction (forward/bidirectional or f/b)              |
| `-m, --message MESSAGE` | Message to display before animation                             |
| `--style STYLES`        | Visual styles (rainbow, inverse, caps - can be comma-separated) |
| `-c, --command COMMAND` | Command to run (optional - runs indefinitely without command)   |
| `--success TEXT`        | Text to display on successful completion                        |
| `--error TEXT`          | Text to display on error                                        |
| `--checkmark`           | Show checkmarks (✅ for success, 🛑 for failure)                  |
| `--stdout`              | Output captured command result to STDOUT                        |

### Ripple Library Usage

You can also use Ripple as a Ruby library:

```ruby
require 'ruby-progress'

### Simple progress block
result = RubyProgress::Ripple.progress("Processing...") do
  sleep 5  # Your actual work here
end

### With options
rippler = RubyProgress::Ripple.new("Loading Data", {
  speed: :fast,
  format: :bidirectional,
  rainbow: true,
  spinner: :dots
})

RubyProgress::Ripple.hide_cursor
while some_condition
  rippler.advance
end
RubyProgress::Ripple.show_cursor
```

---

## Twirl

Twirl is a lightweight spinner animation system providing over 35 different spinner styles for terminal progress indication. It's perfect for showing indefinite progress during command execution.

### Twirl Features

- **35+ spinner styles** including dots, arrows, blocks, and geometric patterns
- **Flexible speed control** (1-10 scale or named speeds)
- **Command execution** with animated progress display
- **Daemon mode** for background progress indication
- **Custom success/failure messages** with optional checkmarks
- **Signal handling** for graceful shutdown and status updates

### Twirl Usage

#### Command Line

```bash
### Basic spinner animation
prg twirl --message "Processing..." --style dots

### With command execution
prg twirl --command "npm install" --message "Installing" --style arc

### Different spinner styles
prg twirl --message "Working" --style arrows --speed fast
prg twirl --message "Loading" --style blocks --speed slow

### With success/error handling
prg twirl --command "make build" --success "Build complete!" --error "Build failed!" --checkmark

### Daemon mode for background tasks
prg twirl --daemon --message "Background processing" --style geometric
prg twirl --daemon-as mytask --message "Named task" --style dots

### ... do other work ...
prg twirl --stop-success "Processing complete!"
prg twirl --stop-id mytask --stop-success "Task finished!"
```

#### Twirl Command Line Options

| Option                  | Description                                                   |
| ----------------------- | ------------------------------------------------------------- |
| `-s, --speed SPEED`     | Animation speed (1-10, fast/medium/slow, or f/m/s)            |
| `-m, --message MESSAGE` | Message to display before spinner                             |
| `--style STYLE`         | Spinner style (see --list-styles for all options)             |
| `-c, --command COMMAND` | Command to run (optional - runs indefinitely without command) |
| `--success TEXT`        | Text to display on successful completion                      |
| `--error TEXT`          | Text to display on error                                      |
| `--checkmark`           | Show checkmarks (✅ for success, 🛑 for failure)                |
| `--stdout`              | Output captured command result to STDOUT                      |
| `--daemon`              | Run in background daemon mode                                 |
| `--daemon-as NAME`      | Run in daemon mode with custom name                           |
| `--stop`                | Stop a running daemon                                         |
| `--stop-id NAME`        | Stop daemon by name (implies --stop)                          |
| `--status`              | Check daemon status                                           |
| `--status-id NAME`      | Check daemon status by name                                   |

### Available Spinner Styles

Twirl includes over 35 different spinner animations:

- **Dots**: `dots`, `dots_2`, `dots_3`, `dots_pulse`, `dots_scrolling`
- **Arrows**: `arrow`, `arrow_pulse`, `arrows`, `arrows_2`
- **Blocks**: `blocks`, `blocks_2`, `toggle`, `toggle_2`
- **Lines**: `line`, `line_2`, `pipe`, `vertical_bar`
- **Geometric**: `arc`, `circle`, `triangle`, `square_corners`
- **Classic**: `classic`, `bounce`, `push`, `flip`
- **And many more!**

Use `prg --list-styles` to see all available spinner options.

---

## Worm

Worm is a clean, Unicode-based progress indicator that creates a ripple effect using combining characters. It's designed for running commands with visual progress feedback.

### Worm Features

- **Ripple wave animation** using Unicode characters
- **Multiple visual styles** (circles, blocks, geometric)
- **Configurable speed** (1-10 scale or named speeds)
- **Customizable length** and messages
- **Command execution** with progress indication
- **Success/error message customization**
- **Proper signal handling** and cursor management

### Worm Usage

#### Command Line

```bash
### Run indefinitely without a command (like ripple)
prg worm --message "Loading..." --speed fast --style circles

### Run a command with progress animation
prg worm --command "sleep 5" --message "Installing" --success "Done!"

### Customize the animation
prg worm --command "make build" --speed fast --length 5 --style blocks

### With custom error handling
prg worm --command "risky_operation" --error "Operation failed" --style geometric

### With checkmarks for visual feedback
prg worm --command "npm install" --success "Installation complete!" --checkmark

### Control animation direction (forward-only or bidirectional)
prg worm --message "Processing" --direction forward --style circles
prg worm --command "sleep 3" --direction bidirectional --style blocks

### Create custom animations with 3-character patterns
prg worm --message "Custom style" --style "custom=_-=" --command "sleep 2"
prg worm --message "Emoji worm!" --style "custom=🟦🟨🟥" --success "Complete!"
prg worm --message "Mixed chars" --style "custom=.🟡*" --direction forward

### Add start/end characters around the animation
prg worm --message "Bracketed" --ends "[]" --style circles
prg worm --message "Parentheses" --ends "()" --style blocks --direction forward
prg worm --message "Emoji ends" --ends "🎯🎪" --style "custom=🟦🟨🟥"

### Capture and display command output
prg worm --command "git status" --message "Checking status" --stdout

You can reserve terminal rows for captured command output so the animation doesn't interleave with the script output. Use:

- `--output-position POSITION` — `above` (default) or `below` the animation
- `--output-lines N` — how many terminal rows to reserve for captured output (default: 3)

Examples:

prg worm --command "git status" --stdout --output-position above --output-lines 4

### Combine checkmarks and stdout output
prg worm --command "echo 'Build output'" --success "Build complete!" --checkmark --stdout
```

#### Daemon mode (background indicator)

Run the worm indicator as a background daemon and stop it later (useful in shell scripts):

```bash
### Start in the background (default PID file: /tmp/ruby-progress/progress.pid)
prg worm --daemon

### ... run your tasks ...

### Stop using the default PID file
prg worm --stop

### Use a custom PID file
prg worm --daemon --pid-file /tmp/custom-worm.pid

### Stop using the matching custom PID file
prg worm --stop --pid-file /tmp/custom-worm.pid
```

Stopping clears the progress line for clean output. You can also provide a success message and checkmark while stopping by sending SIGUSR1; the CLI handles cleanup automatically.

Note: You don’t need `&` when starting the daemon. The command detaches itself and returns right away, which also avoids “job … has ended” messages from your shell.

#### Worm Command Line Options

| Option                  | Description                                                |
| ----------------------- | ---------------------------------------------------------- |
| `-s, --speed SPEED`     | Animation speed (1-10, fast/medium/slow, or f/m/s)         |
| `-l, --length LENGTH`   | Number of dots to display                                  |
| `-m, --message MESSAGE` | Message to display before animation                        |
| `--style STYLE`         | Animation style (circles/blocks/geometric or custom=XXX)   |
| `--direction DIR`       | Animation direction (forward/bidirectional or f/b)         |
| `--ends CHARS`          | Start/end characters (even number of chars, split in half) |
| `-c, --command COMMAND` | Command to run (optional)                                  |
| `--success TEXT`        | Text to display on successful completion                   |
| `--error TEXT`          | Text to display on error                                   |
| `--checkmark`           | Show checkmarks (✅ for success, 🛑 for failure)             |
| `--stdout`              | Output captured command result to STDOUT                   |
| `--daemon`              | Run in background daemon mode                              |
| `--daemon-as NAME`      | Run in daemon mode with custom name                        |
| `--stop`                | Stop a running daemon                                      |
| `--stop-id NAME`        | Stop daemon by name (implies --stop)                       |
| `--status`              | Check daemon status                                        |
| `--status-id NAME`      | Check daemon status by name                                |

### Worm Library Usage

```ruby
require 'ruby-progress'

### Create and run animation with a block
worm = RubyProgress::Worm.new(
  length: 4,
  message: "Processing",
  speed: 'fast',
  style: 'circles',
  direction: :bidirectional
)

result = worm.animate(
  success: "Complete!",
  error: "Failed!"
) do
  # Your work here
  some_long_running_task
end

### With custom style and forward direction
worm = RubyProgress::Worm.new(
  message: "Custom animation",
  style: 'custom=🔴🟡🟢',
  direction: :forward
)

result = worm.animate { sleep 3 }

### Or run with a command
worm = RubyProgress::Worm.new(command: "bundle install")
worm.run_with_command
```

### Animation Styles

Worm supports three built-in animation styles plus custom patterns:

#### Circles

- Baseline: `·` (middle dot)
- Midline: `●` (black circle)
- Peak: `⬤` (large circle)

#### Blocks

- Baseline: `▁` (lower eighth block)
- Midline: `▄` (lower half block)
- Peak: `█` (full block)

#### Geometric

- Baseline: `▪` (small black square)
- Midline: `▫` (small white square)
- Peak: `■` (large black square)

#### Custom Styles

Create your own animation patterns using the `custom=XXX` format, where `XXX` is a 3-character pattern representing baseline, midline, and peak states:

```bash
### ASCII characters
prg worm --style "custom=_-=" --message "Custom ASCII"

### Unicode characters
prg worm --style "custom=▫▪■" --message "Custom geometric"

### Emojis (supports multi-byte characters)
prg worm --style "custom=🟦🟨🟥" --message "Color progression"

### Mixed ASCII and emoji
prg worm --style "custom=.🟡*" --message "Mixed characters"
```

The custom format requires exactly 3 characters and supports:
- ASCII characters
- Unicode symbols and shapes
- Emojis (properly handled as single characters)
- Mixed combinations of the above

#### Direction Control

Control the animation movement pattern:

- `--direction forward` (or `-d f`): Animation moves only forward
- `--direction bidirectional` (or `-d b`): Animation moves back and forth (default)

This works with all animation styles including custom patterns.

---

## Requirements

Both projects require:

- Ruby 2.5 or higher
- Terminal with Unicode support (for Worm)
- ANSI color support (for Ripple rainbow effects)

## Installation

### As a Gem (Recommended)

```bash
gem install ruby-progress
```

### From Source

1. Clone this repository
2. Build and install:

   ```bash
   bundle install
   bundle exec rake build
   gem install pkg/ruby-progress-*.gem
   ```

### Development

1. Clone the repository
2. Install dependencies:

   ```bash
   bundle install
   ```

3. Run tests:

   ```bash
   bundle exec rspec
   ```

## Universal Utilities

The gem provides universal utilities in the `RubyProgress::Utils` module for common terminal operations:

### Terminal Control

```ruby
require 'ruby-progress'

### Cursor control
RubyProgress::Utils.hide_cursor    # Hide terminal cursor
RubyProgress::Utils.show_cursor    # Show terminal cursor
RubyProgress::Utils.clear_line     # Clear current line
```

### Completion Messages

```ruby
### Basic completion message
RubyProgress::Utils.display_completion("Task completed!")

### With success/failure indication and checkmarks
RubyProgress::Utils.display_completion(
  "Build successful!",
  success: true,
  show_checkmark: true
)

RubyProgress::Utils.display_completion(
  "Build failed!",
  success: false,
  show_checkmark: true,
  output_stream: :stdout  # :stdout, :stderr, or :warn (default)
)

### Clear line and display completion (useful for replacing progress indicators)
RubyProgress::Utils.complete_with_clear(
  "Processing complete!",
  success: true,
  show_checkmark: true,
  output_stream: :stdout
)
```

These utilities are used internally by Ripple, Worm, and Twirl classes and are available for use in your own applications.

## Contributing

Feel free to submit issues and pull requests to improve either project!

## License

Both projects are provided as-is for educational and practical use.
