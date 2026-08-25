# frozen_string_literal: true

source 'https://rubygems.org'

# concurrent-ruby >= 1.3.5 no longer requires "logger" itself, but
# activesupport 6.1 still references ::Logger at load time. Requiring
# it here in the Gemfile ensures it is loaded by bundler/setup before
# any gem loads active_support.
require "logger"

# Specify your gem's dependencies in active_remote-cached.gemspec
gemspec
