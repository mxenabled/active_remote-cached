require "active_support"
require "active_support/cache"
require "active_support/concern"
require "active_support/core_ext/array/extract_options"

require "active_remote/cached/cache"
require "active_remote/cached/version"

require "active_remote/cached/railtie" if defined?(Rails)

module ActiveRemote
  module Cached
    extend ::ActiveSupport::Concern

    def self.cache(cache_provider = nil)
      if cache_provider
        @cache_provider = ::ActiveRemote::Cached::Cache.new(cache_provider)
      end

      @cache_provider
    end

    def self.default_options(options = nil)
      if options
        @default_options = options
      end

      @default_options || {}
    end

    module ClassMethods
      def cached_finders_for(*cached_finder_keys)
        options = cached_finder_keys.extract_options!

        cached_finder_keys.each do |cached_finder_key|
          _create_cached_finder_for(cached_finder_key, options)
        end
      end

      def cached_finders(*keys)
        cached_finders_for(*keys)
      end

      def cached_find(argument_hash, options = {})
        method_name = _cached_find_method_name(argument_hash.keys)
        arguments = argument_hash.values

        if block_given?
          __send__(method_name, *arguments, options) do
            yield
          end
        else
          __send__(method_name, *arguments, options)
        end
      end

      def cached_search(argument_hash, options = {})
        method_name = _cached_search_method_name(argument_hash.keys)
        arguments = argument_hash.values

        if block_given?
          __send__(method_name, *arguments, options) do
            yield
          end
        else
          __send__(method_name, *arguments, options)
        end
      end

      ##
      # Underscored Methods
      #
      def _create_cached_finder_for(cached_finder_key, options = {})
        cached_finder_key_set = [ cached_finder_key ].flatten.sort

        ##
        # Run each permutation of the arguments passed in
        # and define each finder/searcher
        #
        cached_finder_key_set.permutation do |arguments|
          delete_method_name = _cached_delete_method_name(arguments)
          exist_find_method_name = _cached_exist_find_method_name(arguments)
          exist_search_method_name = _cached_exist_search_method_name(arguments)
          find_method_name = _cached_find_method_name(arguments)
          search_method_name = _cached_search_method_name(arguments)

          unless self.respond_to?(delete_method_name)
            _define_cached_delete_method(delete_method_name, arguments)
          end

          unless self.respond_to?(exist_find_method_name)
            _define_cached_exist_find_method(exist_find_method_name, arguments)
          end

          unless self.respond_to?(exist_search_method_name)
            _define_cached_exist_search_method(exist_search_method_name, arguments)
          end

          unless self.respond_to?(find_method_name)
            _define_cached_find_method(find_method_name, arguments)
          end

          unless self.respond_to?(search_method_name)
            _define_cached_search_method(search_method_name, arguments)
          end
        end
      end

      def _cached_delete_method_name(arguments)
        "cached_delete_by_#{arguments.join('_and_')}"
      end

      def _cached_exist_find_method_name(arguments)
        "cached_exist_find_by_#{arguments.join('_and_')}"
      end

      def _cached_exist_search_method_name(arguments)
        "cached_exist_search_by_#{arguments.join('_and_')}"
      end

      def _cached_find_method_name(arguments)
        "cached_find_by_#{arguments.join('_and_')}"
      end

      def _cached_search_method_name(arguments)
        "cached_search_by_#{arguments.join('_and_')}"
      end

      def _define_cached_delete_method(method_name, *method_arguments)
        method_arguments.flatten!
        expanded_method_args = method_arguments.join(",")
        sorted_method_args = method_arguments.sort.join(",")

        self.class_eval <<-RUBY, __FILE__, __LINE__ + 1
          # def self.cached_delete_by_user_guid(user_guid, options = {})
          #   ::ActiveRemote::Cached.cache.delete([name, user_guid])
          # end
          def self.#{method_name}(#{expanded_method_args}, options = {})
            ::ActiveRemote::Cached.cache.delete([name, "#search", #{sorted_method_args}])
            ::ActiveRemote::Cached.cache.delete([name, "#find", #{sorted_method_args}])
          end
        RUBY
      end

      def _define_cached_exist_find_method(method_name, *method_arguments)
        method_arguments.flatten!
        expanded_method_args = method_arguments.join(",")
        sorted_method_args = method_arguments.sort.join(",")

        self.class_eval <<-RUBY, __FILE__, __LINE__ + 1
          # def self.cached_exist_find_by_user_guid(user_guid, options = {})
          #   ::ActiveRemote::Cached.cache.exist?([name, user_guid])
          # end
          def self.#{method_name}(#{expanded_method_args}, options = {})
            ::ActiveRemote::Cached.cache.exist?([name, "#find", #{sorted_method_args}])
          end
        RUBY

        self.class_eval <<-RUBY, __FILE__, __LINE__ + 1
          # def self.cached_exist_find_by_user_guid?(user_guid, options = {})
          #   ::ActiveRemote::Cached.cache.exist?([name, user_guid])
          # end
          def self.#{method_name}?(#{expanded_method_args}, options = {})
            ::ActiveRemote::Cached.cache.exist?([name, "#find", #{sorted_method_args}])
          end
        RUBY
      end

      def _define_cached_exist_search_method(method_name, *method_arguments)
        method_arguments.flatten!
        expanded_method_args = method_arguments.join(",")
        sorted_method_args = method_arguments.sort.join(",")

        self.class_eval <<-RUBY, __FILE__, __LINE__ + 1
          # def self.cached_exist_search_by_user_guid(user_guid, options = {})
          #   ::ActiveRemote::Cached.cache.exist?([name, user_guid])
          # end
          def self.#{method_name}(#{expanded_method_args}, options = {})
            ::ActiveRemote::Cached.cache.exist?([name, "#search", #{sorted_method_args}])
          end
        RUBY

        self.class_eval <<-RUBY, __FILE__, __LINE__ + 1
          # def self.cached_exist_search_by_user_guid?(user_guid, options = {})
          #   ::ActiveRemote::Cached.cache.exist?([name, user_guid])
          # end
          def self.#{method_name}?(#{expanded_method_args}, options = {})
            ::ActiveRemote::Cached.cache.exist?([name, "#search", #{sorted_method_args}])
          end
        RUBY
      end

      def _define_cached_find_method(method_name, *method_arguments)
        method_arguments.flatten!
        expanded_method_args = method_arguments.join(",")
        sorted_method_args = method_arguments.sort.join(",")

        expanded_search_args = ""
        method_arguments.each do |method_argument|
          expanded_search_args << ":#{method_argument} => #{method_argument},"
        end

        self.class_eval <<-RUBY, __FILE__, __LINE__ + 1
          # def self.cached_find_by_user_guid(user_guid, options = {})
          #   options = ::ActiveRemote::Cached.default_options.merge(options)
          #
          #   ::ActiveRemote::Cached.cache.fetch([name, "#find", user_guid], options) do
          #     self.find(:user_guid => user_guid)
          #   end
          # end
          #
          # If a block is given, it is incumbent on the caller to make sure the expectation
          # of the result object is maintained for requests/responses
          #
          def self.#{method_name}(#{expanded_method_args}, options = {})
            options = ::ActiveRemote::Cached.default_options.merge(options)

            ::ActiveRemote::Cached.cache.fetch([name, "#find", #{sorted_method_args}], options) do
              if block_given?
                yield
              else
                self.find(#{expanded_search_args})
              end
            end
          end
        RUBY
      end

      def _define_cached_search_method(method_name, *method_arguments)
        method_arguments.flatten!
        expanded_method_args = method_arguments.join(",")
        sorted_method_args = method_arguments.sort.join(",")

        expanded_search_args = ""
        method_arguments.each do |method_argument|
          expanded_search_args << ":#{method_argument} => #{method_argument},"
        end

        self.class_eval <<-RUBY, __FILE__, __LINE__ + 1
          # def self.cached_search_by_user_guid(user_guid, options = {})
          #   options = ::ActiveRemote::Cached.default_options.merge(options)
          #
          #   ::ActiveRemote::Cached.cache.fetch([name, "#search", user_guid], options) do
          #     self.search(:user_guid => user_guid)
          #   end
          # end
          #
          # If a block is given, it is incumbent on the caller to make sure the expectation
          # of the result object is maintained for requests/responses
          #
          def self.#{method_name}(#{expanded_method_args}, options = {})
            options = ::ActiveRemote::Cached.default_options.merge(options)

            ::ActiveRemote::Cached.cache.fetch([name, "#search", #{sorted_method_args}], options) do
              if block_given?
                yield
              else
                self.search(#{expanded_search_args})
              end
            end
          end
        RUBY
      end
    end

    # Initialize the cache provider with a MemoryStore cache
    cache(ActiveSupport::Cache::MemoryStore.new)
  end
end
