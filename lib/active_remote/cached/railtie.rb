module ActiveRemote
  module Cached
    class Railtie < Rails::Railtie
      initializer "active_remote-cached.initialize_cache" do |app|
        ActiveRemote::Cached.cache(Rails.cache)
        ActiveRemote::Cached.default_options(:race_condition_ttl => 5.seconds)
      end

      ActiveSupport.on_load(:active_remote) do
        include ActiveRemote::Cached
      end
    end
  end
end
