# frozen_string_literal: true

require 'spec_helper'

class SearchMethodClass
  include ::ActiveRemote::Cached

  def self.derp
    nil
  end

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

describe SearchMethodClass do
  let(:versioned_prefix) do
    "#{RUBY_ENGINE_VERSION}:#{ActiveSupport::VERSION::STRING}"
  end

  describe 'API' do
    it "creates 'cached_search_by_foo'" do
      expect(SearchMethodClass).to respond_to(:cached_search_by_foo)
    end

    it "creates 'cached_search_by_foo!'" do
      expect(SearchMethodClass).to respond_to(:cached_search_by_foo!)
    end

    it "creates 'cached_search_by_guid'" do
      expect(SearchMethodClass).to respond_to(:cached_search_by_guid)
    end

    it "creates 'cached_search_by_user_guid'" do
      expect(SearchMethodClass).to respond_to(:cached_search_by_user_guid)
    end

    it "creates 'cached_search_by_user_guid_and_client_guid'" do
      expect(SearchMethodClass).to respond_to(:cached_search_by_user_guid_and_client_guid)
    end

    it "creates 'cached_search_by_client_guid_and_user_guid'" do
      expect(SearchMethodClass).to respond_to(:cached_search_by_client_guid_and_user_guid)
    end

    it "creates 'cached_search_by_derp_and_user_guid_and_client_guid'" do
      expect(SearchMethodClass).to respond_to(:cached_search_by_derp_and_user_guid_and_client_guid)
    end

    it "creates 'cached_search_by_client_guid_and_derp_and_user_guid'" do
      expect(SearchMethodClass).to respond_to(:cached_search_by_client_guid_and_derp_and_user_guid)
    end

    it "creates 'cached_search_by_client_guid_and_user_guid_and_derp'" do
      expect(SearchMethodClass).to respond_to(:cached_search_by_client_guid_and_user_guid_and_derp)
    end

    it "creates 'cached_search_by_client_guid_and_user_guid_and_derp!'" do
      expect(SearchMethodClass).to respond_to(:cached_search_by_client_guid_and_user_guid_and_derp!)
    end
  end

  describe '#cached_search_by_guid' do
    before do
      ::ActiveRemote::Cached.cache(HashCache.new)
      ::ActiveRemote::Cached.default_options(:expires_in => 100)
    end

    after do
      ::ActiveRemote::Cached.default_options({})
    end

    it 'executes the search block when a block is passed' do
      expect(SearchMethodClass).to receive(:derp).and_return(:derp)
      expect(SearchMethodClass.cached_search(:guid => :guid) do
        SearchMethodClass.derp
      end).to eq(:derp)
    end

    it 'does not persist empty values by default' do
      expect(SearchMethodClass).to receive(:derp).and_return([])

      SearchMethodClass.cached_search(:guid => :guid) do
        SearchMethodClass.derp
      end

      expect(SearchMethodClass.cached_exist_search_by_guid?(:guid)).to eq(false)
    end

    it 'persists empty values when allow_empty sent' do
      expect(SearchMethodClass).to receive(:derp).and_return([])
      SearchMethodClass.cached_search({ :guid => :guid }, :allow_empty => true) do
        SearchMethodClass.derp
      end

      expect(SearchMethodClass.cached_exist_search_by_guid?(:guid)).to eq(true)
    end

    it 'does not persist nil values by default' do
      expect(SearchMethodClass).to receive(:derp).and_return(nil)
      SearchMethodClass.cached_search(:guid => :guid) do
        SearchMethodClass.derp
      end

      expect(SearchMethodClass.cached_exist_search_by_guid?(:guid)).to eq(false)
    end

    it 'persists nil values when allow_nil sent' do
      expect(SearchMethodClass).to receive(:derp).and_return(nil)
      SearchMethodClass.cached_search({ :guid => :guid }, :allow_nil => true) do
        SearchMethodClass.derp
      end

      expect(SearchMethodClass.cached_exist_search_by_guid?(:guid)).to eq(true)
    end

    it 'does persist non nil values' do
      expect(SearchMethodClass).to receive(:derp).and_return(:derp)
      SearchMethodClass.cached_search(:guid => :guid) do
        SearchMethodClass.derp
      end

      expect(SearchMethodClass.cached_exist_search_by_guid?(:guid)).to eq(true)
    end

    it 'executes search_by_guid when cached_search with guid called' do
      expect(SearchMethodClass).to receive(:search).and_return(:hello)

      expect(SearchMethodClass.cached_search(:guid => :guid)).to eq(:hello)
    end

    it 'executes the fetch block if not present in cache' do
      expect(SearchMethodClass).to receive(:search).and_return(:hello)
      expect(SearchMethodClass.cached_search_by_guid(:guid)).to eq(:hello)
    end

    it 'merges the default options in for the fetch call' do
      expect(::ActiveRemote::Cached.cache).to receive(:fetch).with(
        [versioned_prefix, SearchMethodClass.name, '#search', 'guid'], { :expires_in => 100 }
      ).and_return(:hello)

      expect(SearchMethodClass).not_to receive(:search)
      expect(SearchMethodClass.cached_search_by_guid(:guid)).to eq(:hello)
    end

    it 'overrides the default options with local options for the fetch call' do
      expect(::ActiveRemote::Cached.cache).to receive(:fetch).with(
        [versioned_prefix, SearchMethodClass.name, '#search', 'guid'], { :expires_in => 200 }
      ).and_return(:hello)

      expect(SearchMethodClass).not_to receive(:search)
      expect(SearchMethodClass.cached_search_by_guid(:guid, { :expires_in => 200 })).to eq(:hello)
    end

    describe 'namespaced cache' do
      before do
        ::ActiveRemote::Cached.default_options(:expires_in => 100, :namespace => 'MyApp')
      end

      it 'uses the namespace as a prefix to the cache key' do
        expect(::ActiveRemote::Cached.cache).to receive(:fetch).with(
          [versioned_prefix, 'MyApp', SearchMethodClass.name, '#search', 'guid'], { :expires_in => 100 }
        ).and_return(:hello)

        expect(SearchMethodClass).not_to receive(:search)
        SearchMethodClass.cached_search_by_guid(:guid)
      end
    end
  end

  describe '#cached_search_by_foo' do
    before do
      ::ActiveRemote::Cached.cache(HashCache.new)
      ::ActiveRemote::Cached.default_options(:expires_in => 100)
    end

    after do
      ::ActiveRemote::Cached.default_options({})
    end

    it 'overrides the default options with cached_finder options for the fetch call' do
      expect(::ActiveRemote::Cached.cache).to receive(:fetch).with(
        [versioned_prefix, SearchMethodClass.name, '#search', 'foo'], { :expires_in => 500 }
      ).and_return(:hello)

      expect(SearchMethodClass).not_to receive(:find)
      expect(SearchMethodClass.cached_search_by_foo(:foo)).to eq(:hello)
    end

    it 'overrides the cached_finder options with local options for the fetch call' do
      expect(::ActiveRemote::Cached.cache).to receive(:fetch).with(
        [versioned_prefix, SearchMethodClass.name, '#search', 'foo'], { :expires_in => 200 }
      ).and_return(:hello)

      expect(SearchMethodClass).not_to receive(:find)
      expect(SearchMethodClass.cached_search_by_foo(:foo, :expires_in => 200)).to eq(:hello)
    end
  end

  describe '#cached_search_by_foo!' do
    before do
      ::ActiveRemote::Cached.cache(HashCache.new)
      ::ActiveRemote::Cached.default_options(:expires_in => 100)
    end

    after do
      ::ActiveRemote::Cached.default_options({})
    end

    it 'and_return results when present' do
      expect(SearchMethodClass).to receive(:search).and_return([:hello])
      expect(SearchMethodClass.cached_search_by_foo!(:foo, :expires_in => 200)).to eq([:hello])
    end

    it 'raises ActiveRemote::RemoteRecordNotFound when not found' do
      expect(SearchMethodClass).to receive(:search).and_return([])
      expect do
        SearchMethodClass.cached_search_by_foo!(:foo, :expires_in => 200)
      end.to raise_error ::ActiveRemote::RemoteRecordNotFound
    end
  end
end
