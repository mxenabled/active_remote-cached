# frozen_string_literal: true

require 'spec_helper'

describe ::ActiveRemote::Cached::ArgumentKeys do
  it 'does not mutate a string by default' do
    expect(::ActiveRemote::Cached::ArgumentKeys.new('hello', {}).cache_key).to eq('hello')
  end

  it 'returns a string of a symbol by default' do
    expect(::ActiveRemote::Cached::ArgumentKeys.new(:hello, {}).cache_key).to eq('hello')
  end

  it 'does not mutate a string with special characters by default' do
    expect(::ActiveRemote::Cached::ArgumentKeys.new('hello {}', {}).cache_key).to eq('hello {}')
  end

  it 'removes special characters from string with special characters when :active_remote_cached_remove_characters' do
    options = { :active_remote_cached_remove_characters => true }
    expect(::ActiveRemote::Cached::ArgumentKeys.new('hello {}', options).cache_key).to eq('hello')
  end

  it 'replaces special characters from string with special characters when :active_remote_cached_replace_characters' do
    options = { :active_remote_cached_replace_characters => true }
    expect(::ActiveRemote::Cached::ArgumentKeys.new('hello {}', options).cache_key).to eq('helloSPLBRB')
  end

  it 'joins multiple arguments into one key' do
    expect(::ActiveRemote::Cached::ArgumentKeys.new('hello', 'world', {}).cache_key).to eq('helloworld')
  end

  it 'removes nil arguments from the key' do
    expect(::ActiveRemote::Cached::ArgumentKeys.new('hello', nil, 'world', {}).cache_key).to eq('helloworld')
  end

  it 'flattens nested array arguments into the key' do
    expect(::ActiveRemote::Cached::ArgumentKeys.new(['hello', ['world']], {}).cache_key).to eq('helloworld')
  end

  it 'returns an empty key when no arguments are given' do
    expect(::ActiveRemote::Cached::ArgumentKeys.new({}).cache_key).to eq('')
  end

  it 'returns the cache key from #to_s' do
    expect(::ActiveRemote::Cached::ArgumentKeys.new('hello', {}).to_s).to eq('hello')
  end

  it 'removes characters when both the remove and the replace option are given' do
    options = {
      :active_remote_cached_remove_characters => true,
      :active_remote_cached_replace_characters => true
    }
    expect(::ActiveRemote::Cached::ArgumentKeys.new('hello {}', options).cache_key).to eq('hello')
  end

  # #cache_key calls gsub! on an instance variable, so a second call must not
  # replace the characters of the first result again.
  it 'returns the same key when :active_remote_cached_replace_characters is called twice' do
    options = { :active_remote_cached_replace_characters => true }
    argument_keys = ::ActiveRemote::Cached::ArgumentKeys.new('hello {}', options)

    expect(argument_keys.cache_key).to eq('helloSPLBRB')
    expect(argument_keys.cache_key).to eq('helloSPLBRB')
  end
end
