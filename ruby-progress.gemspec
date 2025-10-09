# frozen_string_literal: true

require_relative 'lib/ruby-progress/version'

Gem::Specification.new do |spec|
  spec.name = 'ruby-progress'
  spec.version = RubyProgress::VERSION
  spec.authors = ['Brett Terpstra']
  spec.email = ['me@brettterpstra.com']

  spec.summary = 'Animated terminal progress indicators'
  spec.description = 'Animated progress indicators for Ruby: Ripple (text ripple effects), Worm (Unicode wave animations), and Twirl (spinner indicators)'
  spec.homepage = 'https://github.com/ttscoff/ruby-progress'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 2.5.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = 'bin'
  spec.executables = %w[prg ripple worm twirl]
  spec.require_paths = ['lib']

  # Runtime dependencies
  # None required - uses only standard library

  # Development dependencies
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 1.21'
  spec.add_development_dependency 'simplecov', '~> 0.21'
  spec.metadata['rubygems_mfa_required'] = 'true'
end
