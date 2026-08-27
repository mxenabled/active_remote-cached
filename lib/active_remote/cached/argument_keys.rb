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

      # The separators below are absent from both REMOVE_CHARACTERS and
      # REPLACE_MAP, so they survive either option. escape_value/1 escapes them
      # inside a value, which makes the key one-to-one with the arguments.
      FIELD_SEPARATOR = '.'
      PAIR_SEPARATOR = '/'
      ESCAPE_MAP = { '%' => '%25', FIELD_SEPARATOR => '%2E', PAIR_SEPARATOR => '%2F' }.freeze
      ESCAPE_CHARACTERS = %r{[%./]}

      # Build a key that names each field, so that two finders with the same
      # values do not share one cache entry.
      #
      #   for_fields([:alpha, :beta], ['x', 'y'], {}).cache_key
      #   # => "alpha.x/beta.y"
      #
      def self.for_fields(field_names, values, options)
        pairs = field_names.each_with_index.map do |field_name, index|
          "#{field_name}#{FIELD_SEPARATOR}#{normalize_value(values[index])}"
        end

        new(pairs.join(PAIR_SEPARATOR), options)
      end

      def self.normalize_value(value)
        [value].flatten.compact.map { |element| escape_value(element) }.join(FIELD_SEPARATOR)
      end
      private_class_method :normalize_value

      def self.escape_value(value)
        value.to_s.gsub(ESCAPE_CHARACTERS, ESCAPE_MAP)
      end
      private_class_method :escape_value

      def initialize(*arguments, options)
        @options = options
        @arguments = arguments.flatten.compact
        @argument_string = @arguments.join
      end

      def cache_key
        return @argument_string.gsub(REMOVE_CHARACTERS, '') if remove_characters?
        return @argument_string unless replace_characters?

        REPLACE_MAP.inject(@argument_string) do |key, (character, replacement)|
          key.gsub(character, replacement)
        end
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
