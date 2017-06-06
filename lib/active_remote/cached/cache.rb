require 'delegate'

module ActiveRemote::Cached
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
      fetch_value = nested_cache_provider.fetch(name, options) { super }

      unless valid_fetched_value?(fetch_value, options)
        delete(name)
      end

      return fetch_value
    end

    def read(*args)
      nested_cache_provider.read(*args) || super
    end

    def write(*args)
      nested_cache_provider.write(*args)
      super
    end

  private

    def nested_cache_provider
      @nested_cache_provider
    end

    def valid_fetched_value?(value, options = {})
      return false if value.nil? && !options.fetch(:allow_nil, false)
      return false if !options.fetch(:allow_empty, false) && value.respond_to?(:empty?) && value.empty?
      return true
    end

    def validate_provider_method_present(method_name)
      unless self.cache_provider.respond_to?(method_name)
        raise <<-CACHE_METHOD
          ActiveRemote::Cached::Cache must respond_to? #{method_name}
          in order to be used as a caching interface for ActiveRemote
        CACHE_METHOD
      end
    end
  end
end
