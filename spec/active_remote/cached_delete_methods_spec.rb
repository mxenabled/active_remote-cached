# frozen_string_literal: true

require 'spec_helper'

class DeleteMethodClass
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

describe DeleteMethodClass do
  describe 'API' do
    it "creates 'cached_delete_by_guid'" do
      expect(DeleteMethodClass).to respond_to(:cached_delete_by_guid)
    end

    it "creates 'cached_delete_by_user_guid'" do
      expect(DeleteMethodClass).to respond_to(:cached_delete_by_user_guid)
    end

    it "creates 'cached_delete_by_user_guid_and_client_guid'" do
      expect(DeleteMethodClass).to respond_to(:cached_delete_by_user_guid_and_client_guid)
    end

    it "creates 'cached_delete_by_client_guid_and_user_guid'" do
      expect(DeleteMethodClass).to respond_to(:cached_delete_by_client_guid_and_user_guid)
    end

    it "creates 'cached_delete_by_derp_and_user_guid_and_client_guid'" do
      expect(DeleteMethodClass).to respond_to(:cached_delete_by_derp_and_user_guid_and_client_guid)
    end

    it "creates 'cached_delete_by_client_guid_and_derp_and_user_guid'" do
      expect(DeleteMethodClass).to respond_to(:cached_delete_by_client_guid_and_derp_and_user_guid)
    end

    it "creates 'cached_delete_by_client_guid_and_user_guid_and_derp'" do
      expect(DeleteMethodClass).to respond_to(:cached_delete_by_client_guid_and_user_guid_and_derp)
    end
  end

  describe '#cached_delete_by_guid' do
    before do
      ::ActiveRemote::Cached.cache(HashCache.new)
    end

    after do
      ::ActiveRemote::Cached.default_options({})
    end

    it 'deletes the find cache key' do
      DeleteMethodClass.cached_find_by_guid(:guid)
      expect(DeleteMethodClass.cached_exist_find_by_guid?(:guid)).to eq(true)

      DeleteMethodClass.cached_delete_by_guid(:guid)

      expect(DeleteMethodClass.cached_exist_find_by_guid?(:guid)).to eq(false)
    end

    it 'deletes the search cache key' do
      DeleteMethodClass.cached_search_by_guid(:guid)
      expect(DeleteMethodClass.cached_exist_search_by_guid?(:guid)).to eq(true)

      DeleteMethodClass.cached_delete_by_guid(:guid)

      expect(DeleteMethodClass.cached_exist_search_by_guid?(:guid)).to eq(false)
    end

    it 'does not raise when the cache keys are not present' do
      expect { DeleteMethodClass.cached_delete_by_guid(:missing) }.not_to raise_error
    end

    describe 'namespaced cache' do
      it 'deletes the namespaced find and search cache keys' do
        expect(::ActiveRemote::Cached.cache).to receive(:delete).with(
          [::ActiveRemote::Cached::RUBY_AND_ACTIVE_SUPPORT_VERSION, 'MyApp', DeleteMethodClass.name, '#find',
           'guid.guid']
        )
        expect(::ActiveRemote::Cached.cache).to receive(:delete).with(
          [::ActiveRemote::Cached::RUBY_AND_ACTIVE_SUPPORT_VERSION, 'MyApp', DeleteMethodClass.name, '#search',
           'guid.guid']
        )

        DeleteMethodClass.cached_delete_by_guid(:guid, :namespace => 'MyApp')
      end
    end
  end
end
