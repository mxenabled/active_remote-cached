# frozen_string_literal: true

require 'active_support'
require 'active_support/cache'
require 'active_support/concern'
require 'active_support/core_ext/array/extract_options'

require 'active_remote/cached/argument_keys'
require 'active_remote/cached/cache'
require 'active_remote/cached/version'
require 'active_remote/errors'

module ActiveRemote
  module Cached
    extend ::ActiveSupport::Concern

    # When upgrading Rails versions, don't reuse the same cache key,
    # because you can't rely upon the serialized objects to be consistent across versions.
    # To fix, this adds a cache key that caches the ruby engine version
    # and the activesupport version to prevent cache re-use across different versions.
    RUBY_AND_ACTIVE_SUPPORT_VERSION = "#{RUBY_ENGINE_VERSION}:#{ActiveSupport::VERSION::STRING}".freeze

    def self.cache(cache_provider = nil)
      @cache_provider = ::ActiveRemote::Cached::Cache.new(cache_provider) if cache_provider

      @cache_provider
    end

    def self.default_options(options = nil)
      @default_options = options if options

      @default_options || {}
    end

    module ClassMethods
      def cached_methods
        @cached_methods ||= []
        @cached_methods
      end

      # The options each cached finder was declared with, keyed by method name.
      # The generated methods read this at call time. Interpolating the options
      # into the generated source instead would require every value to have a
      # literal form, and a value such as 5.minutes does not.
      def cached_finder_options
        @cached_finder_options ||= {}
      end

      # A subclass inherits the finder methods its parent defined, but not the
      # parent registry, so the lookup walks up the superclass chain.
      def _cached_finder_options_for(method_name)
        klass = self

        while klass.respond_to?(:cached_finder_options)
          options = klass.cached_finder_options[method_name]
          return options if options

          klass = klass.superclass
        end

        {}
      end

      def cached_finders_for(*cached_finder_keys)
        options = cached_finder_keys.extract_options!

        cached_finder_keys.each do |cached_finder_key|
          _create_cached_finder_for(cached_finder_key, options)
        end
      end

      def cached_finders(*keys)
        cached_finders_for(*keys)
      end

      def cached_find(argument_hash, options = {}, &block)
        method_name = _cached_find_method_name(argument_hash.keys)
        arguments = argument_hash.keys.sort.map { |k| argument_hash[k] }

        if block_given?
          __send__(method_name, *arguments, options, &block)
        else
          __send__(method_name, *arguments, options)
        end
      end

      def cached_search(argument_hash, options = {}, &block)
        method_name = _cached_search_method_name(argument_hash.keys)
        arguments = argument_hash.keys.sort.map { |k| argument_hash[k] }

        if block_given?
          __send__(method_name, *arguments, options, &block)
        else
          __send__(method_name, *arguments, options)
        end
      end

      def method_missing(m, *args, &block)
        method_name = _method_missing_name(m)

        if method_name.nil? || !cached_methods.include?(method_name.to_s)
          super(m, *args, &block)
        else
          new_args = _args_in_sorted_order(m, args)
          __send__(method_name, *new_args, &block)
        end
      end

      def respond_to_missing?(m, include_private = false)
        method_name = _method_missing_name(m)

        if !method_name.nil? && cached_methods.include?(method_name.to_s)
          true
        else
          super
        end
      end

      ##
      # Underscored Methods
      #
      def _method_missing_name(m)
        regex = /(cached_(?:delete|exist_search|search|exist_find|find)_by_)([0-9a-zA-Z_]*)(!|\?)?/

        return unless m.to_s =~ regex

        params = ::Regexp.last_match(2).split('_and_')
        "#{::Regexp.last_match(1)}#{params.sort.join('_and_')}#{::Regexp.last_match(3)}".to_sym
      end

      def _args_in_sorted_order(m, args)
        regex = /cached_(?:delete|exist_search|search|exist_find|find)_by_([0-9a-zA-Z_]*)(!|\?)?/

        called_match = m.match(regex)
        sorted_match = _method_missing_name(m).match(regex)

        return args unless called_match[1] && sorted_match[1]

        called_field_names = called_match[1].split('_and_')
        sorted_field_names = sorted_match[1].split('_and_')

        _reorder_args(m, args, called_field_names, sorted_field_names)
      end

      def _reorder_args(m, args, called_field_names, sorted_field_names)
        if args.size < called_field_names.size
          raise ::ArgumentError,
                "wrong number of arguments to #{m} (given #{args.size}, expected #{called_field_names.size})"
        end

        args_in_order = sorted_field_names.map do |field_name|
          index = called_field_names.index(field_name)
          raise ::ArgumentError, "#{m} has no argument named #{field_name}" if index.nil?

          args[index]
        end

        # Add the options hash if the caller passed one.
        args_in_order << args.last if args.size > called_field_names.size

        args_in_order
      end

      # rubocop:disable Metrics/AbcSize
      def _create_cached_finder_for(cached_finder_key, options = {})
        cached_finder_key_set = [cached_finder_key].flatten.sort

        delete_method_name = _cached_delete_method_name(cached_finder_key_set)
        exist_find_method_name = _cached_exist_find_method_name(cached_finder_key_set)
        exist_search_method_name = _cached_exist_search_method_name(cached_finder_key_set)
        find_method_name = _cached_find_method_name(cached_finder_key_set)
        search_method_name = _cached_search_method_name(cached_finder_key_set)
        search_bang_method_name = "#{search_method_name}!"

        unless cached_methods.include?(delete_method_name)
          _define_cached_delete_method(delete_method_name, cached_finder_key_set, options)
        end

        unless cached_methods.include?(exist_find_method_name)
          _define_cached_exist_find_method(exist_find_method_name, cached_finder_key_set, options)
        end

        unless cached_methods.include?(exist_search_method_name)
          _define_cached_exist_search_method(exist_search_method_name, cached_finder_key_set, options)
        end

        unless cached_methods.include?(find_method_name)
          _define_cached_find_method(find_method_name, cached_finder_key_set, options)
        end

        unless cached_methods.include?(search_bang_method_name)
          _define_cached_search_bang_method(search_bang_method_name, cached_finder_key_set, options)
        end

        return if cached_methods.include?(search_method_name)

        _define_cached_search_method(search_method_name, cached_finder_key_set, options)
      end
      # rubocop:enable Metrics/AbcSize

      def _cached_delete_method_name(arguments)
        "cached_delete_by_#{arguments.sort.join('_and_')}"
      end

      def _cached_exist_find_method_name(arguments)
        "cached_exist_find_by_#{arguments.sort.join('_and_')}"
      end

      def _cached_exist_search_method_name(arguments)
        "cached_exist_search_by_#{arguments.sort.join('_and_')}"
      end

      def _cached_find_method_name(arguments)
        "cached_find_by_#{arguments.sort.join('_and_')}"
      end

      def _cached_search_method_name(arguments)
        "cached_search_by_#{arguments.sort.join('_and_')}"
      end

      def _expanded_search_args(method_arguments)
        method_arguments.map { |method_argument| ":#{method_argument} => #{method_argument}," }.join
      end

      # Returns the source text that builds the cache key for a generated
      # method. The key names each field, so that two finders that take the
      # same values do not share one cache entry.
      def _expanded_cache_key_args(method_arguments)
        sorted_arguments = method_arguments.sort
        field_names = sorted_arguments.map { |argument| ":#{argument}" }.join(',')

        '::ActiveRemote::Cached::ArgumentKeys.for_fields(' \
          "[#{field_names}], [#{sorted_arguments.join(',')}], __active_remote_cached_options" \
          ').cache_key'
      end

      def _define_cached_delete_method(method_name, *method_arguments, cached_finder_options_hash)
        method_arguments.flatten!
        expanded_method_args = method_arguments.join(',')
        expanded_cache_key_args = _expanded_cache_key_args(method_arguments)

        class_eval <<-RUBY, __FILE__, __LINE__ + 1
          # def self.cached_delete_by_user_guid(user_guid, options = {})
          #   ::ActiveRemote::Cached.cache.delete([name, user_guid])
          # end
          def self.#{method_name}(#{expanded_method_args}, __active_remote_cached_options = {})
            __active_remote_cached_options = ::ActiveRemote::Cached.default_options.merge(_cached_finder_options_for('#{method_name}')).merge(__active_remote_cached_options)
            namespace = __active_remote_cached_options.delete(:namespace)
            find_cache_key = [
              RUBY_AND_ACTIVE_SUPPORT_VERSION,
              namespace,
              name,
              "#find",
              #{expanded_cache_key_args}
            ].compact

            search_cache_key = [
              RUBY_AND_ACTIVE_SUPPORT_VERSION,
              namespace,
              name,
              "#search",
              #{expanded_cache_key_args}
            ].compact

            ::ActiveRemote::Cached.cache.delete(find_cache_key)
            ::ActiveRemote::Cached.cache.delete(search_cache_key)
          end
        RUBY

        cached_finder_options[method_name] = cached_finder_options_hash
        cached_methods << method_name
      end

      def _define_cached_exist_find_method(method_name, *method_arguments, cached_finder_options_hash)
        method_arguments.flatten!
        expanded_method_args = method_arguments.join(',')
        expanded_cache_key_args = _expanded_cache_key_args(method_arguments)

        class_eval <<-RUBY, __FILE__, __LINE__ + 1
          # def self.cached_exist_find_by_user_guid(user_guid, options = {})
          #   ::ActiveRemote::Cached.cache.exist?([name, user_guid])
          # end
          def self.#{method_name}(#{expanded_method_args}, __active_remote_cached_options = {})
            __active_remote_cached_options = ::ActiveRemote::Cached.default_options.merge(_cached_finder_options_for('#{method_name}')).merge(__active_remote_cached_options)
            namespace = __active_remote_cached_options.delete(:namespace)
            cache_key = [
              RUBY_AND_ACTIVE_SUPPORT_VERSION,
              namespace,
              name,
              "#find",
              #{expanded_cache_key_args}
            ].compact

            ::ActiveRemote::Cached.cache.exist?(cache_key)
          end
        RUBY

        singleton_class.send(:alias_method, "#{method_name}?", method_name)

        cached_finder_options[method_name] = cached_finder_options_hash
        cached_methods << method_name
        cached_methods << "#{method_name}?"
      end

      def _define_cached_exist_search_method(method_name, *method_arguments, cached_finder_options_hash)
        method_arguments.flatten!
        expanded_method_args = method_arguments.join(',')
        expanded_cache_key_args = _expanded_cache_key_args(method_arguments)

        class_eval <<-RUBY, __FILE__, __LINE__ + 1
          # def self.cached_exist_search_by_user_guid(user_guid, options = {})
          #   ::ActiveRemote::Cached.cache.exist?([namespace, name, "#search", user_guid])
          # end
          def self.#{method_name}(#{expanded_method_args}, __active_remote_cached_options = {})
            __active_remote_cached_options = ::ActiveRemote::Cached.default_options.merge(_cached_finder_options_for('#{method_name}')).merge(__active_remote_cached_options)
            namespace = __active_remote_cached_options.delete(:namespace)
            cache_key = [
              RUBY_AND_ACTIVE_SUPPORT_VERSION,
              namespace,
              name,
              "#search",
              #{expanded_cache_key_args}
            ].compact

            ::ActiveRemote::Cached.cache.exist?(cache_key)
          end
        RUBY

        singleton_class.send(:alias_method, "#{method_name}?", method_name)

        cached_finder_options[method_name] = cached_finder_options_hash
        cached_methods << method_name
        cached_methods << "#{method_name}?"
      end

      def _define_cached_find_method(method_name, *method_arguments, cached_finder_options_hash)
        method_arguments.flatten!
        expanded_method_args = method_arguments.join(',')
        expanded_cache_key_args = _expanded_cache_key_args(method_arguments)

        expanded_search_args = _expanded_search_args(method_arguments)

        class_eval <<-RUBY, __FILE__, __LINE__ + 1
          # def self.cached_find_by_user_guid(user_guid, options = {})
          #   options = ::ActiveRemote::Cached.default_options.merge({}).merge(options)
          #
          #   ::ActiveRemote::Cached.cache.fetch([namespace, name, "#find", user_guid], options) do
          #     self.find(:user_guid => user_guid)
          #   end
          # end
          #
          # If a block is given, it is incumbent on the caller to make sure the expectation
          # of the result object is maintained for requests/responses
          #
          def self.#{method_name}(#{expanded_method_args}, __active_remote_cached_options = {})
            __active_remote_cached_options = ::ActiveRemote::Cached.default_options.merge(_cached_finder_options_for('#{method_name}')).merge(__active_remote_cached_options)
            namespace = __active_remote_cached_options.delete(:namespace)
            cache_key = [
              RUBY_AND_ACTIVE_SUPPORT_VERSION,
              namespace,
              name,
              "#find",
              #{expanded_cache_key_args}
            ].compact

            ::ActiveRemote::Cached.cache.fetch(cache_key, __active_remote_cached_options) do
              if block_given?
                yield
              else
                self.find(#{expanded_search_args})
              end
            end
          end
        RUBY

        cached_finder_options[method_name] = cached_finder_options_hash
        cached_methods << method_name
      end

      def _define_cached_search_method(method_name, *method_arguments, cached_finder_options_hash)
        method_arguments.flatten!
        expanded_method_args = method_arguments.join(',')
        expanded_cache_key_args = _expanded_cache_key_args(method_arguments)

        expanded_search_args = _expanded_search_args(method_arguments)

        class_eval <<-RUBY, __FILE__, __LINE__ + 1
          # def self.cached_search_by_user_guid(user_guid, options = {})
          #   options = ::ActiveRemote::Cached.default_options.merge({}).merge(options)
          #
          #   ::ActiveRemote::Cached.cache.fetch([namespace, name, "#search", user_guid], options) do
          #     if block_given?
          #       yield
          #     else
          #       self.search(:user_guid => user_guid)
          #     end
          #   end
          # end
          #
          # If a block is given, it is incumbent on the caller to make sure the expectation
          # of the result object is maintained for requests/responses
          #
          def self.#{method_name}(#{expanded_method_args}, __active_remote_cached_options = {})
            __active_remote_cached_options = ::ActiveRemote::Cached.default_options.merge(_cached_finder_options_for('#{method_name}')).merge(__active_remote_cached_options)
            namespace = __active_remote_cached_options.delete(:namespace)
            cache_key = [
              RUBY_AND_ACTIVE_SUPPORT_VERSION,
              namespace,
              name,
              "#search",
              #{expanded_cache_key_args}
            ].compact

            ::ActiveRemote::Cached.cache.fetch(cache_key, __active_remote_cached_options) do
              if block_given?
                yield
              else
                self.search(#{expanded_search_args})
              end
            end
          end
        RUBY

        cached_finder_options[method_name] = cached_finder_options_hash
        cached_methods << method_name
      end

      def _define_cached_search_bang_method(method_name, *method_arguments, cached_finder_options_hash)
        method_arguments.flatten!
        expanded_method_args = method_arguments.join(',')
        expanded_cache_key_args = _expanded_cache_key_args(method_arguments)

        expanded_search_args = _expanded_search_args(method_arguments)

        class_eval <<-RUBY, __FILE__, __LINE__ + 1
          # def self.cached_search_by_user_guid!(user_guid, options = {})
          #   options = ::ActiveRemote::Cached.default_options.merge({}).merge(options)
          #
          #   ::ActiveRemote::Cached.cache.fetch([namespace, name, "#search", user_guid], options) do
          #     results = []
          #
          #     if block_given?
          #       results = yield
          #     else
          #       results = self.search(:user_guid => user_guid)
          #     end
          #
          #     raise ::ActiveRemote::RemoteRecordNotFound, self if results.nil? || results.first.nil?
          #     results
          #   end
          # end
          #
          # If a block is given, it is incumbent on the caller to make sure the expectation
          # of the result object is maintained for requests/responses
          #
          def self.#{method_name}(#{expanded_method_args}, __active_remote_cached_options = {})
            __active_remote_cached_options = ::ActiveRemote::Cached.default_options.merge(_cached_finder_options_for('#{method_name}')).merge(__active_remote_cached_options)
            namespace = __active_remote_cached_options.delete(:namespace)
            cache_key = [
              RUBY_AND_ACTIVE_SUPPORT_VERSION,
              namespace,
              name,
              "#search",
              #{expanded_cache_key_args}
            ].compact

            ::ActiveRemote::Cached.cache.fetch(cache_key, __active_remote_cached_options) do
              results = []

              if block_given?
                results = yield
              else
                results = self.search(#{expanded_search_args})
              end

              raise ::ActiveRemote::RemoteRecordNotFound, self if results.nil? || results.first.nil?
              results
            end
          end
        RUBY

        cached_finder_options[method_name] = cached_finder_options_hash
        cached_methods << method_name
      end
    end

    # Initialize the cache provider with a MemoryStore cache
    cache(ActiveSupport::Cache::MemoryStore.new)
  end
end

require 'active_remote/cached/railtie' if defined?(Rails)
