# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/ruby-progress/cli/ripple_options'

# Mock PrgCLI methods
module PrgCLI
  def self.show_ripple_styles
    puts 'Available ripple styles:'
  end

  def self.stop_subcommand_processes(_subcommand)
    true
  end
end

RSpec.describe 'RippleCLI::Options module' do
  describe '.parse_cli_options' do
    it 'returns default options' do
      ARGV.replace([])
      options = RippleCLI::Options.parse_cli_options

      expect(options[:speed]).to eq(:medium)
      expect(options[:direction]).to eq(:bidirectional)
      expect(options[:styles]).to eq([])
    end

    describe 'animation options' do
      it 'parses speed as fast' do
        ARGV.replace(['--speed', 'fast'])
        options = RippleCLI::Options.parse_cli_options
        expect(options[:speed]).to eq(:fast)
      end

      it 'parses speed as slow' do
        ARGV.replace(['--speed', 'slow'])
        options = RippleCLI::Options.parse_cli_options
        expect(options[:speed]).to eq(:slow)
      end

      it 'parses speed abbreviation' do
        ARGV.replace(['-s', 'f'])
        options = RippleCLI::Options.parse_cli_options
        expect(options[:speed]).to eq(:fast)
      end

      it 'parses message option' do
        ARGV.replace(['--message', 'Loading...'])
        options = RippleCLI::Options.parse_cli_options
        expect(options[:message]).to eq('Loading...')
      end

      it 'parses single style' do
        ARGV.replace(['--style', 'rainbow'])
        options = RippleCLI::Options.parse_cli_options
        expect(options[:styles]).to eq([:rainbow])
      end

      it 'parses multiple styles comma-separated' do
        ARGV.replace(['--style', 'rainbow,caps,inverse'])
        options = RippleCLI::Options.parse_cli_options
        expect(options[:styles]).to eq(%i[rainbow caps inverse])
      end

      it 'parses direction as forward' do
        ARGV.replace(['--direction', 'forward'])
        options = RippleCLI::Options.parse_cli_options
        expect(options[:format]).to eq(:forward_only)
      end

      it 'parses ends option' do
        ARGV.replace(['--ends', '()'])
        options = RippleCLI::Options.parse_cli_options
        expect(options[:ends]).to eq('()')
      end
    end

    describe 'command execution' do
      it 'parses command option' do
        ARGV.replace(['--command', 'sleep 1'])
        options = RippleCLI::Options.parse_cli_options
        expect(options[:command]).to eq('sleep 1')
      end

      it 'parses output-position' do
        ARGV.replace(['--output-position', 'below'])
        options = RippleCLI::Options.parse_cli_options
        expect(options[:output_position]).to eq(:below)
      end

      it 'parses output-lines' do
        ARGV.replace(['--output-lines', '7'])
        options = RippleCLI::Options.parse_cli_options
        expect(options[:output_lines]).to eq(7)
      end

      it 'parses success message' do
        ARGV.replace(['--success', 'Complete!'])
        options = RippleCLI::Options.parse_cli_options
        expect(options[:success_message]).to eq('Complete!')
      end

      it 'parses error message' do
        ARGV.replace(['--error', 'Failed'])
        options = RippleCLI::Options.parse_cli_options
        expect(options[:fail_message]).to eq('Failed')
      end

      it 'parses checkmark flag' do
        ARGV.replace(['--checkmark'])
        options = RippleCLI::Options.parse_cli_options
        expect(options[:complete_checkmark]).to be true
      end

      it 'parses stdout flag' do
        ARGV.replace(['--stdout'])
        options = RippleCLI::Options.parse_cli_options
        expect(options[:output]).to eq(:stdout)
      end

      it 'parses quiet flag' do
        ARGV.replace(['--quiet'])
        options = RippleCLI::Options.parse_cli_options
        expect(options[:output]).to eq(:quiet)
      end
    end

    describe 'daemon options' do
      it 'parses daemon flag' do
        ARGV.replace(['--daemon'])
        options = RippleCLI::Options.parse_cli_options
        expect(options[:daemon]).to be true
      end

      it 'parses daemon-as' do
        ARGV.replace(['--daemon-as', 'myprocess'])
        options = RippleCLI::Options.parse_cli_options
        expect(options[:daemon]).to be true
        expect(options[:daemon_name]).to eq('myprocess')
      end

      it 'parses stop flag' do
        ARGV.replace(['--stop'])
        options = RippleCLI::Options.parse_cli_options
        expect(options[:stop]).to be true
      end

      it 'parses status flag' do
        ARGV.replace(['--status'])
        options = RippleCLI::Options.parse_cli_options
        expect(options[:status]).to be true
      end
    end

    describe 'combined options' do
      it 'parses multiple options' do
        ARGV.replace([
                       '--message', 'Processing',
                       '--speed', 'fast',
                       '--style', 'rainbow,caps',
                       '--command', 'echo done'
                     ])
        options = RippleCLI::Options.parse_cli_options

        expect(options[:message]).to eq('Processing')
        expect(options[:speed]).to eq(:fast)
        expect(options[:styles]).to eq(%i[rainbow caps])
        expect(options[:command]).to eq('echo done')
      end
    end
  end
end
