#!/usr/bin/env ruby
# frozen_string_literal: true

# Shim script to delegate to the unified prg CLI
prg = File.expand_path(File.join(__dir__, 'bin', 'prg'))
if File.executable?(prg)
  exec prg, 'ripple', *ARGV
else
  # Fallback to system-installed prg
  exec 'prg', 'ripple', *ARGV
end
