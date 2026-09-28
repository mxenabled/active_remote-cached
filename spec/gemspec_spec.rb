# frozen_string_literal: true

require 'spec_helper'
require 'open3'

# `gem build` evals the gemspec inside Gem::Specification, but Bundler evals it
# at the top level. Bundler has already loaded the gemspec in this process, so
# a top-level def or constant from that load would hide the bug here. Load it
# in a fresh ruby without Bundler instead.
describe 'active_remote-cached.gemspec' do
  let(:root) { File.expand_path('..', __dir__) }
  let(:script) do
    <<~RUBY
      spec = Gem::Specification.load('active_remote-cached.gemspec')
      abort 'Gem::Specification.load returned nil' unless spec
      spec.validate
      puts spec.full_name
    RUBY
  end

  it 'loads and validates with Rubygems alone' do
    stdout, stderr, status = ::Bundler.with_unbundled_env do
      ::Open3.capture3(::RbConfig.ruby, '-e', script, :chdir => root)
    end

    expect(status).to be_success, stderr
    expect(stdout).to eq("active_remote-cached-#{::ActiveRemote::Cached::VERSION}\n")
  end
end
