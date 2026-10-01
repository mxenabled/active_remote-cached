# frozen_string_literal: true

require 'spec_helper'

describe ::ActiveRemote::Cached::Cache do
  let(:invalid_provider_error) { ::ActiveRemote::Cached::Cache::InvalidCacheProvider }
  let(:cache_provider) { ::ActiveSupport::Cache::MemoryStore.new }
  let(:cache) { ::ActiveRemote::Cached::Cache.new(cache_provider) }

  describe 'API' do
    it 'validates #delete present' do
      cache = OpenStruct.new(:write => nil, :fetch => nil, :read => nil, :exist? => nil)
      expect { ::ActiveRemote::Cached.cache(cache) }.to raise_error(invalid_provider_error, /respond_to.*delete/i)
    end

    it 'validates #exist? present' do
      cache = OpenStruct.new(:write => nil, :delete => nil, :read => nil, :fetch => nil)
      expect { ::ActiveRemote::Cached.cache(cache) }.to raise_error(invalid_provider_error, /respond_to.*exist/i)
    end

    it 'validates #fetch present' do
      cache = OpenStruct.new(:write => nil, :delete => nil, :read => nil, :exist? => nil)
      expect { ::ActiveRemote::Cached.cache(cache) }.to raise_error(invalid_provider_error, /respond_to.*fetch/i)
    end

    it 'validates #read present' do
      cache = OpenStruct.new(:write => nil, :delete => nil, :fetch => nil, :exist? => nil)
      expect { ::ActiveRemote::Cached.cache(cache) }.to raise_error(invalid_provider_error, /respond_to.*read/i)
    end

    it 'validates #write present' do
      cache = OpenStruct.new(:read => nil, :delete => nil, :fetch => nil, :exist? => nil)
      expect { ::ActiveRemote::Cached.cache(cache) }.to raise_error(invalid_provider_error, /respond_to.*write/i)
    end
  end

  describe '#nested_caching?' do
    it 'is false before nested caching is enabled' do
      expect(cache.nested_caching?).to eq(false)
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

    it 'does not persist anything on a miss with no block' do
      expect(cache.fetch('key', :allow_nil => true)).to be_nil
      expect(cache_provider.exist?('key')).to eq(false)
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

  describe 'cache error handling' do
    let(:failing_provider) do
      Class.new(::ActiveSupport::Cache::MemoryStore) do
        %i[delete exist? fetch read write].each do |method_name|
          define_method(method_name) { |*| raise ::IOError, "#{method_name} failed" }
        end
      end.new
    end
    let(:cache) { ::ActiveRemote::Cached::Cache.new(failing_provider) }
    let(:handled_errors) { [] }

    after do
      ::ActiveRemote::Cached.default_options_overwrite({})
    end

    context 'when :handle_cache_error is not set' do
      it 'raises the provider error from each method' do
        expect { cache.delete('key') }.to raise_error(::IOError, 'delete failed')
        expect { cache.exist?('key') }.to raise_error(::IOError, 'exist? failed')
        expect { cache.fetch('key') { :value } }.to raise_error(::IOError, 'fetch failed')
        expect { cache.read('key') }.to raise_error(::IOError, 'read failed')
        expect { cache.write('key', :value) }.to raise_error(::IOError, 'write failed')
      end
    end

    context 'when :handle_cache_error is true' do
      before do
        ::ActiveRemote::Cached.default_options(
          :handle_cache_error => true,
          :cache_error_proc => lambda { |error| handled_errors << error.message }
        )
      end

      it 'returns a cache miss from #read' do
        expect(cache.read('key')).to be_nil
        expect(handled_errors).to eq(['read failed'])
      end

      it 'returns false from #exist?' do
        expect(cache.exist?('key')).to eq(false)
        expect(handled_errors).to eq(['exist? failed'])
      end

      it 'returns nil from #write' do
        expect(cache.write('key', :value)).to be_nil
        expect(handled_errors).to eq(['write failed'])
      end

      it 'returns nil from #delete' do
        expect(cache.delete('key')).to be_nil
        expect(handled_errors).to eq(['delete failed'])
      end

      it 'returns the block value from #fetch when the provider fails before the block' do
        calls = 0

        expect(cache.fetch('key') { calls += 1 }).to eq(1)
        expect(calls).to eq(1)
        expect(handled_errors).to eq(['fetch failed'])
      end

      it 'does not call the block again when the provider fails after the block' do
        provider = Class.new(::ActiveSupport::Cache::MemoryStore) do
          def fetch(*)
            yield
            raise ::IOError, 'write after fetch failed'
          end
        end.new
        cache = ::ActiveRemote::Cached::Cache.new(provider)
        calls = 0

        expect(cache.fetch('key') { calls += 1 }).to eq(1)
        expect(calls).to eq(1)
        expect(handled_errors).to eq(['write after fetch failed'])
      end

      it 'raises an error from the #fetch block, does not handle it, and does not cache it' do
        provider = ::ActiveSupport::Cache::MemoryStore.new
        cache = ::ActiveRemote::Cached::Cache.new(provider)
        rpc_error = ::ActiveRemote::ActiveRemoteError

        expect { cache.fetch('key') { raise rpc_error, 'rpc failed' } }.to raise_error(rpc_error)
        expect(handled_errors).to be_empty
        expect(provider.exist?('key')).to eq(false)
      end

      it 'raises an error from the #fetch block when the provider fails before the block' do
        not_found = ::ActiveRemote::RemoteRecordNotFound

        expect { cache.fetch('key') { raise not_found } }.to raise_error(not_found)
        expect(handled_errors).to eq(['fetch failed'])
      end

      it 'does not pass the error handling options to the provider' do
        provider = ::ActiveSupport::Cache::MemoryStore.new
        cache = ::ActiveRemote::Cached::Cache.new(provider)

        expect(provider).to receive(:fetch).with('key', { :skip_nil => true }).and_call_original

        cache.fetch('key', :handle_cache_error => true, :cache_error_proc => lambda {}) { :value }
      end

      it 'returns the block value when :cache_error_proc raises' do
        ::ActiveRemote::Cached.default_options(:cache_error_proc => lambda { |_| raise 'notifier down' })
        provider = Class.new(::ActiveSupport::Cache::MemoryStore) do
          def fetch(*)
            yield
            raise ::IOError, 'write after fetch failed'
          end
        end.new
        cache = ::ActiveRemote::Cached::Cache.new(provider)

        expect { expect(cache.fetch('key') { :value }).to eq(:value) }
          .to output(/ignored an error from :cache_error_proc: RuntimeError: notifier down/).to_stderr
      end

      it 'does not report a block error that the provider wraps in a new error' do
        provider = Class.new(::ActiveSupport::Cache::MemoryStore) do
          def fetch(*)
            yield
          rescue StandardError => e
            raise ::IOError, "wrapped #{e.class}"
          end
        end.new
        cache = ::ActiveRemote::Cached::Cache.new(provider)
        not_found = ::ActiveRemote::RemoteRecordNotFound

        expect { cache.fetch('key') { raise not_found } }.to raise_error(not_found)
        expect(handled_errors).to be_empty
      end

      it 'handles the error without a :cache_error_proc' do
        ::ActiveRemote::Cached.default_options_overwrite(:handle_cache_error => true)

        expect(cache.read('key')).to be_nil
      end
    end

    context 'with nested caching' do
      let(:backing_provider) { ::ActiveSupport::Cache::MemoryStore.new }
      let(:cache) do
        ::ActiveRemote::Cached::Cache.new(backing_provider).tap(&:enable_nested_caching!)
      end
      let(:nested_provider) { cache.send(:nested_cache_provider) }

      before do
        ::ActiveRemote::Cached.default_options(
          :handle_cache_error => true,
          :cache_error_proc => lambda { |error| handled_errors << error.message }
        )
        %i[delete exist? fetch read write].each do |method_name|
          allow(nested_provider).to receive(method_name).and_raise(::IOError, "nested #{method_name} failed")
        end
      end

      it 'still writes to and deletes from the cache provider when the nested cache fails' do
        cache.write('key', 'value')
        expect(backing_provider.read('key')).to eq('value')

        cache.delete('key')
        expect(backing_provider.exist?('key')).to eq(false)
        expect(handled_errors).to eq(['nested write failed', 'nested delete failed'])
      end

      it 'still reads from the cache provider when the nested cache fails' do
        backing_provider.write('key', 'value')

        expect(cache.read('key')).to eq('value')
        expect(cache.exist?('key')).to eq(true)
      end

      it 'still fetches through the cache provider when the nested cache fails' do
        calls = 0

        expect(cache.fetch('key') { calls += 1 }).to eq(1)
        expect(cache.fetch('key') { calls += 1 }).to eq(1)
        expect(calls).to eq(1)
        expect(handled_errors).to eq(['nested fetch failed', 'nested fetch failed'])
      end

      it 'raises a block error from inside the nested fetch, and does not report it' do
        allow(nested_provider).to receive(:fetch).and_call_original
        not_found = ::ActiveRemote::RemoteRecordNotFound

        expect { cache.fetch('key') { raise not_found } }.to raise_error(not_found)
        expect(handled_errors).to be_empty
      end
    end

    context 'when :handle_cache_error is false' do
      it 'returns the fetched value when the cleanup delete fails' do
        ::ActiveRemote::Cached.default_options(:handle_cache_error => false)
        provider = Class.new(::ActiveSupport::Cache::MemoryStore) do
          def delete(*)
            raise ::IOError, 'delete failed'
          end
        end.new
        cache = ::ActiveRemote::Cached::Cache.new(provider)

        expect(cache.fetch('key') { [] }).to eq([])
      end

      it 'raises the error and does not call :cache_error_proc' do
        ::ActiveRemote::Cached.default_options(
          :handle_cache_error => false,
          :cache_error_proc => lambda { |error| handled_errors << error.message }
        )

        expect { cache.read('key') }.to raise_error(::IOError, 'read failed')
        expect(handled_errors).to be_empty
      end
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

      it 'reports that nested caching is on' do
        expect(cache.nested_caching?).to eq(true)
      end

      # A new Cache starts with nested caching off, so swapping the provider
      # used to turn the setting off without saying so.
      it 'keeps nested caching on when the cache provider is replaced' do
        original_cache = ::ActiveRemote::Cached.cache

        ::ActiveRemote::Cached.cache(cache_provider)
        ::ActiveRemote::Cached.cache.enable_nested_caching!
        ::ActiveRemote::Cached.cache(::ActiveSupport::Cache::MemoryStore.new)

        expect(::ActiveRemote::Cached.cache.nested_caching?).to eq(true)
      ensure
        # .cache now carries the nested setting forward, so reset the module
        # rather than call it again.
        ::ActiveRemote::Cached.instance_variable_set(:@cache_provider, original_cache)
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
