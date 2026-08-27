# frozen_string_literal: true

require 'delegate'

module ActiveRemote
  module Cached
    class Cache < ::SimpleDelegator
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
      end

      def enable_nested_caching!
        @nested_cache_provider = ::ActiveSupport::Cache::MemoryStore.new
      end

      def exist?(*args)
        nested_cache_provider.exist?(*args) || super
      end

      def fetch(name, options = {})
        provider_options = provider_fetch_options(options)
        fetch_value = nested_cache_provider.fetch(name, provider_options) { super(name, provider_options) }

        delete(name) if delete_after_fetch?(fetch_value, options, provider_options)

        fetch_value
      end

      def read(*args)
        nested_cache_provider.read(*args) || super
      end

      def write(*args)
        nested_cache_provider.write(*args)
        super
      end

      private

      attr_reader :nested_cache_provider

      # :skip_nil tells the provider not to write a nil at all, which saves a
      # write and the delete that follows it. Only an ActiveSupport store is
      # known to honor the option.
      def provider_fetch_options(options)
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

          raise <<-CACHE_METHOD
          ActiveRemote::Cached::Cache must respond_to? #{method_name}
          in order to be used as a caching interface for ActiveRemote
          CACHE_METHOD
      end
    end
  end
end
