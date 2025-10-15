# Job CLI Refactoring Summary

## Changes Made

Restructured `prg job` to use proper subcommands instead of being hardcoded to only send stop signals.

### Before
```bash
prg job send --daemon-name mytask --message "Done!"
```

### After
```bash
# Stop a daemon
prg job stop --daemon-name mytask --message "Done!"

# Check daemon status
prg job status --daemon-name mytask

# Advance a fill progress bar
prg job advance --daemon-name mybar --amount 10
```

## New Subcommands

1. **`prg job stop`** - Stop a running progress indicator
   - Options: `--daemon-name`, `--pid-file`, `--message`, `--checkmark`, `--error`
   - Replaces the old `prg job send` command

2. **`prg job status`** - Check if a daemon is running
   - Options: `--daemon-name`, `--pid-file`
   - Shows PID and running status

3. **`prg job advance`** - Advance a fill progress bar
   - Options: `--daemon-name`, `--pid-file`, `--amount`, `--total`
   - Sends control message to update progress
   - Uses USR2 signal to notify daemon

## Implementation Details

- **Main entry point**: `JobCLI.run(argv)` - dispatches to subcommands
- **Backward compatibility**: `prg job send` still works but shows deprecation warning
- **Control messages**: Uses JSON files (`.pid.msg`) to pass data to daemons
- **Signal handling**: USR2 for control messages, USR1/INT/TERM/HUP for stop
- **Silent operation**: No confirmation messages for script-friendly usage - 
  only daemon output is shown

## Files Modified

- `lib/ruby-progress/cli/job_cli.rb` - Complete rewrite with subcommands
- `bin/prg` - Updated to call `JobCLI.run` instead of `JobCLI.send`
- `DAEMON_MODE.md` - Updated documentation with new command syntax

## Testing

All three subcommands tested and working:
- ✅ `prg job stop` - Gracefully stops daemons
- ✅ `prg job status` - Shows daemon status
- ✅ `prg job send` - Backward compatibility with deprecation warning
- ⏳ `prg job advance` - Ready for implementation (requires daemon-side handling)

## Next Steps

To fully implement `job advance`, the fill daemon needs to:
1. Listen for USR2 signal
2. Read control message file on USR2
3. Parse JSON and update progress accordingly
