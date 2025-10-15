# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/ruby-progress/cli/fill_options'

RSpec.describe 'FillCLI::Options module' do
  describe '.parse_cli_options' do
    it 'returns default options' do
      ARGV.replace([])
      options = RubyProgress::FillCLI::Options.parse_cli_options

      expect(options[:style]).to eq(:blocks)
      expect(options[:length]).to eq(20)
      expect(options[:speed]).to eq(:medium)
    end

    describe 'progress bar options' do
      it 'parses length option' do
        ARGV.replace(['--length', '30'])
        options = RubyProgress::FillCLI::Options.parse_cli_options
        expect(options[:length]).to eq(30)
      end

      it 'parses style option' do
        ARGV.replace(['--style', 'dots'])
        options = RubyProgress::FillCLI::Options.parse_cli_options
        expect(options[:style]).to eq('dots')
      end

      it 'parses custom style' do
        ARGV.replace(['--style', 'custom=.#'])
        options = RubyProgress::FillCLI::Options.parse_cli_options
        expect(options[:style]).to eq('custom=.#')
      end

      it 'parses ends option' do
        ARGV.replace(['--ends', '[]'])
        options = RubyProgress::FillCLI::Options.parse_cli_options
        expect(options[:ends]).to eq('[]')
      end
    end

    describe 'output capture options' do
      it 'parses command option' do
        ARGV.replace(['--command', 'echo test'])
        options = RubyProgress::FillCLI::Options.parse_cli_options
        expect(options[:command]).to eq('echo test')
      end

      it 'parses output-position' do
        ARGV.replace(['--output-position', 'below'])
        options = RubyProgress::FillCLI::Options.parse_cli_options
        expect(options[:output_position]).to eq(:below)
      end

      it 'parses output-lines' do
        ARGV.replace(['--output-lines', '5'])
        options = RubyProgress::FillCLI::Options.parse_cli_options
        expect(options[:output_lines]).to eq(5)
      end

      it 'parses stdout-live flag' do
        ARGV.replace(['--stdout-live'])
        options = RubyProgress::FillCLI::Options.parse_cli_options
        expect(options[:stdout_live]).to be true
      end
    end

    describe 'progress control options' do
      it 'parses percent option' do
        ARGV.replace(['--percent', '50.5'])
        options = RubyProgress::FillCLI::Options.parse_cli_options
        expect(options[:percent]).to eq(50.5)
      end

      it 'parses advance flag' do
        ARGV.replace(['--advance'])
        options = RubyProgress::FillCLI::Options.parse_cli_options
        expect(options[:advance]).to be true
      end

      it 'parses complete flag' do
        ARGV.replace(['--complete'])
        options = RubyProgress::FillCLI::Options.parse_cli_options
        expect(options[:complete]).to be true
      end

      it 'parses cancel flag' do
        ARGV.replace(['--cancel'])
        options = RubyProgress::FillCLI::Options.parse_cli_options
        expect(options[:cancel]).to be true
      end
    end

    describe 'message options' do
      it 'parses success message' do
        ARGV.replace(['--success', 'Done!'])
        options = RubyProgress::FillCLI::Options.parse_cli_options
        expect(options[:success_message]).to eq('Done!')
      end

      it 'parses error message' do
        ARGV.replace(['--error', 'Failed'])
        options = RubyProgress::FillCLI::Options.parse_cli_options
        expect(options[:error_message]).to eq('Failed')
      end

      it 'parses checkmark flag' do
        ARGV.replace(['--checkmark'])
        options = RubyProgress::FillCLI::Options.parse_cli_options
        expect(options[:checkmark]).to be true
      end
    end

    describe 'daemon options' do
      it 'parses daemon flag' do
        ARGV.replace(['--daemon'])
        options = RubyProgress::FillCLI::Options.parse_cli_options
        expect(options[:daemon]).to be true
      end

      it 'parses stop flag' do
        ARGV.replace(['--stop'])
        options = RubyProgress::FillCLI::Options.parse_cli_options
        expect(options[:stop]).to be true
      end

      it 'parses status flag' do
        ARGV.replace(['--status'])
        options = RubyProgress::FillCLI::Options.parse_cli_options
        expect(options[:status]).to be true
      end
    end

    describe 'query options' do
      it 'parses current flag' do
        ARGV.replace(['--current'])
        options = RubyProgress::FillCLI::Options.parse_cli_options
        expect(options[:current]).to be true
      end

      it 'parses report flag' do
        ARGV.replace(['--report'])
        options = RubyProgress::FillCLI::Options.parse_cli_options
        expect(options[:report]).to be true
      end
    end

    describe 'combined options' do
      it 'parses multiple options together' do
        ARGV.replace([
                       '--length', '15',
                       '--style', 'bars',
                       '--percent', '60',
                       '--success', 'Complete'
                     ])
        options = RubyProgress::FillCLI::Options.parse_cli_options

        expect(options[:length]).to eq(15)
        expect(options[:style]).to eq('bars')
        expect(options[:percent]).to eq(60.0)
        expect(options[:success_message]).to eq('Complete')
      end
    end
  end
end
