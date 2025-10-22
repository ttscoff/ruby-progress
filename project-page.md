# Ruby Progress Indicators

[![Gem Version](https://badge.fury.io/rb/ruby-progress.svg)](https://badge.fury.io/rb/ruby-progress)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Ruby](https://img.shields.io/badge/ruby-%3E%3D%202.5.0-ruby.svg)](https://www.ruby-lang.org/)

A collection of Ruby progress indicator projects: **Ripple**, **Worm**,
**Twirl**, and **Fill**. All provide animated terminal progress indicators
with different visual styles and features.

## Quick Start

Install the gem:

{% iterm "gem install ruby-progress" %}

Use the unified interface:

{% iterm "prg worm --message 'Processing data' --style blocks --checkmark" %}

{% iterm "prg ripple 'Loading...' --style rainbow --speed fast" %}

{% iterm "prg twirl --message 'Working...' --style dots --speed fast" %}

## Unified Interface

The gem provides a unified `prg` command that supports all progress
indicators through subcommands. Run commands with progress animation:

{% iterm "prg worm --command 'sleep 5' --success 'Completed!' --error 'Failed!' --checkmark" %}

{% iterm "prg ripple 'Building...' --command 'make build' --success 'Build complete!' --stdout" %}

{% iterm "prg twirl --command 'npm install' --message 'Installing packages' --style arc" %}

[See the README for more CLI examples](https://github.com/ttscoff/ruby-progress/blob/main/README.md#ripple-cli-examples)

## Ripple

Sophisticated text animation library that creates ripple effects across
text strings in the terminal. Supports various animation modes including
bidirectional movement and rainbow colors.

**Key Features:**

- Text ripple animations with customizable speed and direction
- Style system supporting rainbow colors and inverse highlighting
- Multiple animation formats: forward-only, bidirectional
- Command execution with animated progress display

Basic text animation:

{% iterm "prg ripple 'Loading...'" %}

With style options:

{% iterm "prg ripple 'Processing Data' --speed fast --style rainbow --direction bidirectional" %}

Run a command with progress animation:

{% iterm "prg ripple 'Installing packages' --command 'sleep 5' --success 'Installation complete!' --checkmark" %}

[See the README for more Ripple CLI examples](https://github.com/ttscoff/ruby-progress/blob/main/README.md#ripple-cli-examples)

## Twirl

Lightweight spinner animation system providing over 35 different spinner
styles for terminal progress indication. Perfect for showing indefinite
progress during command execution.

**Key Features:**

- 35+ spinner styles including dots, arrows, blocks, and geometric patterns
- Flexible speed control (1-10 scale or named speeds)
- Command execution with animated progress display
- Daemon mode for background progress indication

Basic spinner animation:

{% iterm "prg twirl --message 'Processing...' --style dots" %}

With command execution:

{% iterm "prg twirl --command 'npm install' --message 'Installing' --style arc" %}

Different spinner styles:

{% iterm "prg twirl --message 'Working' --style arrows --speed fast" %}

[See the README for more Twirl CLI examples](https://github.com/ttscoff/ruby-progress/blob/main/README.md#twirl-usage)

## Worm

Clean, Unicode-based progress indicator that creates a ripple effect using
combining characters. Designed for running commands with visual progress
feedback.

**Key Features:**

- Ripple wave animation using Unicode characters
- Multiple visual styles (circles, blocks, geometric)
- Configurable speed and customizable length
- Command execution with progress indication
- Custom styles with 3-character patterns

Run indefinitely without a command:

{% iterm "prg worm --message 'Loading...' --speed fast --style circles" %}

Run a command with progress animation:

{% iterm "prg worm --command 'sleep 5' --message 'Installing' --success 'Done!'" %}

Custom animations with 3-character patterns:

{% iterm "prg worm --message 'Custom style' --style 'custom=_-=' --command 'sleep 2'" %}

{% iterm "prg worm --message 'Emoji worm!' --style 'custom=🟦🟨🟥' --success 'Complete!'" %}

[See the README for more Worm CLI examples](https://github.com/ttscoff/ruby-progress/blob/main/README.md#worm-usage)

## Background Mode

All progress indicators support daemon mode for background tasks:

Start a background indicator:

{% iterm "prg worm --daemon-as mytask --message 'Background processing'" %}

Stop it later with a message:

{% iterm "prg job stop --daemon-name mytask --message 'Task complete!' --checkmark" %}

[See the README for more background mode examples](https://github.com/ttscoff/ruby-progress/blob/main/README.md#example-background-mode-demo)

## Installation

As a gem (recommended):

{% iterm "gem install ruby-progress" %}

From source:

{% iterm "git clone https://github.com/ttscoff/ruby-progress.git" %}

{% iterm "cd ruby-progress" %}

{% iterm "bundle install" %}

{% iterm "bundle exec rake build" %}

{% iterm "gem install pkg/ruby-progress-*.gem" %}

[See the README for more installation options](https://github.com/ttscoff/ruby-progress/blob/main/README.md#installation)

## Requirements

- Ruby 2.7 or higher
- Terminal with Unicode support (for Worm)
- ANSI color support (for Ripple rainbow effects)

[See the README for complete documentation](https://github.com/ttscoff/ruby-progress/blob/main/README.md)
