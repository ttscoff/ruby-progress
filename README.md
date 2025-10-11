# Ruby Progress Indicators

[![Gem Version](https://badge.fury.io/rb/ruby-progress.svg)](https://badge.fury.io/rb/ruby-progress)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![RSpec Tests](https://github.com/ttscoff/ruby-progress/actions/workflows/rspec.yml/badge.svg)](https://github.com/ttscoff/ruby-progress/actions/workflows/rspec.yml)
[![Ruby](https://img.shields.io/badge/ruby-%3E%3D%202.5.0-ruby.svg)](https://www.ruby-lang.org/)
[![Coverage Status](https://img.shields.io/badge/coverage-55%25-yellow.svg)](#)

This repository contains three different Ruby progress indicator projects: **Ripple**, **Worm**, and **Twirl**. All provide animated terminal progress indicators with different visual styles and features.

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

# With command execution
prg worm --command "sleep 5" --success "Completed!" --error "Failed!" --checkmark
prg ripple "Building..." --command "make build" --success "Build complete!" --stdout
prg twirl --command "npm install" --message "Installing packages" --style arc

# With start/end character decoration using --ends
prg ripple "Loading data" --ends "[]" --style rainbow
prg worm --message "Processing" --ends "()" --style blocks
prg twirl --message "Building" --ends "<<>>" --style dots

# Complex --ends patterns with emojis
prg worm --message "Magic" --ends "🎯🎪" --style "custom=🟦🟨🟥"
```

### Global Options

- `prg --help` - Show main help
- `prg --version` - Show version info
- `prg --list-styles` - Show all available styles for all subcommands
- `prg <subcommand> --help` - Show specific subcommand help

### Common Options (available for all subcommands)

- `--speed SPEED` - Animation speed (fast/medium/slow or f/m/s)
- `--message MESSAGE` - Message to display
- `--command COMMAND` - Command to execute during animation
- `--success MESSAGE` - Success message after completion
- `--error MESSAGE` - Error message on failure
- `--checkmark` - Show checkmarks (✅ success, 🛑 failure)
- `--stdout` - Output command results to STDOUT
- `--ends CHARS` - Start/end characters (even number of chars, split in half)

### Daemon Mode (Background Progress)

For shell scripts where you need a continuous progress indicator across multiple steps, use daemon mode. You can use named daemons or custom PID files.

```bash
# Start in background (uses default PID file)
prg worm --daemon --message "Working..."

# Start with a custom name (creates /tmp/ruby-progress/NAME.pid)
prg worm --daemon-as mytask --message "Processing data..."

# ... run your tasks ...

# Stop with a success message and checkmark (--stop-success implies --stop)
prg worm --stop-success "All done" --stop-checkmark

# Stop a named daemon (--stop-id implies --stop)
prg worm --stop-id mytask --stop-success "Task complete!" --stop-checkmark

# Or stop with an error message and checkmark
prg worm --stop-error "Failed during step" --stop-checkmark

# Check status at any time
prg worm --status
prg worm --status-id mytask

# Use a completely custom PID file path
prg worm --daemon --pid-file /tmp/custom-progress.pid
prg worm --status --pid-file /tmp/custom-progress.pid
prg worm --stop-success "Complete" --pid-file /tmp/custom-progress.pid
```

Notes:

- The CLI detaches itself (double-fork); do not append `&`. This prevents shell job notifications like “job … has ended.” The command returns immediately.
- `--stop-success` and `--stop-error` are mutually exclusive; whichever you provide determines the success state and icon if `--stop-checkmark` is set.
- The indicator clears its line on shutdown and prints the final message to STDOUT.
- `--stop-pid` is still supported for backward compatibility, but `--stop [--pid-file FILE]` is preferred.

## Table of Contents

- [Ruby Progress Indicators](#ruby-progress-indicators)
  - [Unified Interface](#unified-interface)
    - [Global Options](#global-options)
    - [Common Options (available for both subcommands)](#common-options-available-for-both-subcommands)
    - [Daemon Mode (Background Progress)](#daemon-mode-background-progress)
  - [Table of Contents](#table-of-contents)
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

---

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
# Basic text animation
prg ripple "Loading..."

# With style options
prg ripple "Processing Data" --speed fast --style rainbow --direction bidirectional

# Multiple styles combined
prg ripple "Loading..." --style rainbow,inverse

# Case transformation mode
prg ripple "Processing Text" --style caps,inverse

# Run a command with progress animation
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

# Simple progress block
result = RubyProgress::Ripple.progress("Processing...") do
  sleep 5  # Your actual work here
end

# With options
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
# Basic spinner animation
prg twirl --message "Processing..." --style dots

# With command execution
prg twirl --command "npm install" --message "Installing" --style arc

# Different spinner styles
prg twirl --message "Working" --style arrows --speed fast
prg twirl --message "Loading" --style blocks --speed slow

# With success/error handling
prg twirl --command "make build" --success "Build complete!" --error "Build failed!" --checkmark

# Daemon mode for background tasks
prg twirl --daemon --message "Background processing" --style geometric
prg twirl --daemon-as mytask --message "Named task" --style dots

# ... do other work ...
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
# Run indefinitely without a command (like ripple)
prg worm --message "Loading..." --speed fast --style circles

# Run a command with progress animation
prg worm --command "sleep 5" --message "Installing" --success "Done!"

# Customize the animation
prg worm --command "make build" --speed fast --length 5 --style blocks

# With custom error handling
prg worm --command "risky_operation" --error "Operation failed" --style geometric

# With checkmarks for visual feedback
prg worm --command "npm install" --success "Installation complete!" --checkmark

# Control animation direction (forward-only or bidirectional)
prg worm --message "Processing" --direction forward --style circles
prg worm --command "sleep 3" --direction bidirectional --style blocks

# Create custom animations with 3-character patterns
prg worm --message "Custom style" --style "custom=_-=" --command "sleep 2"
prg worm --message "Emoji worm!" --style "custom=🟦🟨🟥" --success "Complete!"
prg worm --message "Mixed chars" --style "custom=.🟡*" --direction forward

# Add start/end characters around the animation
prg worm --message "Bracketed" --ends "[]" --style circles
prg worm --message "Parentheses" --ends "()" --style blocks --direction forward
prg worm --message "Emoji ends" --ends "🎯🎪" --style "custom=🟦🟨🟥"

# Capture and display command output
prg worm --command "git status" --message "Checking status" --stdout

# Combine checkmarks and stdout output
prg worm --command "echo 'Build output'" --success "Build complete!" --checkmark --stdout
```

#### Daemon mode (background indicator)

Run the worm indicator as a background daemon and stop it later (useful in shell scripts):

```bash
# Start in the background (default PID file: /tmp/ruby-progress/progress.pid)
prg worm --daemon

# ... run your tasks ...

# Stop using the default PID file
prg worm --stop

# Use a custom PID file
prg worm --daemon --pid-file /tmp/custom-worm.pid

# Stop using the matching custom PID file
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

# Create and run animation with a block
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

# With custom style and forward direction
worm = RubyProgress::Worm.new(
  message: "Custom animation",
  style: 'custom=🔴🟡🟢',
  direction: :forward
)

result = worm.animate { sleep 3 }

# Or run with a command
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
# ASCII characters
prg worm --style "custom=_-=" --message "Custom ASCII"

# Unicode characters
prg worm --style "custom=▫▪■" --message "Custom geometric"

# Emojis (supports multi-byte characters)
prg worm --style "custom=🟦🟨🟥" --message "Color progression"

# Mixed ASCII and emoji
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

# Cursor control
RubyProgress::Utils.hide_cursor    # Hide terminal cursor
RubyProgress::Utils.show_cursor    # Show terminal cursor
RubyProgress::Utils.clear_line     # Clear current line
```

### Completion Messages

```ruby
# Basic completion message
RubyProgress::Utils.display_completion("Task completed!")

# With success/failure indication and checkmarks
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

# Clear line and display completion (useful for replacing progress indicators)
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
