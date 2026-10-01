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

      # The nested cache and the cache provider each get their own failsafe, so
      # a handled error in one does not skip the other.
      def delete(*args)
        failsafe { nested_cache_provider.delete(*args) }
        failsafe { super }
      end

      def enable_nested_caching!
        @nested_cache_provider = ::ActiveSupport::Cache::MemoryStore.new
      end

      def nested_caching?
        !nested_cache_provider.is_a?(::ActiveSupport::Cache::NullStore)
      end

      def exist?(*args)
        failsafe(:returning => false) { nested_cache_provider.exist?(*args) } ||
          failsafe(:returning => false) { super }
      end

      # An error from the block (the RPC call) always goes to the caller. Only
      # an error from a cache provider goes to handle_or_reraise_cache_error.
      # When that error is handled, the block value is returned without the
      # cache, and the block runs at most once.
      def fetch(name, options = {}, &block)
        block_result = FetchBlockResult.new(block)
        provider_options = provider_fetch_options(options)
        fetch_value = provider_fetch(name, provider_options, &block_result.to_block)

        delete_quietly(name) if delete_after_fetch?(fetch_value, options, provider_options)

        fetch_value
      rescue StandardError => e
        # #value raises the block error again, so a block error goes to the
        # caller as it was raised.
        handle_or_reraise_cache_error(e) unless block_result.raised?(e)
        block_result.value
      end

      def read(*args)
        failsafe { nested_cache_provider.read(*args) } || failsafe { super }
      end

      def write(*args)
        failsafe { nested_cache_provider.write(*args) }
        failsafe { super }
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
          run unless @ran
          raise @error if @error

          @value
        end

        # The block to give the provider: nil when fetch got no block, so the
        # provider gets no block either. A proc, because the provider yields
        # the key and #value takes no argument.
        def to_block
          proc { value } if @block
        end

        # True for the block error itself, and for an error that a provider
        # raised while it rescued the block error (Ruby sets it as the cause).
        def raised?(error)
          return false if @error.nil? || error.nil?

          error.equal?(@error) || raised?(error.cause)
        end

        private

        def run
          @ran = true
          @value = @block&.call
        rescue StandardError => e
          @error = e
        end
      end
      private_constant :FetchBlockResult

      # An error from the nested cache is handled here, and the cache provider
      # is still used. An error from the cache provider or the block goes to
      # #fetch.
      def provider_fetch(name, options, &block)
        provider_result = FetchBlockResult.new(proc { cache_provider.fetch(name, options, &block) })

        begin
          nested_cache_provider.fetch(name, options, &provider_result.to_block)
        rescue StandardError => e
          handle_or_reraise_cache_error(e) unless provider_result.raised?(e)
          provider_result.value
        end
      end

      # Removes a nil or empty value after #fetch. If the delete fails, the
      # value stays until its TTL ends, so the error never fails the #fetch.
      def delete_quietly(name)
        delete(name)
      rescue StandardError
        nil
      end

      def failsafe(returning: nil)
        yield
      rescue StandardError => e
        handle_or_reraise_cache_error(e)
        returning
      end

      def handle_or_reraise_cache_error(error)
        raise error unless ::ActiveRemote::Cached.default_options[:handle_cache_error]

        call_cache_error_proc(error)
      end

      # A handled cache error must not fail the call, so an error from the proc
      # (for example, a notifier that is down) is only reported.
      def call_cache_error_proc(error)
        error_proc = ::ActiveRemote::Cached.default_options[:cache_error_proc]
        error_proc.call(error) if error_proc.respond_to?(:call)
      rescue StandardError => e
        warn("ActiveRemote::Cached ignored an error from :cache_error_proc: #{e.class}: #{e.message}")
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
