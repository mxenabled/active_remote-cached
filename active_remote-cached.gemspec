# frozen_string_literal: true

require 'English'

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'active_remote/cached/version'

Gem::Specification.new do |gem|
  gem.name          = 'active_remote-cached'
  gem.version       = ActiveRemote::Cached::VERSION
  gem.authors       = ['Brandon Dewitt', 'MXDevExperience']
  gem.email         = ['brandonsdewitt@gmail.com', 'devexperience@mx.com']
  gem.description   = ' Provides "cached" finders and a DSL to enumerate which finders should have cached versions '
  gem.summary       = ' Provides a configuration for caching mechanisms and finders on ActiveRemote models'
  gem.homepage      = ''

  gem.required_ruby_version = '>= 2.6'
  gem.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  gem.executables   = gem.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']

  gem.add_dependency 'active_remote', '>= 6.1'
  gem.add_dependency 'activesupport'

  gem.add_development_dependency 'bundler'
  gem.add_development_dependency 'mocha'
  gem.add_development_dependency 'pry'
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec', '>= 3.0'
  gem.add_development_dependency 'rubocop'
end
