# frozen_string_literal: true

module ActiveRemote
  module Cached
    class ArgumentKeys
      attr_reader :arguments, :argument_string, :options

      REMOVE_CHARACTERS = /[[:space:]+=><{}\[\];:\-,]/
      REPLACE_MAP = [
        [' ', 'SP'],
        ['+', 'PL'],
        ['=', 'EQ'],
        ['>', 'GT'],
        ['<', 'LT'],
        ['{', 'LB'],
        ['}', 'RB'],
        ['[', 'LB2'],
        [']', 'RB2'],
        [';', 'SC'],
        [':', 'CO'],
        ['-', 'DA'],
        [',', 'COM']
      ].freeze

      def initialize(*arguments, options)
        @options = options
        @arguments = arguments.flatten.compact
        @argument_string = ''

        @arguments.each do |argument|
          @argument_string << argument.to_s
        end
      end

      def cache_key
        return @argument_string.gsub(REMOVE_CHARACTERS, '') if remove_characters?

        if replace_characters?
          REPLACE_MAP.each do |character, replacement|
            @argument_string.gsub!(character, replacement)
          end
        end

        @argument_string
      end

      def to_s
        cache_key
      end

      private

      def remove_characters?
        options.fetch(:active_remote_cached_remove_characters, false)
      end

      def replace_characters?
        options.fetch(:active_remote_cached_replace_characters, false)
      end
    end
  end
end
