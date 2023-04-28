require 'active_support/ordered_options'

module ActiveRemote
  module Cached
    class Railtie < ::Rails::Railtie
      config.active_remote_cached = ::ActiveSupport::OrderedOptions.new

      initializer "active_remote-cached.initialize_cache" do |app|
        config.active_remote_cached.cache_error_proc ||= nil
        config.active_remote_cached.expires_in ||= 5.minutes
        config.active_remote_cached.handle_cache_error ||= false
        config.active_remote_cached.race_condition_ttl ||= 5.seconds

        ::ActiveRemote::Cached.cache(::Rails.cache)

        if config.active_remote_cached.enable_nested_caching
          ::ActiveRemote::Cached.cache.enable_nested_caching!
        end

        ::ActiveRemote::Cached.default_options(
          :cache_error_proc   => config.active_remote_cached.cache_error_proc,
          :expires_in         => config.active_remote_cached.expires_in,
          :handle_cache_error => config.active_remote_cached.handle_cache_error,
          :race_condition_ttl => config.active_remote_cached.race_condition_ttl
        )
      end

      ::ActiveSupport.on_load(:active_remote) do
        include ::ActiveRemote::Cached
      end
    end
  end
end
