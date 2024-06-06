require 'spec_helper'

describe ::ActiveRemote::Cached::ArgumentKeys do
  it "does not mutate a string by default" do
    expect(::ActiveRemote::Cached::ArgumentKeys.new("hello", {}).cache_key).to eq("hello")
  end

  it "returns a string of a symbol by default" do
    expect(::ActiveRemote::Cached::ArgumentKeys.new(:hello, {}).cache_key).to eq("hello")
  end

  it "does not mutate a string with special characters by default" do
    expect(::ActiveRemote::Cached::ArgumentKeys.new("hello {}", {}).cache_key).to eq("hello {}")
  end

  it "removes special characters from string with special characters when :active_remote_cached_remove_characters" do
    options = { :active_remote_cached_remove_characters => true }
    expect(::ActiveRemote::Cached::ArgumentKeys.new("hello {}", options).cache_key).to eq("hello")
  end

  it "replaces special characters from string with special characters when :active_remote_cached_replace_characters" do
    options = { :active_remote_cached_replace_characters => true }
    expect(::ActiveRemote::Cached::ArgumentKeys.new("hello {}", options).cache_key).to eq("helloSPLBRB")
  end
end
