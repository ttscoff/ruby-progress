# Ruby Progress Indicators

This repository contains two different Ruby progress indicator projects: **Ripple** and **Worm**. Both provide animated terminal progress indicators with different visual styles and features.

## Table of Contents

- [Ruby Progress Indicators](#ruby-progress-indicators)
  - [Table of Contents](#table-of-contents)
  - [Ripple](#ripple)
    - [Ripple Features](#ripple-features)
    - [Ripple Usage](#ripple-usage)
      - [Command Line](#command-line)
      - [Ripple Command Line Options](#ripple-command-line-options)
    - [Ripple Library Usage](#ripple-library-usage)
    - [Available Spinners](#available-spinners)
  - [Worm](#worm)
    - [Worm Features](#worm-features)
    - [Worm Usage](#worm-usage)
      - [Command Line](#command-line-1)
      - [Worm Command Line Options](#worm-command-line-options)
    - [Worm Library Usage](#worm-library-usage)
    - [Animation Styles](#animation-styles)
      - [Circles](#circles)
      - [Blocks](#blocks)
      - [Geometric](#geometric)
  - [Requirements](#requirements)
  - [Installation](#installation)
  - [Contributing](#contributing)
  - [License](#license)

---

## Ripple

Ripple is a sophisticated text animation library that creates ripple effects across text strings in the terminal. It supports various animation modes including bidirectional movement, rainbow colors, spinners, and case transformations.

### Ripple Features

- **Text ripple animations** with customizable speed and direction
- **Rainbow color effects** that cycle through colors
- **30+ built-in spinner styles** (dots, arrows, blocks, etc.)
- **Multiple animation formats**: forward-only, bidirectional
- **Command execution** with animated progress display
- **Custom success/failure messages** with optional checkmarks
- **Case transformation modes** (uppercase/lowercase rippling)
- **Inverse highlighting** for different visual effects

### Ripple Usage

#### Command Line

```bash
# Basic text animation
./ripple "Loading..."

# With options
./ripple "Processing Data" --speed fast --rainbow --direction bidirectional

# Run a command with progress animation
./ripple "Installing packages" --command "sleep 5" --success "Installation complete!" --checkmark

# Use a spinner instead of text ripple
./ripple "Working" --spinner dots --spinner-pos before
```

#### Ripple Command Line Options

| Option                      | Description                                   |
| --------------------------- | --------------------------------------------- |
| `-s, --speed SPEED`         | Set animation speed (fast/medium/slow)        |
| `-r, --rainbow`             | Enable rainbow color mode                     |
| `-d, --direction DIRECTION` | Set animation format (forward/back-and-forth) |
| `-i, --inverse`             | Enable inverse highlighting mode              |
| `-c, --command COMMAND`     | Run a command during animation                |
| `--success MESSAGE`         | Message to display on successful completion   |
| `--fail MESSAGE`            | Message to display on error                   |
| `--checkmark`               | Show checkmark on completion                  |
| `--spinner TYPE`            | Use spinner animation instead of text ripple  |
| `--spinner-pos POSITION`    | Position spinner before or after message      |
| `--caps`                    | Enable case transformation mode               |
| `--stdout`                  | Output captured command result to STDOUT      |
| `--quiet`                   | Suppress all output                           |
| `--list-spinners`           | List all available spinner types              |

### Ripple Library Usage

You can also use Ripple as a Ruby library:

```ruby
require_relative 'ripple'

# Simple progress block
result = Ripple.progress("Processing...") do
  sleep 5  # Your actual work here
end

# With options
rippler = Ripple.new("Loading Data", {
  speed: :fast,
  format: :bidirectional,
  rainbow: true,
  spinner: :dots
})

Ripple.hide_cursor
while some_condition
  rippler.advance
end
Ripple.show_cursor
```

### Available Spinners

Ripple includes 30+ different spinner styles:

- **Classic**: `|`, `/`, `—`, `\`
- **Dots**: Various braille dot patterns (dots, dots_2, dots_3, etc.)
- **Arrows**: Arrow patterns and pulsing arrows
- **Blocks**: Block characters in different patterns
- **Geometric**: Circles, triangles, arcs
- **Progress bars**: Bounce, push, pulse effects
- **And many more!**

Use `./ripple --list-spinners` to see all available options.

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
# Run a command with progress animation
./worm.rb --command "sleep 5" --message "Installing" --success "Done!"

# Customize the animation
./worm.rb --command "make build" --speed fast --length 5 --style blocks

# With custom error handling
./worm.rb --command "risky_operation" --error "Operation failed" --style geometric
```

#### Worm Command Line Options

| Option                  | Description                                         |
| ----------------------- | --------------------------------------------------- |
| `-s, --speed SPEED`     | Animation speed (1-10, fast/medium/slow, or f/m/s)  |
| `-l, --length LENGTH`   | Number of dots to display                           |
| `-m, --message MESSAGE` | Message to display before animation                 |
| `--style STYLE`         | Animation style (blocks/geometric/circles or b/g/c) |
| `-c, --command COMMAND` | Command to run (required)                           |
| `--success TEXT`        | Text to display on successful completion            |
| `--error TEXT`          | Text to display on error                            |

### Worm Library Usage

```ruby
require_relative 'worm'

# Create and run animation with a block
worm = Worm.new(
  length: 4,
  message: "Processing",
  speed: 'fast',
  style: 'circles'
)

result = worm.animate(
  success: "Complete!",
  error: "Failed!"
) do
  # Your work here
  some_long_running_task
end

# Or run with a command
worm = Worm.new(command: "bundle install")
worm.run_with_command
```

### Animation Styles

Worm supports three built-in animation styles:

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

---

## Requirements

Both projects require:
- Ruby 2.5 or higher
- Terminal with Unicode support (for Worm)
- ANSI color support (for Ripple rainbow effects)

## Installation

1. Clone this repository
2. Make the scripts executable:
   ```bash
   chmod +x ripple worm.rb
   ```
3. Run directly or require as libraries in your Ruby projects

## Contributing

Feel free to submit issues and pull requests to improve either project!

## License

Both projects are provided as-is for educational and practical use.