# frozen_string_literal: true

require 'spec_helper'

class ConfigurationClass
  include ::ActiveRemote::Cached

  def self.find(*)
    :find_result
  end

  def self.search(*)
    [:search_result]
  end

  cached_finders_for :guid
  cached_finders_for %i[alpha beta]

  # Declared twice on purpose, to prove cached_methods does not repeat itself.
  cached_finders_for :guid
end

class AliasFinderClass
  include ::ActiveRemote::Cached

  def self.find(*)
    :find_result
  end

  def self.search(*)
    [:search_result]
  end

  cached_finders :guid
end

class ChildFinderClass < ConfigurationClass; end

describe ::ActiveRemote::Cached do
  let(:versioned_prefix) { ::ActiveRemote::Cached::RUBY_AND_ACTIVE_SUPPORT_VERSION }

  before do
    ::ActiveRemote::Cached.cache(HashCache.new)
  end

  after do
    ::ActiveRemote::Cached.default_options({})
  end

  describe '.cache' do
    it 'wraps the cache provider in a cache' do
      expect(::ActiveRemote::Cached.cache).to be_a(::ActiveRemote::Cached::Cache)
    end

    it 'returns the current cache when no cache provider is given' do
      cache = ::ActiveRemote::Cached.cache

      expect(::ActiveRemote::Cached.cache).to be(cache)
    end
  end

  describe '.default_options' do
    it 'returns an empty hash when no options are set' do
      expect(::ActiveRemote::Cached.default_options).to eq({})
    end

    it 'returns the options that were set' do
      ::ActiveRemote::Cached.default_options(:expires_in => 100)

      expect(::ActiveRemote::Cached.default_options).to eq(:expires_in => 100)
    end

    # Passing nil reads the options. Callers must pass an empty hash to clear.
    it 'keeps the current options when nil is given' do
      ::ActiveRemote::Cached.default_options(:expires_in => 100)

      expect(::ActiveRemote::Cached.default_options(nil)).to eq(:expires_in => 100)
    end

    it 'clears the current options when an empty hash is given' do
      ::ActiveRemote::Cached.default_options(:expires_in => 100)

      expect(::ActiveRemote::Cached.default_options({})).to eq({})
    end
  end

  describe 'RUBY_AND_ACTIVE_SUPPORT_VERSION' do
    it 'prefixes every cache key' do
      expect(::ActiveRemote::Cached.cache).to receive(:fetch).with(
        [versioned_prefix, ConfigurationClass.name, '#find', 'guid'], {}
      ).and_return(:find_result)

      ConfigurationClass.cached_find_by_guid(:guid)
    end
  end

  describe '.cached_find' do
    it 'calls find with the given arguments' do
      expect(ConfigurationClass).to receive(:find).and_return(:hello)

      expect(ConfigurationClass.cached_find(:guid => :guid)).to eq(:hello)
    end

    it 'sorts the argument keys before it builds the cache key' do
      expect(ConfigurationClass).to receive(:cached_find_by_alpha_and_beta).with('A', 'B', {})

      ConfigurationClass.cached_find(:beta => 'B', :alpha => 'A')
    end

    it 'yields to the block instead of calling find' do
      expect(ConfigurationClass).not_to receive(:find)

      expect(ConfigurationClass.cached_find(:guid => :guid) { :block_result }).to eq(:block_result)
    end

    it 'passes the options through to the fetch call' do
      expect(::ActiveRemote::Cached.cache).to receive(:fetch).with(
        [versioned_prefix, ConfigurationClass.name, '#find', 'guid'], { :expires_in => 200 }
      ).and_return(:hello)

      expect(ConfigurationClass.cached_find({ :guid => :guid }, :expires_in => 200)).to eq(:hello)
    end
  end

  describe '.cached_search' do
    it 'calls search with the given arguments' do
      expect(ConfigurationClass).to receive(:search).and_return([:hello])

      expect(ConfigurationClass.cached_search(:guid => :guid)).to eq([:hello])
    end

    it 'sorts the argument keys before it builds the cache key' do
      expect(ConfigurationClass).to receive(:cached_search_by_alpha_and_beta).with('A', 'B', {})

      ConfigurationClass.cached_search(:beta => 'B', :alpha => 'A')
    end
  end

  describe '.cached_methods' do
    it 'does not repeat a method when the same finder is declared twice' do
      expect(ConfigurationClass.cached_methods).to eq(ConfigurationClass.cached_methods.uniq)
    end
  end

  describe '.cached_finders' do
    it 'creates the same methods as cached_finders_for' do
      expect(AliasFinderClass).to respond_to(:cached_find_by_guid)
      expect(AliasFinderClass).to respond_to(:cached_search_by_guid)
    end
  end

  describe '.respond_to_missing?' do
    it 'is true for a finder that was defined' do
      expect(ConfigurationClass.respond_to?(:cached_find_by_alpha_and_beta)).to eq(true)
    end

    it 'is true for a finder whose arguments are in a different order' do
      expect(ConfigurationClass.respond_to?(:cached_find_by_beta_and_alpha)).to eq(true)
    end

    it 'is false for a finder that was not defined' do
      expect(ConfigurationClass.respond_to?(:cached_find_by_missing)).to eq(false)
    end

    it 'returns a method object for a finder in a different argument order' do
      expect(ConfigurationClass.method(:cached_find_by_beta_and_alpha)).to be_a(::Method)
    end
  end

  describe '.method_missing' do
    it 'raises NoMethodError for a method that is not a finder' do
      expect { ConfigurationClass.not_a_finder }.to raise_error(::NoMethodError)
    end

    it 'raises NoMethodError for a finder that was not defined' do
      expect { ConfigurationClass.cached_find_by_missing(:value) }.to raise_error(::NoMethodError)
    end
  end

  describe '._method_missing_name' do
    it 'returns nil when the method name is not a finder' do
      expect(ConfigurationClass._method_missing_name(:not_a_finder)).to be_nil
    end

    it 'sorts the argument names in the method name' do
      expect(ConfigurationClass._method_missing_name(:cached_find_by_beta_and_alpha)).to eq(
        :cached_find_by_alpha_and_beta
      )
    end

    # The regex has no anchors, so it matches a finder name inside a longer
    # name. This records the current behavior. See the note in the README.
    it 'matches a finder name that is a suffix of a longer method name' do
      expect(ConfigurationClass._method_missing_name(:not_cached_find_by_guid)).to eq(
        :cached_find_by_guid
      )
    end
  end

  describe 'a subclass of a class with cached finders' do
    it 'responds to the finders the parent defined' do
      expect(ChildFinderClass).to respond_to(:cached_find_by_alpha_and_beta)
    end

    it 'calls the finders the parent defined' do
      expect(ChildFinderClass).to receive(:find).and_return(:hello)

      expect(ChildFinderClass.cached_find_by_alpha_and_beta('A', 'B')).to eq(:hello)
    end

    it 'has an empty cached_methods list of its own' do
      expect(ChildFinderClass.cached_methods).to eq([])
    end

    # method_missing reads cached_methods, which is empty on the subclass, so
    # the subclass cannot reorder the arguments the way the parent can.
    it 'does not accept the finder arguments in a different order' do
      expect(ConfigurationClass.cached_find_by_beta_and_alpha('B', 'A')).to eq(:find_result)

      expect { ChildFinderClass.cached_find_by_beta_and_alpha('B', 'A') }.to raise_error(::NoMethodError)
    end
  end
end
