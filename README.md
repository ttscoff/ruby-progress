# Ruby Progress Indicators

[![Gem Version](https://badge.fury.io/rb/ruby-progress.svg)](https://badge.fury.io/rb/ruby-progress)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
<!-- [![RSpec Tests](https://github.com/ttscoff/ruby-progress/actions/workflows/rspec.yml/badge.svg)](https://github.com/ttscoff/ruby-progress/actions/workflows/rspec.yml) -->
[![Ruby](https://img.shields.io/badge/ruby-%3E%3D%202.5.0-ruby.svg)](https://www.ruby-lang.org/)
<!-- [![Coverage Status](https://img.shields.io/badge/coverage-31%25-yellow.svg)](#) -->

This repository contains a collection of Ruby progress indicator projects: **Ripple**, **Worm**, **Twirl**, and **Fill**. All provide animated terminal progress indicators with different visual styles and features.

## Table of Contents

- [Ruby Progress Indicators](#ruby-progress-indicators)
  - [Table of Contents](#table-of-contents)
  - [Unified Interface](#unified-interface)
    - [Global Options](#global-options)
    - [Stopping a backgrounded progress indicator](#stopping-a-backgrounded-progress-indicator)
      - [Job Control Subcommands](#job-control-subcommands)
  - [Example: background mode demo](#example-background-mode-demo)
  - [Ripple](#ripple)
    - [Ripple Features](#ripple-features)
    - [Ripple Usage](#ripple-usage)
      - [Ripple CLI examples](#ripple-cli-examples)
      - [Ripple Command Line Options](#ripple-command-line-options)
    - [Ripple Library Usage](#ripple-library-usage)
  - [Twirl](#twirl)
    - [Twirl Features](#twirl-features)
    - [Twirl Usage](#twirl-usage)
      - [Command Line](#command-line)
      - [Twirl Command Line Options](#twirl-command-line-options)
    - [Piped STDIN (no --command)](#piped-stdin-no--command)
    - [Available Spinner Styles](#available-spinner-styles)
  - [Worm](#worm)
    - [Worm Features](#worm-features)
    - [Worm Usage](#worm-usage)
      - [Command Line](#command-line-1)
      - [Daemon mode (background indicator)](#daemon-mode-background-indicator)
      - [Worm Command Line Options](#worm-command-line-options)
    - [Worm Library Usage](#worm-library-usage)
    - [Animation Styles](#animation-styles)
      - [Circles](#circles)
      - [Blocks](#blocks)
      - [Geometric](#geometric)
      - [Custom Styles](#custom-styles)
      - [Direction Control](#direction-control)
  - [Requirements](#requirements)
  - [Installation](#installation)
    - [As a Gem (Recommended)](#as-a-gem-recommended)
    - [From Source](#from-source)
    - [Development](#development)
  - [Universal Utilities](#universal-utilities)
    - [Terminal Control](#terminal-control)
    - [Completion Messages](#completion-messages)
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

### Stopping a backgrounded progress indicator

When running a backgrounded progress indicator (for example `prg worm --daemon`), you can send control signals using the `prg job` command with subcommands.

#### Job Control Subcommands

**Stop a running daemon:**

```bash
# Send a stop signal to the default daemon
prg job stop

# Send a stop signal to a named daemon (uses /tmp/ruby-progress/<name>.pid)
prg job stop --daemon-name mytask

# Send a stop signal with a completion message
prg job stop --daemon-name mytask --message "Deployment complete!"

# Send a stop signal with a checkmark
prg job stop --daemon-name mytask --message "Build successful" --checkmark

# Send a stop signal indicating an error
prg job stop --daemon-name mytask --message "Build failed" --error
```

**Check daemon status:**

```bash
# Check if a daemon is running
prg job status --daemon-name mytask

# Check status using a PID file
prg job status --pid-file /tmp/ruby-progress/mytask.pid
```

**Advance a progress indicator:**

```bash
# Advance progress by 1 (for indicators that support it)
prg job advance --daemon-name mytask

# Advance by a specific amount
prg job advance --daemon-name mytask --amount 10
```

**Backward Compatibility:**

The legacy `prg job send` command is still supported but deprecated. It functions identically to `prg job stop`:

```bash
# This still works but shows a deprecation warning
prg job send --daemon-name mytask --message "Complete!"
```

Alternatively, you can use the built-in `--stop` flags on the progress commands:

```bash
# Stop a named daemon with a success message
prg worm --stop-id demo --stop-success 'Task completed'

# Stop with an error message
prg worm --stop-id demo --stop-error 'Task failed'
```

## Example: background mode demo

Below is an example script that demonstrates starting a backgrounded progress indicator, doing work, and stopping it with a message.

```bash
# Start a named worm worker that runs in the background
prg worm --daemon-as demo

# Do some work in your script...
sleep 2

# Stop the worker with a success message
prg job stop --daemon-name demo --message "Demo finished" --checkmark
```

**Note:** Daemon mode automatically backgrounds the process using `Process.fork` and `Process.detach`, so you don't need to append `&`. The process detaches cleanly without shell job notifications.

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
| `--stdout-live`         | Stream piped input lines immediately to STDOUT                |
| `--daemon`              | Run in background daemon mode                                 |
| `--daemon-as NAME`      | Run in daemon mode with custom name                           |
| `--stop`                | Stop a running daemon                                         |
| `--stop-id NAME`        | Stop daemon by name (implies --stop)                          |
| `--status`              | Check daemon status                                           |
| `--status-id NAME`      | Check daemon status by name                                   |

### Piped STDIN (no --command)

All subcommands can animate while reading from STDIN when no `-c/--command` is provided. Output is printed only when `--stdout` is set. With `--stdout-live`, each incoming line is streamed immediately; otherwise lines are buffered and printed upon EOF.

Examples:

```bash
# Stream lines as they arrive (live); animation line is cleared before each print
rake generate | prg twirl --stdout --stdout-live
rake generate | prg ripple --stdout --stdout-live
rake generate | prg worm   --stdout --stdout-live
rake generate | prg fill   --stdout --stdout-live

# Buffer and print at the end (no interleaving during animation)
rake generate | prg twirl --stdout
```

Notes:
- Live streaming clears the animation line before each print to avoid prefix artifacts.
- Without `--stdout`, no piped content is printed; the indicator still animates until EOF.

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

### Capture and display command output or piped input
prg worm --command "git status" --message "Checking status" --stdout

# With piped input (no --command)
git log --oneline | prg worm --stdout --stdout-live

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
| `--stdout-live`         | Stream piped input lines immediately to STDOUT                |
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
