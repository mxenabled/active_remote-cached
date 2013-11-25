require 'delegate'

module ActiveRemote::Cached
  class Cache < ::SimpleDelegator
    attr_reader :cache_provider

    def initialize(new_cache_provider)
      @cache_provider = new_cache_provider
      validate_provider_method_present(:delete)
      validate_provider_method_present(:fetch)
      validate_provider_method_present(:read)
      validate_provider_method_present(:write)
      
      super(@cache_provider)
    end

    def exist?(key)
      if self.cache_provider.respond_to?(:exist?)
        self.cache_provider.exist?(key)
      else
        !self.cache_provider.read(key).nil?
      end
    end

    private

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
