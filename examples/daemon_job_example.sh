#!/usr/bin/env sh
# Example: start a worm daemon, send a job, wait for result, then stop.
# This script assumes you're running from the project root and have a working
# `bin/prg` script in the repository.

set -eu

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PRG_BIN="$PROJECT_ROOT/bin/prg"

echo "Starting worm daemon (named 'example')..."
# prg detaches in daemon mode so no & needed
$PRG_BIN worm --daemon-as example --message "Example daemon"

sleep 0.2

echo "Sending job and waiting for result..."
$PRG_BIN job send --daemon-name example --command "echo hello; sleep 0.1" --wait --timeout 10

sleep 0.1

echo "Stopping daemon with success message..."
$PRG_BIN worm --stop-success "Example finished" --stop-checkmark --daemon-name example

echo "Done."
