# frozen_string_literal: true

require 'spec_helper'

class ExistMethodClass
  include ::ActiveRemote::Cached

  def self.find(*)
    :record
  end

  def self.search(*)
    [:record]
  end

  cached_finders_for :guid
  cached_finders_for :guid, :user_guid
  cached_finders_for %i[user_guid client_guid]
  cached_finders_for %i[derp user_guid client_guid]
end

describe ExistMethodClass do
  describe 'API' do
    it "creates 'cached_exist_find_by_guid'" do
      expect(ExistMethodClass).to respond_to(:cached_exist_find_by_guid)
    end

    it "creates 'cached_exist_search_by_guid'" do
      expect(ExistMethodClass).to respond_to(:cached_exist_search_by_guid)
    end

    it "creates 'cached_exist_find_by_user_guid'" do
      expect(ExistMethodClass).to respond_to(:cached_exist_find_by_user_guid)
    end

    it "creates 'cached_exist_search_by_user_guid'" do
      expect(ExistMethodClass).to respond_to(:cached_exist_search_by_user_guid)
    end

    it "creates 'cached_exist_find_by_user_guid_and_client_guid'" do
      expect(ExistMethodClass).to respond_to(:cached_exist_find_by_user_guid_and_client_guid)
    end

    it "creates 'cached_exist_search_by_user_guid_and_client_guid'" do
      expect(ExistMethodClass).to respond_to(:cached_exist_search_by_user_guid_and_client_guid)
    end

    it "creates 'cached_exist_find_by_client_guid_and_user_guid'" do
      expect(ExistMethodClass).to respond_to(:cached_exist_find_by_client_guid_and_user_guid)
    end

    it "creates 'cached_exist_search_by_client_guid_and_user_guid'" do
      expect(ExistMethodClass).to respond_to(:cached_exist_search_by_client_guid_and_user_guid)
    end

    it "creates 'cached_exist_find_by_derp_and_user_guid_and_client_guid'" do
      expect(ExistMethodClass).to respond_to(:cached_exist_find_by_derp_and_user_guid_and_client_guid)
    end

    it "creates 'cached_exist_search_by_derp_and_user_guid_and_client_guid'" do
      expect(ExistMethodClass).to respond_to(:cached_exist_search_by_derp_and_user_guid_and_client_guid)
    end

    it "creates 'cached_exist_find_by_client_guid_and_derp_and_user_guid'" do
      expect(ExistMethodClass).to respond_to(:cached_exist_find_by_client_guid_and_derp_and_user_guid)
    end

    it "creates 'cached_exist_search_by_client_guid_and_derp_and_user_guid'" do
      expect(ExistMethodClass).to respond_to(:cached_exist_search_by_client_guid_and_derp_and_user_guid)
    end

    it "creates 'cached_exist_find_by_client_guid_and_user_guid_and_derp'" do
      expect(ExistMethodClass).to respond_to(:cached_exist_find_by_client_guid_and_user_guid_and_derp)
    end

    it "creates 'cached_exist_search_by_client_guid_and_user_guid_and_derp'" do
      expect(ExistMethodClass).to respond_to(:cached_exist_search_by_client_guid_and_user_guid_and_derp)
    end

    # ? based methods
    it "creates 'cached_exist_find_by_guid?'" do
      expect(ExistMethodClass).to respond_to(:cached_exist_find_by_guid?)
    end

    it "creates 'cached_exist_search_by_guid?'" do
      expect(ExistMethodClass).to respond_to(:cached_exist_search_by_guid?)
    end

    it "creates 'cached_exist_find_by_user_guid?'" do
      expect(ExistMethodClass).to respond_to(:cached_exist_find_by_user_guid?)
    end

    it "creates 'cached_exist_search_by_user_guid?'" do
      expect(ExistMethodClass).to respond_to(:cached_exist_search_by_user_guid?)
    end

    it "creates 'cached_exist_find_by_user_guid_and_client_guid?'" do
      expect(ExistMethodClass).to respond_to(:cached_exist_find_by_user_guid_and_client_guid?)
    end

    it "creates 'cached_exist_search_by_user_guid_and_client_guid?'" do
      expect(ExistMethodClass).to respond_to(:cached_exist_search_by_user_guid_and_client_guid?)
    end

    it "creates 'cached_exist_find_by_client_guid_and_user_guid?'" do
      expect(ExistMethodClass).to respond_to(:cached_exist_find_by_client_guid_and_user_guid?)
    end

    it "creates 'cached_exist_search_by_client_guid_and_user_guid?'" do
      expect(ExistMethodClass).to respond_to(:cached_exist_search_by_client_guid_and_user_guid?)
    end

    it "creates 'cached_exist_find_by_derp_and_user_guid_and_client_guid?'" do
      expect(ExistMethodClass).to respond_to(:cached_exist_find_by_derp_and_user_guid_and_client_guid?)
    end

    it "creates 'cached_exist_search_by_derp_and_user_guid_and_client_guid?'" do
      expect(ExistMethodClass).to respond_to(:cached_exist_search_by_derp_and_user_guid_and_client_guid?)
    end

    it "creates 'cached_exist_find_by_client_guid_and_derp_and_user_guid?'" do
      expect(ExistMethodClass).to respond_to(:cached_exist_find_by_client_guid_and_derp_and_user_guid?)
    end

    it "creates 'cached_exist_search_by_client_guid_and_derp_and_user_guid?'" do
      expect(ExistMethodClass).to respond_to(:cached_exist_search_by_client_guid_and_derp_and_user_guid?)
    end

    it "creates 'cached_exist_find_by_client_guid_and_user_guid_and_derp?'" do
      expect(ExistMethodClass).to respond_to(:cached_exist_find_by_client_guid_and_user_guid_and_derp?)
    end

    it "creates 'cached_exist_search_by_client_guid_and_user_guid_and_derp?'" do
      expect(ExistMethodClass).to respond_to(:cached_exist_search_by_client_guid_and_user_guid_and_derp?)
    end
  end

  describe '#cached_exist_find_by_guid?' do
    before do
      ::ActiveRemote::Cached.cache(HashCache.new)
    end

    after do
      ::ActiveRemote::Cached.default_options({})
    end

    it 'returns false before the find cache key is written' do
      expect(ExistMethodClass.cached_exist_find_by_guid?(:guid)).to eq(false)
    end

    it 'returns true after the find cache key is written' do
      ExistMethodClass.cached_find_by_guid(:guid)

      expect(ExistMethodClass.cached_exist_find_by_guid?(:guid)).to eq(true)
    end

    it 'returns the same result as the method without the question mark' do
      ExistMethodClass.cached_find_by_guid(:guid)

      expect(ExistMethodClass.cached_exist_find_by_guid(:guid)).to eq(
        ExistMethodClass.cached_exist_find_by_guid?(:guid)
      )
    end

    it 'ignores a search cache key for the same arguments' do
      ExistMethodClass.cached_search_by_guid(:guid)

      expect(ExistMethodClass.cached_exist_find_by_guid?(:guid)).to eq(false)
    end

    describe 'namespaced cache' do
      it 'uses the namespace as a prefix to the cache key' do
        expect(::ActiveRemote::Cached.cache).to receive(:exist?).with(
          [::ActiveRemote::Cached::RUBY_AND_ACTIVE_SUPPORT_VERSION, 'MyApp', ExistMethodClass.name, '#find', 'guid']
        ).and_return(true)

        expect(ExistMethodClass.cached_exist_find_by_guid?(:guid, :namespace => 'MyApp')).to eq(true)
      end
    end
  end

  describe '#cached_exist_search_by_guid?' do
    before do
      ::ActiveRemote::Cached.cache(HashCache.new)
    end

    after do
      ::ActiveRemote::Cached.default_options({})
    end

    it 'returns false before the search cache key is written' do
      expect(ExistMethodClass.cached_exist_search_by_guid?(:guid)).to eq(false)
    end

    it 'returns true after the search cache key is written' do
      ExistMethodClass.cached_search_by_guid(:guid)

      expect(ExistMethodClass.cached_exist_search_by_guid?(:guid)).to eq(true)
    end

    it 'ignores a find cache key for the same arguments' do
      ExistMethodClass.cached_find_by_guid(:guid)

      expect(ExistMethodClass.cached_exist_search_by_guid?(:guid)).to eq(false)
    end
  end
end
