# frozen_string_literal: true

require 'active_support/ordered_options'

module ActiveRemote
  module Cached
    class Railtie < ::Rails::Railtie
      config.active_remote_cached = ::ActiveSupport::OrderedOptions.new

      initializer 'active_remote-cached.initialize_cache' do |_app|
        config.active_remote_cached.expires_in ||= 5.minutes
        config.active_remote_cached.race_condition_ttl ||= 5.seconds

        ::ActiveRemote::Cached.cache(Rails.cache)

        ::ActiveRemote::Cached.cache.enable_nested_caching! if config.active_remote_cached.enable_nested_caching

        ::ActiveRemote::Cached.default_options(
          :expires_in => config.active_remote_cached.expires_in,
          :race_condition_ttl => config.active_remote_cached.race_condition_ttl
        )
      end

      ::ActiveSupport.on_load(:active_remote) do
        include ::ActiveRemote::Cached
      end
    end
  end
end
