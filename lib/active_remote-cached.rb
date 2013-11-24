require "active_support/core_ext/array/extract_options"
require "active_remote-cached/version"
require "heredity"

module ActiveRemote
  module Cached

    def self.included(klass)
      class << klass
        extend ClassMethods

        
      end
    end

    module ClassMethods
      def cached_finders_for(*cached_finder_keys)
        options = cached_finder_keys.extract_options!

        puts cached_finder_keys
        puts options
      end

    end
  end
end
