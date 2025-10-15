# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/ruby-progress/cli/twirl_options'

# Mock PrgCLI methods that are called during option parsing
module PrgCLI
  def self.show_twirl_styles
    puts 'Available twirl styles:'
  end

  def self.stop_subcommand_processes(_subcommand)
    true
  end
end

RSpec.describe 'TwirlCLI::Options module' do
  describe '.parse_cli_options' do
    it 'returns default options when no args provided' do
      ARGV.replace([])
      options = TwirlCLI::Options.parse_cli_options

      expect(options[:output_position]).to eq(:above)
      expect(options[:output_lines]).to eq(3)
    end

    describe 'animation options' do
      it 'parses speed option' do
        ARGV.replace(['--speed', 'fast'])
        options = TwirlCLI::Options.parse_cli_options
        expect(options[:speed]).to eq('fast')
      end

      it 'parses message option' do
        ARGV.replace(['--message', 'Loading...'])
        options = TwirlCLI::Options.parse_cli_options
        expect(options[:message]).to eq('Loading...')
      end

      it 'parses style option' do
        ARGV.replace(['--style', 'dots'])
        options = TwirlCLI::Options.parse_cli_options
        expect(options[:style]).to eq('dots')
      end

      it 'parses direction as forward' do
        ARGV.replace(['--direction', 'forward'])
        options = TwirlCLI::Options.parse_cli_options
        expect(options[:direction]).to eq(:forward_only)
      end

      it 'parses direction as bidirectional' do
        ARGV.replace(['--direction', 'back'])
        options = TwirlCLI::Options.parse_cli_options
        expect(options[:direction]).to eq(:bidirectional)
      end

      it 'parses ends option' do
        ARGV.replace(['--ends', '[]'])
        options = TwirlCLI::Options.parse_cli_options
        expect(options[:ends]).to eq('[]')
      end
    end

    describe 'command execution options' do
      it 'parses command option' do
        ARGV.replace(['--command', 'echo test'])
        options = TwirlCLI::Options.parse_cli_options
        expect(options[:command]).to eq('echo test')
      end

      it 'parses output-position' do
        ARGV.replace(['--output-position', 'below'])
        options = TwirlCLI::Options.parse_cli_options
        expect(options[:output_position]).to eq(:below)
      end

      it 'parses output-lines' do
        ARGV.replace(['--output-lines', '5'])
        options = TwirlCLI::Options.parse_cli_options
        expect(options[:output_lines]).to eq(5)
      end

      it 'parses success message' do
        ARGV.replace(['--success', 'Done!'])
        options = TwirlCLI::Options.parse_cli_options
        expect(options[:success]).to eq('Done!')
      end

      it 'parses checkmark flag' do
        ARGV.replace(['--checkmark'])
        options = TwirlCLI::Options.parse_cli_options
        expect(options[:checkmark]).to be true
      end

      it 'parses stdout flag' do
        ARGV.replace(['--stdout'])
        options = TwirlCLI::Options.parse_cli_options
        expect(options[:stdout]).to be true
      end
    end

    describe 'daemon options' do
      it 'parses daemon flag' do
        ARGV.replace(['--daemon'])
        options = TwirlCLI::Options.parse_cli_options
        expect(options[:daemon]).to be true
      end

      it 'parses daemon-as with name' do
        ARGV.replace(['--daemon-as', 'mytask'])
        options = TwirlCLI::Options.parse_cli_options
        expect(options[:daemon]).to be true
        expect(options[:daemon_name]).to eq('mytask')
      end

      it 'parses stop flag' do
        ARGV.replace(['--stop'])
        options = TwirlCLI::Options.parse_cli_options
        expect(options[:stop]).to be true
      end

      it 'parses status flag' do
        ARGV.replace(['--status'])
        options = TwirlCLI::Options.parse_cli_options
        expect(options[:status]).to be true
      end
    end

    describe 'error handling' do
      it 'exits with error on invalid option' do
        ARGV.replace(['--invalid-option'])
        expect do
          TwirlCLI::Options.parse_cli_options
        end.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(1)
        end
      end
    end

    describe 'combined options' do
      it 'parses multiple options together' do
        ARGV.replace([
                       '--message', 'Testing',
                       '--speed', 'fast',
                       '--style', 'dots',
                       '--command', 'echo test'
                     ])
        options = TwirlCLI::Options.parse_cli_options

        expect(options[:message]).to eq('Testing')
        expect(options[:speed]).to eq('fast')
        expect(options[:style]).to eq('dots')
        expect(options[:command]).to eq('echo test')
      end
    end
  end
end
