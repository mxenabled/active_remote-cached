# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'active_remote-cached/version'

Gem::Specification.new do |gem|
  gem.name          = "active_remote-cached"
  gem.version       = ActiveRemote::Cached::VERSION
  gem.authors       = ["Brandon Dewitt"]
  gem.email         = ["brandonsdewitt@gmail.com"]
  gem.description   = %q{ Provides "cached" finders and a DSL to enumerate which finders should have cached versions }
  gem.summary       = %q{ Provides a configuration for caching mechanisms and finders on ActiveRemote models that are cached/cacheable }
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency "active_remote"
  gem.add_dependency "activesupport"
  gem.add_dependency "darryl_jenks"
  gem.add_dependency "heredity"

  gem.add_development_dependency "bundler"
  gem.add_development_dependency "pry"
  gem.add_development_dependency "rake"
end
