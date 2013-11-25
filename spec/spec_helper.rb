require 'rubygems'
require 'bundler'
Bundler.require(:default, :development, :test)

require 'minitest/spec'
require 'minitest/autorun'
require 'minitest/pride'

class HashCache < Hash
  def read(key)
    [key]
  end

  def write(key, value)
    [key] = value
  end
end
