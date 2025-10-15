#!/usr/bin/env bash

# Test daemon mode
echo "Starting twirl daemon..."
./bin/prg twirl --daemon-as test_twirl &
sleep 2

echo "Checking if daemon is running..."
ps aux | grep "[p]rg twirl" || echo "No daemon found"

echo "Checking PID files..."
ls -la ~/.prg/*.pid 2>/dev/null || echo "No PID files found"

echo "Stopping daemon..."
./bin/prg job send --daemon-name test_twirl
sleep 1

echo "Checking if daemon stopped..."
ps aux | grep "[p]rg twirl" || echo "Daemon stopped successfully"
ls -la ~/.prg/*.pid 2>/dev/null || echo "PID files cleaned up"
