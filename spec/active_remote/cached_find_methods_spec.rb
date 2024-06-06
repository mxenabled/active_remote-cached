# frozen_string_literal: true

require 'spec_helper'

class FindMethodClass
  include ::ActiveRemote::Cached

  def self.find
    nil
  end

  def self.search
    nil
  end

  cached_finders_for :foo, :expires_in => 500
  cached_finders_for :guid
  cached_finders_for :guid, :user_guid
  cached_finders_for %i[user_guid client_guid]
  cached_finders_for %i[derp user_guid client_guid]
end

describe FindMethodClass do
  let(:versioned_prefix) do
    "#{RUBY_ENGINE_VERSION}:#{ActiveSupport::VERSION::STRING}"
  end

  describe 'API' do
    it "creates 'cached_find_by_foo'" do
      expect(FindMethodClass).to respond_to(:cached_find_by_foo)
    end

    it "creates 'cached_find_by_guid'" do
      expect(FindMethodClass).to respond_to(:cached_find_by_guid)
    end

    it "creates 'cached_find_by_user_guid'" do
      expect(FindMethodClass).to respond_to(:cached_find_by_user_guid)
    end

    it "creates 'cached_find_by_user_guid_and_client_guid'" do
      expect(FindMethodClass).to respond_to(:cached_find_by_user_guid_and_client_guid)
    end

    it "creates 'cached_find_by_client_guid_and_user_guid'" do
      expect(FindMethodClass).to respond_to(:cached_find_by_client_guid_and_user_guid)
    end

    it "creates 'cached_find_by_derp_and_user_guid_and_client_guid'" do
      expect(FindMethodClass).to respond_to(:cached_find_by_derp_and_user_guid_and_client_guid)
    end

    it "creates 'cached_find_by_client_guid_and_derp_and_user_guid'" do
      expect(FindMethodClass).to respond_to(:cached_find_by_client_guid_and_derp_and_user_guid)
    end

    it "creates 'cached_find_by_client_guid_and_user_guid_and_derp'" do
      expect(FindMethodClass).to respond_to(:cached_find_by_client_guid_and_user_guid_and_derp)
    end
  end

  describe '#cached_find_by_guid' do
    before do
      ::ActiveRemote::Cached.cache(HashCache.new)
      ::ActiveRemote::Cached.default_options(:expires_in => 100)
    end

    after do
      ::ActiveRemote::Cached.default_options({})
    end

    it 'executes find_by_guid when cached_find with guid called' do
      expect(FindMethodClass).to receive(:find).and_return(:hello)
      expect(FindMethodClass.cached_find(:guid => :guid)).to eq(:hello)
    end

    it 'executes the fetch block if not present in cache' do
      expect(FindMethodClass).to receive(:find).and_return(:hello)
      expect(FindMethodClass.cached_find_by_guid(:guid)).to eq(:hello)
    end

    it 'merges the default options in for the fetch call' do
      expect(::ActiveRemote::Cached.cache).to receive(:fetch).with(
        [versioned_prefix, FindMethodClass.name, '#find', 'guid'], { :expires_in => 100 }
      ).and_return(:hello)
      expect(FindMethodClass).not_to receive(:find)
      expect(FindMethodClass.cached_find_by_guid(:guid)).to eq(:hello)
    end

    it 'overrides the default options with local options for the fetch call' do
      expect(::ActiveRemote::Cached.cache).to receive(:fetch).with(
        [versioned_prefix, FindMethodClass.name, '#find', 'guid'], { :expires_in => 200 }
      ).and_return(:hello)
      expect(FindMethodClass).not_to receive(:find)

      expect(FindMethodClass.cached_find_by_guid(:guid, :expires_in => 200)).to eq(:hello)
    end

    describe 'namespaced cache' do
      before do
        ::ActiveRemote::Cached.default_options(:expires_in => 100, :namespace => 'MyApp')
      end

      it 'uses the namespace as a prefix to the cache key' do
        expect(::ActiveRemote::Cached.cache).to receive(:fetch).with(
          [versioned_prefix, 'MyApp', FindMethodClass.name, '#find', 'guid'], { :expires_in => 100 }
        ).and_return(:hello)

        expect(FindMethodClass).not_to receive(:find)
        FindMethodClass.cached_find_by_guid(:guid)
      end
    end
  end

  describe '#cached_find_by_foo' do
    before do
      ::ActiveRemote::Cached.cache(HashCache.new)
      ::ActiveRemote::Cached.default_options(:expires_in => 100)
    end

    after do
      ::ActiveRemote::Cached.default_options({})
    end

    it 'overrides the default options with cached_finder options for the fetch call' do
      expect(::ActiveRemote::Cached.cache).to receive(:fetch).with(
        [versioned_prefix, FindMethodClass.name, '#find', 'foo'], { :expires_in => 500 }
      ).and_return(:hello)

      expect(FindMethodClass).not_to receive(:find)
      expect(FindMethodClass.cached_find_by_foo(:foo)).to eq(:hello)
    end

    it 'overrides the cached_finder options with local options for the fetch call' do
      expect(::ActiveRemote::Cached.cache).to receive(:fetch).with(
        [versioned_prefix, FindMethodClass.name, '#find', 'foo'], { :expires_in => 200 }
      ).and_return(:hello)

      expect(FindMethodClass).not_to receive(:find)
      expect(FindMethodClass.cached_find_by_foo(:foo, :expires_in => 200)).to eq(:hello)
    end
  end
end
