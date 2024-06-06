# frozen_string_literal: true

require 'rubygems'
require 'bundler'
Bundler.require(:default, :development, :test)

class HashCache < Hash
  def exist?(key)
    key?(key)
  end

  def fetch(key, _options = {})
    return self[key] if key?(key)

    self[key] = yield
  end

  def read(key)
    self[key]
  end

  def write(key, value)
    self[key] = value
  end
end

require 'mocha/api'
