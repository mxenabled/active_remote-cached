# frozen_string_literal: true

require 'spec_helper'

describe ::ActiveRemote::Cached::Cache do
  let(:cache_provider) { ::ActiveSupport::Cache::MemoryStore.new }
  let(:cache) { ::ActiveRemote::Cached::Cache.new(cache_provider) }

  describe 'API' do
    it 'validates #delete present' do
      cache = OpenStruct.new(:write => nil, :fetch => nil, :read => nil, :exist? => nil)
      expect { ::ActiveRemote::Cached.cache(cache) }.to raise_error(RuntimeError, /respond_to.*delete/i)
    end

    it 'validates #exist? present' do
      cache = OpenStruct.new(:write => nil, :delete => nil, :read => nil, :fetch => nil)
      expect { ::ActiveRemote::Cached.cache(cache) }.to raise_error(RuntimeError, /respond_to.*exist/i)
    end

    it 'validates #fetch present' do
      cache = OpenStruct.new(:write => nil, :delete => nil, :read => nil, :exist? => nil)
      expect { ::ActiveRemote::Cached.cache(cache) }.to raise_error(RuntimeError, /respond_to.*fetch/i)
    end

    it 'validates #read present' do
      cache = OpenStruct.new(:write => nil, :delete => nil, :fetch => nil, :exist? => nil)
      expect { ::ActiveRemote::Cached.cache(cache) }.to raise_error(RuntimeError, /respond_to.*read/i)
    end

    it 'validates #write present' do
      cache = OpenStruct.new(:read => nil, :delete => nil, :fetch => nil, :exist? => nil)
      expect { ::ActiveRemote::Cached.cache(cache) }.to raise_error(RuntimeError, /respond_to.*write/i)
    end
  end

  describe 'delegation' do
    it 'exposes the cache provider it was given' do
      expect(cache.cache_provider).to be(cache_provider)
    end

    it 'delegates unknown methods to the cache provider' do
      expect(cache_provider).to receive(:clear).and_return(:cleared)
      expect(cache.clear).to eq(:cleared)
    end
  end

  describe '#fetch' do
    it 'returns a nil value but does not persist it by default' do
      expect(cache.fetch('key') { nil }).to be_nil
      expect(cache_provider.exist?('key')).to eq(false)
    end

    it 'returns an empty value but does not persist it by default' do
      expect(cache.fetch('key') { [] }).to eq([])
      expect(cache_provider.exist?('key')).to eq(false)
    end

    it 'persists a nil value when :allow_nil is given' do
      expect(cache.fetch('key', :allow_nil => true) { nil }).to be_nil
      expect(cache_provider.exist?('key')).to eq(true)
    end

    it 'persists an empty value when :allow_empty is given' do
      expect(cache.fetch('key', :allow_empty => true) { [] }).to eq([])
      expect(cache_provider.exist?('key')).to eq(true)
    end

    it 'persists a value that is neither nil nor empty' do
      expect(cache.fetch('key') { [:record] }).to eq([:record])
      expect(cache_provider.exist?('key')).to eq(true)
    end
  end

  describe '#fetch round trips' do
    let(:counting_provider) do
      Class.new(::ActiveSupport::Cache::MemoryStore) do
        def initialize(*args)
          @calls = []
          super
        end

        attr_reader :calls

        def fetch(*args, **options, &block)
          @calls << :fetch
          super
        end

        def write(*args, **options)
          @calls << :write
          super
        end

        def delete(*args, **options)
          @calls << :delete
          super
        end
      end.new
    end

    # The provider used to write the nil and then take a second round trip to
    # delete it. :skip_nil makes the provider skip the write.
    it 'takes one provider call for a nil value' do
      cache = ::ActiveRemote::Cached::Cache.new(counting_provider)

      cache.fetch('key') { nil }

      expect(counting_provider.calls).to eq([:fetch])
    end

    it 'still writes a nil when :allow_nil is given' do
      cache = ::ActiveRemote::Cached::Cache.new(counting_provider)

      cache.fetch('key', :allow_nil => true) { nil }

      expect(counting_provider.calls).to eq(%i[fetch write])
      expect(counting_provider.exist?('key')).to eq(true)
    end
  end

  describe '#enable_nested_caching!' do
    it 'writes to the cache provider only until nested caching is enabled' do
      cache.write('key', 'value')

      expect(cache_provider.read('key')).to eq('value')
    end

    context 'when nested caching is enabled' do
      before do
        cache.enable_nested_caching!
      end

      it 'writes to both the nested cache and the cache provider' do
        cache.write('key', 'value')

        expect(cache.read('key')).to eq('value')
        expect(cache_provider.read('key')).to eq('value')
      end

      it 'deletes from both the nested cache and the cache provider' do
        cache.write('key', 'value')
        cache.delete('key')

        expect(cache.read('key')).to be_nil
        expect(cache_provider.read('key')).to be_nil
      end

      it 'reads the nested value in preference to the cache provider value' do
        cache.write('key', 'nested')
        cache_provider.write('key', 'provider')

        expect(cache.read('key')).to eq('nested')
      end

      it 'reports a key that only the cache provider holds' do
        cache_provider.write('key', 'provider')

        expect(cache.exist?('key')).to eq(true)
      end

      # #read joins the two providers with ||, so a false value in the nested
      # cache falls through to the cache provider. This records that behavior.
      it 'falls through to the cache provider when the nested value is false' do
        cache.write('key', false)
        cache_provider.write('key', 'provider')

        expect(cache.read('key')).to eq('provider')
      end
    end
  end
end
