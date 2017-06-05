module ActiveRemote::Cached
  class ArgumentKeys
    attr_reader :arguments, :argument_string, :options

    REMOVE_CHARACTERS = /[[:space:]+=><{}\[\];:\-,]/
    REPLACE_MAP = [
      [" ", "SP"],
      ["+", "PL"],
      ["=", "EQ"],
      [">", "GT"],
      ["<", "LT"],
      ["{", "LB"],
      ["}", "RB"],
      ["[", "LB2"],
      ["]", "RB2"],
      [";", "SC"],
      [":", "CO"],
      ["-", "DA"],
      [",", "COM"],
    ].freeze

    def initialize(*arguments, options)
      @options = options
      @arguments = arguments.flatten.compact
      @argument_string = ""

      @arguments.each do |argument|
        @argument_string << "#{argument}"
      end
    end

    def cache_key
      if remove_characters?
        @argument_string.gsub(REMOVE_CHARACTERS, "")
      elsif replace_characters?
        REPLACE_MAP.each do |character, replacement|
          @argument_string.gsub!(character, replacement)
        end

        @argument_string
      else
        @argument_string
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
