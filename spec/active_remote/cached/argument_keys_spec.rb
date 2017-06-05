require 'spec_helper'

describe ::ActiveRemote::Cached::ArgumentKeys do
  it "does not mutate a string by default" do
    ::ActiveRemote::Cached::ArgumentKeys.new("hello", {}).cache_key.must_equal("hello")
  end

  it "returns a string of a symbol by default" do
    ::ActiveRemote::Cached::ArgumentKeys.new(:hello, {}).cache_key.must_equal("hello")
  end

  it "does not mutate a string with special characters by default" do
    ::ActiveRemote::Cached::ArgumentKeys.new("hello {}", {}).cache_key.must_equal("hello {}")
  end

  it "removes special characters from string with special characters when :active_remote_cached_remove_characters" do
    options = { :active_remote_cached_remove_characters => true }
    ::ActiveRemote::Cached::ArgumentKeys.new("hello {}", options).cache_key.must_equal("hello")
  end

  it "replaces special characters from string with special characters when :active_remote_cached_replace_characters" do
    options = { :active_remote_cached_replace_characters => true }
    ::ActiveRemote::Cached::ArgumentKeys.new("hello {}", options).cache_key.must_equal("helloSPLBRB")
  end
end
