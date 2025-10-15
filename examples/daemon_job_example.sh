#!/usr/bin/env sh
# Example: start a worm in background mode, do some work, then stop it with a message.
# This script assumes you're running from the project root and have a working
# `bin/prg` script in the repository.

set -eu

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PRG_BIN="$PROJECT_ROOT/bin/prg"

echo "Starting worm in background mode (named 'example')..."
# Use --no-detach to keep it visible in the current terminal for demos
$PRG_BIN worm --daemon-as example --no-detach --message "Example running..." &

sleep 0.5

echo "Doing some work..."
sleep 2

echo "Stopping daemon with success message..."
$PRG_BIN job send --daemon-name example --message "Example finished" --checkmark

echo "Done."
