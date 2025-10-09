#!/bin/bash

# Example bash script using ruby-progress daemon mode
# This demonstrates how to use background progress indicators in shell scripts

set -e

echo "=== Bash Script with Background Progress Demo ==="
echo

# Configuration
PID_FILE="/tmp/bash_progress.pid"
PRG_BIN="$(dirname "$0")/../bin/prg"

# Clean up function
cleanup() {
	if [ -f "$PID_FILE" ]; then
		echo "Cleaning up progress indicator..."
		"$PRG_BIN" worm --stop-pid "$PID_FILE" 2>/dev/null || true
	fi
}

# Set up cleanup on exit
trap cleanup EXIT

echo "1. Starting background progress indicator..."
"$PRG_BIN" worm --daemon --pid-file "$PID_FILE" \
	--message "Processing multiple tasks..." \
	--success "All tasks completed successfully!" \
	--checkmark &

# Give daemon a moment to start
sleep 0.5

echo "2. Executing tasks with background progress..."

echo "   - Downloading files..."
sleep 2

echo "   - Processing data..."
sleep 2

echo "   - Generating reports..."
sleep 1

echo "   - Uploading results..."
sleep 1

echo "3. All tasks complete, stopping progress indicator..."
cleanup

echo
echo "=== Script Complete ==="

# Usage in your own scripts:
#
# # Start progress in background
# prg worm --daemon --pid-file /tmp/my_progress.pid \
#     --message "Working..." --success "Done!" --checkmark &
#
# # Do your actual work
# long_running_command_1
# long_running_command_2
# long_running_command_3
#
# # Stop progress indicator
# prg worm --stop-pid /tmp/my_progress.pid
