#!/usr/bin/env ruby

# Test script to reproduce daemon orphaning issue
puts 'Starting daemon...'
system("./bin/prg worm --daemon-as test 'Working on something...'")

puts 'Daemon started, sleeping for 3 seconds...'
puts 'Cancel this script with ^C during the sleep to reproduce the orphan issue'
sleep 3

puts 'Stopping daemon normally...'
system('./bin/prg --stop-id test')
puts 'Done'
