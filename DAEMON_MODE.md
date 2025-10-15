# Daemon Mode Usage

## Summary of Changes

We've simplified daemon mode to ALWAYS use backgrounding (not detaching). This means:

1. **The `--no-detach` option has been removed** (it's now the default behavior)
2. **Daemon mode backgrounds in the same terminal** so you can see the progress indicator while running other commands
3. **All CLI subcommands (twirl, ripple, worm, fill) now use `PrgCLI.backgroundize`** instead of conditionally using `daemonize`

## How to Use Daemon Mode

### Starting a background progress indicator

```bash
# Start a twirl spinner in the background
./bin/prg twirl --daemon-as my_task

# Start a ripple animation in the background  
./bin/prg ripple --daemon-as my_task

# Start a worm animation in the background
./bin/prg worm --daemon-as my_task

# Start a fill progress bar in the background
./bin/prg fill --daemon-as my_task --total 100
```

The indicator will appear in your terminal and remain visible while you 
continue working.

### Stopping a background indicator

```bash
# Stop with default message
./bin/prg job stop --daemon-name my_task

# Stop with custom message
./bin/prg job stop --daemon-name my_task --message "Task completed!"

# Stop with success checkmark
./bin/prg job stop --daemon-name my_task --message "Success!" --checkmark

# Stop with error state
./bin/prg job stop --daemon-name my_task --message "Failed" --error
```

### Checking daemon status

```bash
# Check if a daemon is running
./bin/prg job status --daemon-name my_task

# The PID file is stored at:
/tmp/ruby-progress/my_task.pid

# Or check the process manually:
ps aux | grep "prg twirl"
```

### Advancing a fill progress bar

```bash
# Advance by 1 (default)
./bin/prg job advance --daemon-name mybar

# Advance by a specific amount
./bin/prg job advance --daemon-name mybar --amount 10

# Advance and update total
./bin/prg job advance --daemon-name mybar --amount 5 --total 100
```

### Using in shell scripts

Daemons are designed to work cleanly in shell scripts with no extraneous 
output:

```bash
#!/usr/bin/env bash

# Start a background progress indicator
prg twirl --daemon-as build --message "Building..."

# Do your work
make build

# Stop the indicator
prg job stop --daemon-name build --message "Build complete!" --checkmark
```

The daemon will background silently with no shell job notifications, making 
it perfect for scripts and automation.

## Technical Details

- **`PrgCLI.backgroundize`**: Forks the process; parent detaches child and 
  exits (returning control to shell), child creates new process group with 
  `Process.setsid` but keeps stdin/stdout/stderr so output remains visible 
  on the TTY. The use of `Process.detach` prevents shell job notifications.
- **PID files**: Stored in `/tmp/ruby-progress/DAEMON_NAME.pid`
- **Signal handling**: Daemons listen for INT, USR1, TERM, and HUP signals 
  to gracefully stop; USR2 for control messages (advance, etc.)
- **Control messages**: `job` subcommands use signal + message file to pass 
  messages to the daemon
- **Shell scripting**: No shell job completion messages are emitted, making 
  daemons suitable for use in scripts

## Job Subcommands

The `prg job` command provides control over running progress indicators:

- **`stop`**: Gracefully stop a running indicator with optional message, 
  checkmark, or error state
- **`advance`**: Increment a fill progress bar (sends data via control 
  message file)
- **`status`**: Check if a daemon is running and show its PID

### Backward Compatibility

The old `prg job send` command still works but is deprecated. It now 
maps to `prg job stop` and displays a deprecation warning. Update your 
scripts to use `prg job stop` instead.

## Fixed Bug

The `backgroundize` method had a logic error where the child process would return immediately instead of continuing execution. This has been fixed - the child now properly executes the daemon code and writes the PID file.
