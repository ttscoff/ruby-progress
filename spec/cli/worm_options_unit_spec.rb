# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/ruby-progress/cli/worm_options'

# Mock PrgCLI methods
module PrgCLI
  def self.show_worm_styles
    puts 'Available worm styles:'
  end

  def self.stop_subcommand_processes(_subcommand)
    true
  end
end

RSpec.describe 'WormCLI::Options module' do
  describe '.parse_cli_options' do
    it 'returns default options' do
      ARGV.replace([])
      options = WormCLI::Options.parse_cli_options

      expect(options[:output_position]).to eq(:above)
      expect(options[:output_lines]).to eq(3)
    end

    describe 'animation options' do
      it 'parses speed option' do
        ARGV.replace(['--speed', 'fast'])
        options = WormCLI::Options.parse_cli_options
        expect(options[:speed]).to eq('fast')
      end

      it 'parses message option' do
        ARGV.replace(['--message', 'Working...'])
        options = WormCLI::Options.parse_cli_options
        expect(options[:message]).to eq('Working...')
      end

      it 'parses length option' do
        ARGV.replace(['--length', '15'])
        options = WormCLI::Options.parse_cli_options
        expect(options[:length]).to eq(15)
      end

      it 'parses style option' do
        ARGV.replace(['--style', 'blocks'])
        options = WormCLI::Options.parse_cli_options
        expect(options[:style]).to eq('blocks')
      end

      it 'parses custom style' do
        ARGV.replace(['--style', 'custom=abc'])
        options = WormCLI::Options.parse_cli_options
        expect(options[:style]).to eq('custom=abc')
      end

      it 'parses direction as forward' do
        ARGV.replace(['--direction', 'forward'])
        options = WormCLI::Options.parse_cli_options
        expect(options[:direction]).to eq(:forward_only)
      end

      it 'parses direction as bidirectional' do
        ARGV.replace(['--direction', 'bidirectional'])
        options = WormCLI::Options.parse_cli_options
        expect(options[:direction]).to eq(:bidirectional)
      end

      it 'parses ends option' do
        ARGV.replace(['--ends', '{}'])
        options = WormCLI::Options.parse_cli_options
        expect(options[:ends]).to eq('{}')
      end
    end

    describe 'command execution' do
      it 'parses command option' do
        ARGV.replace(['--command', 'ls -l'])
        options = WormCLI::Options.parse_cli_options
        expect(options[:command]).to eq('ls -l')
      end

      it 'parses output-position' do
        ARGV.replace(['--output-position', 'below'])
        options = WormCLI::Options.parse_cli_options
        expect(options[:output_position]).to eq(:below)
      end

      it 'parses output-lines' do
        ARGV.replace(['--output-lines', '6'])
        options = WormCLI::Options.parse_cli_options
        expect(options[:output_lines]).to eq(6)
      end

      it 'parses success message' do
        ARGV.replace(['--success', 'Success!'])
        options = WormCLI::Options.parse_cli_options
        expect(options[:success]).to eq('Success!')
      end

      it 'parses error message' do
        ARGV.replace(['--error', 'Error!'])
        options = WormCLI::Options.parse_cli_options
        expect(options[:error]).to eq('Error!')
      end

      it 'parses checkmark flag' do
        ARGV.replace(['--checkmark'])
        options = WormCLI::Options.parse_cli_options
        expect(options[:checkmark]).to be true
      end

      it 'parses stdout flag' do
        ARGV.replace(['--stdout'])
        options = WormCLI::Options.parse_cli_options
        expect(options[:stdout]).to be true
      end
    end

    describe 'daemon options' do
      it 'parses daemon flag' do
        ARGV.replace(['--daemon'])
        options = WormCLI::Options.parse_cli_options
        expect(options[:daemon]).to be true
      end

      it 'parses daemon-as' do
        ARGV.replace(['--daemon-as', 'worker'])
        options = WormCLI::Options.parse_cli_options
        expect(options[:daemon]).to be true
        expect(options[:daemon_name]).to eq('worker')
      end

      it 'parses stop flag' do
        ARGV.replace(['--stop'])
        options = WormCLI::Options.parse_cli_options
        expect(options[:stop]).to be true
      end

      it 'parses status flag' do
        ARGV.replace(['--status'])
        options = WormCLI::Options.parse_cli_options
        expect(options[:status]).to be true
      end
    end

    describe 'combined options' do
      it 'parses multiple options' do
        ARGV.replace([
                       '--message', 'Processing',
                       '--speed', '7',
                       '--style', 'circles',
                       '--direction', 'forward'
                     ])
        options = WormCLI::Options.parse_cli_options

        expect(options[:message]).to eq('Processing')
        expect(options[:speed]).to eq('7')
        expect(options[:style]).to eq('circles')
        expect(options[:direction]).to eq(:forward_only)
      end
    end
  end
end
