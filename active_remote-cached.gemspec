# frozen_string_literal: true

require 'English'

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'active_remote/cached/version'

HOMEPAGE = 'https://github.com/mxenabled/active_remote-cached'

# git ls-files returns nothing outside a checkout, so a build from a released
# tarball needs the glob.
def gem_files
  files = if File.directory?(File.join(__dir__, '.git'))
            `git ls-files`.split($INPUT_RECORD_SEPARATOR)
          else
            Dir.glob('{lib,spec}/**/*', File::FNM_DOTMATCH) +
              %w[LICENSE.txt README.md Rakefile Appraisals active_remote-cached.gemspec]
          end

  files.reject { |file| File.directory?(file) }
end

Gem::Specification.new do |gem|
  gem.name          = 'active_remote-cached'
  gem.version       = ActiveRemote::Cached::VERSION
  gem.authors       = ['Brandon Dewitt', 'MXDevExperience']
  gem.email         = ['brandonsdewitt@gmail.com', 'devexperience@mx.com']
  gem.description   = ' Provides "cached" finders and a DSL to enumerate which finders should have cached versions '
  gem.summary       = ' Provides a configuration for caching mechanisms and finders on ActiveRemote models'
  gem.homepage      = HOMEPAGE
  gem.license       = 'MIT'

  gem.metadata = {
    'homepage_uri' => HOMEPAGE,
    'source_code_uri' => HOMEPAGE,
    'rubygems_mfa_required' => 'true'
  }

  gem.required_ruby_version = '>= 3.1'
  gem.files         = gem_files
  gem.executables   = gem.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  gem.require_paths = ['lib']

  gem.add_dependency 'active_remote', '>= 6.1'
  # NullStore and ActiveSupport::VERSION::STRING. Matches the active_remote floor.
  gem.add_dependency 'activesupport', '>= 6.1'

  gem.add_development_dependency 'appraisal'
  gem.add_development_dependency 'bundler'
  gem.add_development_dependency 'mocha'
  # ostruct leaves the default gems in ruby 4.0
  gem.add_development_dependency 'ostruct'
  gem.add_development_dependency 'pry'
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec', '>= 3.0'
  gem.add_development_dependency 'rubocop', '~> 1.80'
end
