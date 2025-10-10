---
title: "More CLI Progress Indicators: The ruby-progress Gem"
date: 2025-10-10
categories: [Ruby, CLI, Development Tools]
tags: [ruby, cli, progress, animation, terminal]
---

[ripple]: https://brettterpstra.com/2025/06/30/ripple-an-indeterminate-progress-indicator/

# More CLI Progress Indicators: The ruby-progress Gem

The `ruby-progress` gem expands my previous work on [Ripple], adding 2 more indicator types and a new daemon mode to make it more useful in non-Ruby shell scripts.

## What is ruby-progress?

Ruby-progress provides animated progress indicators for command-line applications. Unlike traditional progress bars showing completion percentage, this gem focuses on continuous animations (indeterminate) that indicate activity - perfect for tasks with unpredictable completion times.

Three animation styles are available:

- **Ripple**: Wave-like effect across text
- **Worm**: Moving dot pattern that crawls across the screen
- **Twirl**: Classic spinning indicators with various symbols

## Quick Start

```bash
# Install
gem install ruby-progress

# Basic usage
ripple "Processing files..."
worm --message "Loading..." --speed fast
twirl --spinner dots
```

## Ruby Integration

```ruby
require 'ruby-progress'

# Block syntax with automatic cleanup
RubyProgress::Ripple.progress("Processing files...") do
  process_files
  upload_results
end

# Manual control
worm = RubyProgress::Worm.new(
  message: "Custom task",
  style: 'blocks',
  speed: 'medium'
)

worm.animate { heavy_computation }
```

## Daemon Mode - The Killer Feature

Run progress indicators in the background while your scripts execute:

```bash
# Start background indicator
worm --daemon --pid-file /tmp/progress.pid --message "Deploying..."

# Run your actual work
./deploy.sh
kubectl apply -f manifests/

# Stop with success message
worm --stop /tmp/progress.pid --message "Deploy complete!" --checkmark
```

This is incredibly useful for complex deployment scripts where you want continuous visual feedback without interrupting the main process.

There's a unified binary called `prg` that takes the three types as subcommands, e.g. `prg twirl --checkmark`. You can use any of them either way.

## Advanced Features

### Error Handling
```ruby
RubyProgress::Ripple.progress("Risky operation") do
  might_fail_operation
rescue StandardError => e
  # Automatically stops and shows error state
  puts "Failed: #{e.message}"
end
```

### Command Integration
```ruby
# Execute shell commands with progress
RubyProgress::Worm.new(
  command: "pg_dump mydb > backup.sql",
  success: "Backup complete!",
  error: "Backup failed"
).run_with_command
```

### Visual Customization
```ruby
# Rainbow colors and custom styling
RubyProgress::Ripple.progress("Colorful task",
  rainbow: true,
  speed: :fast,
  format: :forward_only
) do
  process_with_style
end
```

## Real-World Examples

### Deployment Script

```bash
#!/bin/bash
worm --daemon-as deploy --message "Deploying..." &

git push production main
kubectl rollout status deployment/app

worm --stop-id deploy --stop-success "Success!" --checkmark
```

### Data Processing
```ruby
def import_large_csv(file)
  RubyProgress::Ripple.progress("Importing #{File.basename(file)}...") do
    CSV.foreach(file, headers: true) { |row| User.create!(row.to_h) }
  end
end
```

### Rake Tasks
```ruby
task :backup do
  RubyProgress::Worm.new(
    command: "tar -czf backup.tar.gz app/",
    success: "Backup created successfully!"
  ).run_with_command
end
```

## Why ruby-progress?

- **Simple API**: Works in Ruby code and shell scripts
- **Visual Appeal**: Engaging animations beyond basic spinners
- **Unique Daemon Mode**: Background progress indicators
- **Production Ready**: 84.55% test coverage, 113 test examples, zero failures
- **Cross-Platform**: Linux, macOS, Windows support
- **Reliable**: Comprehensive error handling and edge case coverage

## Installation & First Steps

1. **Install**: `gem install ruby-progress`
2. **Test CLI**: `ripple "Hello World!"`
3. **Try in Ruby**:
   ```ruby
   require 'ruby-progress'
   RubyProgress::Ripple.progress("Testing...") { sleep 2 }
   ```

## Conclusion

Ruby-progress transforms boring CLI applications into engaging user experiences. Whether building deployment scripts, data processing tools, or utility commands, it provides the visual feedback users expect from modern command-line tools.

The daemon mode alone makes it worth trying - no other progress library offers this level of flexibility for complex workflows.

**Links:**
- [GitHub](https://github.com/ttscoff/ruby-progress)
- [RubyGems](https://rubygems.org/gems/ruby-progress)
- [Latest Release](https://github.com/ttscoff/ruby-progress/releases/latest)

*Make your CLI tools feel alive with ruby-progress!*
