# frozen_string_literal: true

require_relative '../utils'

# Minimal spinner implementation used by the Twirl CLI
#
# This small class handles animation frame selection and printing
# for the Twirl command. It was extracted to keep runtime logic
# out of the CLI dispatcher module.
class TwirlSpinner
  def initialize(message, options = {})
    @message = message
    @style = parse_style(options[:style] || 'dots')
    @speed = parse_speed(options[:speed] || 'medium')
    @frames = RubyProgress::INDICATORS[@style] || RubyProgress::INDICATORS[:dots]
    @start_chars, @end_chars = RubyProgress::Utils.parse_ends(options[:ends])
    @index = 0
  end

  def animate
    if @message && !@message.empty?
      $stderr.print "\r\e[2K#{@start_chars}#{@message} #{@frames[@index]}#{@end_chars}"
    else
      $stderr.print "\r\e[2K#{@start_chars}#{@frames[@index]}#{@end_chars}"
    end
    $stderr.flush
    @index = (@index + 1) % @frames.length
    sleep @speed
  end

  private

  def parse_style(style_input)
    return :dots unless style_input && !style_input.to_s.strip.empty?

    style_lower = style_input.to_s.downcase.strip

    indicator_keys = RubyProgress::INDICATORS.keys.map(&:to_s)
    return style_lower.to_sym if indicator_keys.include?(style_lower)

    prefix_matches = indicator_keys.select { |key| key.downcase.start_with?(style_lower) }
    return prefix_matches.min_by(&:length).to_sym unless prefix_matches.empty?

    fuzzy_matches = indicator_keys.select do |key|
      key_chars = key.downcase.chars
      input_chars = style_lower.chars
      input_chars.all? do |char|
        idx = key_chars.index(char)
        if idx
          key_chars = key_chars[idx + 1..-1]
          true
        else
          false
        end
      end
    end

    return fuzzy_matches.min_by(&:length).to_sym unless fuzzy_matches.empty?

    substring_matches = indicator_keys.select { |key| key.downcase.include?(style_lower) }
    return substring_matches.min_by(&:length).to_sym unless substring_matches.empty?

    :dots
  end

  def parse_speed(speed)
    case speed.to_s.downcase
    when /^f/, '1', '2', '3'
      0.05
    when /^m/, '4', '5', '6', '7'
      0.1
    when /^s/, '8', '9', '10'
      0.2
    else
      speed.to_f.positive? ? (1.0 / speed.to_f) : 0.1
    end
  end
end
