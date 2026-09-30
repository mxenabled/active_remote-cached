# frozen_string_literal: true

require 'delegate'

module ActiveRemote
  module Cached
    class Cache < ::SimpleDelegator
      # Raised when the given cache provider is missing a method the library
      # calls on it.
      class InvalidCacheProvider < ::StandardError; end

      # Options that control error handling here. They are not passed to the
      # cache provider.
      ERROR_HANDLING_OPTIONS = %i[handle_cache_error cache_error_proc].freeze

      attr_reader :cache_provider

      def initialize(new_cache_provider)
        @cache_provider = new_cache_provider
        @nested_cache_provider = ::ActiveSupport::Cache::NullStore.new

        validate_provider_method_present(:delete)
        validate_provider_method_present(:exist?)
        validate_provider_method_present(:fetch)
        validate_provider_method_present(:read)
        validate_provider_method_present(:write)

        super(@cache_provider)
      end

      def delete(*args)
        nested_cache_provider.delete(*args)
        super
      rescue StandardError => e
        handle_or_reraise_cache_error(e)
        nil
      end

      def enable_nested_caching!
        @nested_cache_provider = ::ActiveSupport::Cache::MemoryStore.new
      end

      def nested_caching?
        !nested_cache_provider.is_a?(::ActiveSupport::Cache::NullStore)
      end

      def exist?(*args)
        nested_cache_provider.exist?(*args) || super
      rescue StandardError => e
        handle_or_reraise_cache_error(e)
        false
      end

      # An error from the block (the RPC call) always goes to the caller. Only
      # an error from a cache provider goes to handle_or_reraise_cache_error.
      # When that error is handled, the block value is returned without the
      # cache, and the block runs at most once.
      def fetch(name, options = {}, &block)
        block_result = FetchBlockResult.new(block)
        provider_options = provider_fetch_options(options)
        fetch_value = provider_fetch(name, provider_options, block && block_result)

        delete(name) if delete_after_fetch?(fetch_value, options, provider_options)

        fetch_value
      rescue StandardError => e
        raise if block_result.raised?(e)

        handle_or_reraise_cache_error(e)
        block_result.value
      end

      def read(*args)
        nested_cache_provider.read(*args) || super
      rescue StandardError => e
        handle_or_reraise_cache_error(e)
        nil
      end

      def write(*args)
        nested_cache_provider.write(*args)
        super
      rescue StandardError => e
        handle_or_reraise_cache_error(e)
        nil
      end

      private

      attr_reader :nested_cache_provider

      # Runs the fetch block at most once, on the first call to #value, and
      # keeps its value or its error.
      class FetchBlockResult
        def initialize(block)
          @block = block
        end

        def value
          run unless defined?(@value)
          raise @error if @error

          @value
        end

        def raised?(error)
          !@error.nil? && @error.equal?(error)
        end

        private

        def run
          @value = @block&.call
        rescue StandardError => e
          @value = nil
          @error = e
        end
      end
      private_constant :FetchBlockResult

      # Without a block, the provider gets no block, as before.
      def provider_fetch(name, options, block_result)
        provider_block = block_result && proc { block_result.value }

        nested_cache_provider.fetch(name, options) do
          cache_provider.fetch(name, options, &provider_block)
        end
      end

      def handle_or_reraise_cache_error(error)
        raise error unless ::ActiveRemote::Cached.default_options[:handle_cache_error]

        error_proc = ::ActiveRemote::Cached.default_options[:cache_error_proc]
        error_proc.call(error) if error_proc.respond_to?(:call)
      end

      # :skip_nil tells the provider not to write a nil at all, which saves a
      # write and the delete that follows it. Only an ActiveSupport store is
      # known to honor the option.
      def provider_fetch_options(options)
        options = options.except(*ERROR_HANDLING_OPTIONS)
        return options if options.fetch(:allow_nil, false)
        return options unless cache_provider.is_a?(::ActiveSupport::Cache::Store)

        options.merge(:skip_nil => true)
      end

      def delete_after_fetch?(value, options, provider_options)
        return false if valid_fetched_value?(value, options)
        # The provider already skipped the write.
        return false if value.nil? && provider_options[:skip_nil]

        true
      end

      def valid_fetched_value?(value, options = {})
        return false if value.nil? && !options.fetch(:allow_nil, false)
        return false if !options.fetch(:allow_empty, false) && value.respond_to?(:empty?) && value.empty?

        true
      end

      def validate_provider_method_present(method_name)
        return if cache_provider.respond_to?(method_name)

        raise InvalidCacheProvider,
              "ActiveRemote::Cached::Cache must respond_to? #{method_name} " \
              'in order to be used as a caching interface for ActiveRemote'
      end
    end
  end
end
