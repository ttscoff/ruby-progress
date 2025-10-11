# Ruby Progress Gem - Demo Scripts

This directory contains three demo scripts designed to showcase the ruby-progress gem's features for different purposes.

## Demo Scripts Overview

### 1. `demo_screencast.rb` - Full Feature Demo
**Purpose**: Comprehensive screencast demonstration with narration pauses
**Duration**: ~10-15 minutes
**Best for**: Complete feature showcase, video recordings, presentations

**Features demonstrated**:
- All three commands (ripple, worm, twirl)
- Built-in styles and variations
- Universal --ends flag (NEW in v1.2.0)
- Worm direction control (NEW in v1.2.0)
- Custom worm styles (NEW in v1.2.0)
- Error handling and success messages
- Feature combinations

**Usage**:
```bash
./demo_screencast.rb
# or
ruby demo_screencast.rb
```

### 2. `quick_demo.rb` - Essential Features
**Purpose**: Quick demonstration of key features
**Duration**: ~3-5 minutes
**Best for**: Quick testing, feature highlights, social media clips

**Features demonstrated**:
- Universal --ends flag examples
- Custom worm styles with emoji
- Direction control
- Error handling
- Feature combinations

**Usage**:
```bash
./quick_demo.rb
# or
ruby quick_demo.rb
```

### 3. `readme_demo.rb` - Documentation Examples
**Purpose**: Clean examples perfect for README and documentation
**Duration**: Variable (can run sections independently)
**Best for**: Creating documentation examples, README updates, tutorials

**Features demonstrated**:
- Basic usage examples
- Style variations
- New v1.2.0 features
- Advanced features

**Usage**:
```bash
# Run all examples
./readme_demo.rb

# Run specific sections
./readme_demo.rb basic      # Basic usage only
./readme_demo.rb styles     # Style variations only
./readme_demo.rb new        # New v1.2.0 features only
./readme_demo.rb advanced   # Advanced features only
```

## Customization Tips

### Adjusting Sleep Times
All scripts use `--command 'sleep X'` to simulate work. You can adjust timing by modifying the sleep values:

- **Ripple**: 3-4 seconds shows the expanding animation well
- **Worm**: 4-6 seconds demonstrates the full progress bar cycle
- **Twirl**: 2-3 seconds is sufficient for spinner animations

### Adding Your Own Examples
To add new examples, follow this pattern:

```ruby
def your_demo_method
  puts "Description of what this demonstrates:"
  run_cmd("command --option 'value' --command 'sleep X' --success 'Message!'")
  puts "\n"
end
```

### Modifying Pauses
In `demo_screencast.rb`, you can adjust pause durations:

```ruby
pause_for_narration(seconds)    # For narration breaks
pause_between_demos(seconds)    # Between demonstrations
```

## Example Commands Demonstrated

### Universal --ends Flag
```bash
prg ripple 'Loading...' --ends '[]' --command 'sleep 3' --success 'Complete!'
prg worm --length 10 --ends '<<>>' --command 'sleep 4' --success 'Finished!'
prg twirl --ends '🎯🎪' --command 'sleep 2' --success 'Done!'
```

### Custom Worm Styles
```bash
prg worm --length 10 --style custom=_-= --command 'sleep 4' --success 'ASCII style!'
prg worm --length 10 --style custom=▫▪■ --command 'sleep 4' --success 'Unicode blocks!'
prg worm --length 10 --style custom=🟦🟨🟥 --command 'sleep 4' --success 'Emoji colors!'
```

### Direction Control
```bash
prg worm --length 10 --direction forward --command 'sleep 5' --success 'Forward only!'
prg worm --length 10 --direction bidirectional --command 'sleep 5' --success 'Back and forth!'
```

### Feature Combinations
```bash
prg worm --length 10 --style custom=.🟡* --direction forward --ends '【】' --command 'sleep 4' --success 'All features!'
```

## Recording Tips

### For Screencasts
1. Use `demo_screencast.rb` for full feature coverage
2. Terminal window should be at least 80 characters wide
3. Consider using a terminal recorder like `asciinema`
4. The script includes natural pause points for narration

### For Quick Demos
1. Use `quick_demo.rb` for fast demonstrations
2. Perfect for social media clips or quick feature highlights
3. Focuses on the most visually impressive features

### For Documentation
1. Use `readme_demo.rb` to generate clean command-line examples
2. Output can be copied directly into documentation
3. Sectioned approach allows focused demonstrations

## Troubleshooting

### Common Issues
- **"Please provide text to animate"**: Some commands require a message argument
- **"Invalid option"**: Check option names (some flags changed between versions)
- **Animation not visible**: Ensure terminal supports the characters being used

### Solutions
- Always include a message for ripple: `prg ripple 'Loading...'`
- Check `prg --help` for current option names
- Test with basic ASCII characters first, then add Unicode/emoji

## Script Dependencies

All scripts require:
- Ruby (tested with Ruby 3.4.4)
- The ruby-progress gem (installed locally or via `gem install ruby-progress`)
- Terminal with Unicode support (for emoji examples)

The scripts automatically detect the gem location and use the local development version if run from the gem directory.
