---
title: "Ruby Progress Indicators for Modern CLI Tools"
date: 2025-10-15 11:00
categories: [Ruby, CLI, Development Tools]
tags: [ruby, cli, progress, animation, terminal, daemon]
---
I've been playing around with progress bars in the terminal, and I think I've
created something genuinely useful.

Yes, I know there are multiple options
already available for this, but I wanted something specific: a Ruby library that
could be used for command-line scripting, with CLI executables that made it easy
to use when scripting in *any* language --- not just Ruby.

The result is `ruby-progress`, a gem that provides four different animated
progress indicators, each with its own visual style and use cases.

> If you're scripting in Ruby, I do highly recommend the TTY tools from [Piotr Murach](piotrmurach),
such as [tty-progress](https://github.com/piotrmurach/tty-progressbar/). Piotr's
TTY tools are much more elegant with a better Ruby API. `ruby-progress` is
designed more for use in other shell scripts than it is for detailed Ruby
scripting.
{:.tip}

{% gif /uploads/2025/10/ruby-progress.mp4 %}

## The Four Progress Indicators

Ripple
: creates a wave-like effect across text, with the characters rippling
through different visual states. It supports rainbow colors, inverse
highlighting, and case transformations. Perfect for text-heavy operations where
you want something more dynamic than a simple spinner.

Worm
: displays a moving dot pattern that crawls across the screen using
Unicode characters. It includes multiple styles (circles, blocks, geometric
shapes) and can move in any direction. Great for file operations, network
transfers, or any continuous background task.

Twirl
: provides classic spinning indicators with over 35 different spinner
styles --- from simple dots to complex geometric patterns. It's the most
traditional of the four, but with way more visual variety than typical spinners.

Fill : is the only determinate indicator in the bunch --- an actual progress bar
that shows completion percentage. It can be controlled via command execution or
updated programmatically through daemon control messages.

## Installation and Quick Start

Installation is straightforward:

```bash
gem install ruby-progress
```

All four indicators are available through a unified `prg` command:

```bash
# Basic usage
prg ripple "Processing files..."
prg worm --message "Loading..." --style blocks
prg twirl --message "Working..." --style dots --speed fast
prg fill --total 100 --report

# With command execution
prg ripple "Building..." --command "make build" --success "Build complete!" --checkmark
```

You can also use the individual commands directly: `ripple`, `worm`, `twirl`, and `fill`.

## The Killer Feature: Daemon Mode

Here's where things get interesting. All four indicators support daemon mode,
which lets you run a progress indicator in the background while your scripts
execute other commands. This is useful for complex workflows.

```bash
# Start a background spinner
prg worm --daemon-as deployment --message "Deploying application..."

# Execute your actual deployment steps
git push production main
kubectl apply -f manifests/
./run-migrations.sh

# Stop the spinner with a success message
prg job stop --daemon-name deployment --message "Deployment complete!" --checkmark
```

The daemon mode uses `Process.fork` and `Process.detach`, so there are no shell
job notifications cluttering your output. The progress indicator runs cleanly in
the background, providing visual feedback without interfering with your script's
execution.

### Keeping Output Clean

One of the challenges with daemon mode is preventing command output from
disrupting the animation. By default, when you run a progress indicator in
daemon mode, any STDOUT or STDERR output from commands executed in your script
will appear on the terminal and potentially mess up the animation display.

Ruby-progress handles this intelligently. When running in daemon mode, the
animation continues on its dedicated line while your commands execute. However,
if you want to see the output from those commands, you have options:

```bash
# Run command with animation, show output after completion
prg ripple "Building..." --command "make build" --stdout

# Stream output live while animation runs (reserves terminal rows)
prg worm "Installing..." --command "npm install" --stdout-live --output-lines 5

# Run daemon and manually capture output from your script commands
prg worm --daemon-as build --message "Building..."
make build > /tmp/build.log 2>&1
prg job stop --daemon-name build --message "Build complete!" --checkmark
cat /tmp/build.log
```

The `--stdout-live` flag is particularly useful --- it reserves a section of the
terminal to display live command output while the animation continues above or
below it. You control how many lines to reserve with `--output-lines` and where
they appear with `--output-position` (above or below the animation).

### Job Control Commands

The `prg job` command provides subcommands for controlling background indicators:

- `prg job stop` --- Stop a running daemon with an optional message
- `prg job status` --- Check if a daemon is running and show its PID
- `prg job advance` --- Update a fill progress bar by a specific amount

```bash
# Check if a daemon is running
prg job status --daemon-name mytask

# Advance a progress bar remotely
prg fill --daemon-as progress --total 100
prg job advance --daemon-name progress --amount 10

# Stop with error state
prg job stop --daemon-name mytask --message "Build failed!" --error
```

{% paywall "Library and advanced usage" %}

## Ruby Library Usage

While the CLI is great for shell scripting, the Ruby API is just as elegant:

```ruby
require 'ruby-progress'

# Block syntax with automatic cleanup
RubyProgress::Ripple.progress("Processing files...") do
  process_files
  upload_results
end

# Manual control for complex scenarios
worm = RubyProgress::Worm.new(
  message: "Custom task",
  style: 'blocks',
  speed: 'medium'
)

worm.animate do
  heavy_computation
  more_work
end

# Command execution with error handling
RubyProgress::Twirl.new(
  command: "bundle install",
  message: "Installing gems...",
  success: "Dependencies installed!",
  error: "Installation failed",
  checkmark: true
).run_with_command
```

## Advanced Features Worth Knowing

### Custom Styling and Icons

All indicators support custom success and error icons:

```bash
prg ripple "Deploying..." \
  --command "./deploy.sh" \
  --success "All systems go!" \
  --error "Houston, we have a problem" \
  --success-icon "🚀" \
  --error-icon "💥" \
  --checkmark
```

### Visual Customization

Ripple supports rainbow colors and multiple composable styles:

```bash
prg ripple "Processing" --style rainbow,inverse,caps
```

Worm has directional control and custom character sets:

```bash
prg worm --direction rtl --style "custom=🟦🟨🟥"
```

### Start/End Character Decoration

The `--ends` flag lets you wrap your progress indicator with decorative characters:

```bash
prg worm --message "Magic" --ends "🎯🎪" --style blocks
prg ripple "Loading data" --ends "[]" --style rainbow
```

### Output Capture

When running commands, you can capture and display output:

```bash
# Show command output after completion
prg ripple "Building..." --command "make build" --stdout

# Display live output with reserved terminal rows
prg worm --command "npm install" --output-lines 5 --output-position above
```
{% endpaywall %}

## Real-World Use Cases

**Deployment Scripts**: Show continuous progress during multi-step deployments
without blocking command output.

**Data Processing**: Provide visual feedback during long-running data imports or
transformations.

**Build Systems**: Integrate into Rake or Make tasks to show progress during compilation.

**CI/CD Pipelines**: Add visual indicators to pipeline scripts for better monitoring.

**System Administration**: Show progress during backups, database dumps, or file
synchronization.

## Try It Out

The easiest way to get started:

{% iterm "gem install ruby-progress" %}

{% iterm "prg ripple 'Hello, World!'" %}

Or check out the [GitHub repository](https://github.com/ttscoff/ruby-progress)
for full documentation, examples, and the complete API reference. The README
includes detailed guides for each indicator type and advanced usage patterns.

The gem is also available on
[RubyGems](https://rubygems.org/gems/ruby-progress), and the latest release
includes significant improvements to daemon mode handling and job control
commands.
