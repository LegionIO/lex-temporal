# frozen_string_literal: true

require_relative 'lib/legion/extensions/temporal/version'

Gem::Specification.new do |spec|
  spec.name          = 'lex-temporal'
  spec.version       = Legion::Extensions::Temporal::VERSION
  spec.authors       = ['Matthew Iverson']
  spec.email         = ['matt@legionIO.com']
  spec.summary       = 'Temporal perception and time reasoning for LegionIO'
  spec.description   = 'Provides time-aware cognitive processing: elapsed awareness, urgency, temporal patterns, and deadline tracking'
  spec.homepage      = 'https://github.com/LegionIO/lex-temporal'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.files = Dir['lib/**/*']
  spec.require_paths = ['lib']

  spec.metadata['rubygems_mfa_required'] = 'true'
  spec.add_development_dependency 'legion-gaia'
end
