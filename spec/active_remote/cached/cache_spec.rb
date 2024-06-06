# frozen_string_literal: true

require 'spec_helper'

describe ::ActiveRemote::Cached::Cache do
  describe 'API' do
    it 'validates #delete present' do
      cache = OpenStruct.new(:write => nil, :fetch => nil, :read => nil, :exist? => nil)
      expect { ::ActiveRemote::Cached.cache(cache) }.to raise_error(RuntimeError, /respond_to.*delete/i)
    end

    it 'validates #exist? present' do
      cache = OpenStruct.new(:write => nil, :delete => nil, :read => nil, :fetch => nil)
      expect { ::ActiveRemote::Cached.cache(cache) }.to raise_error(RuntimeError, /respond_to.*exist/i)
    end

    it 'validates #fetch present' do
      cache = OpenStruct.new(:write => nil, :delete => nil, :read => nil, :exist? => nil)
      expect { ::ActiveRemote::Cached.cache(cache) }.to raise_error(RuntimeError, /respond_to.*fetch/i)
    end

    it 'validates #read present' do
      cache = OpenStruct.new(:write => nil, :delete => nil, :fetch => nil, :exist? => nil)
      expect { ::ActiveRemote::Cached.cache(cache) }.to raise_error(RuntimeError, /respond_to.*read/i)
    end

    it 'validates #write present' do
      cache = OpenStruct.new(:read => nil, :delete => nil, :fetch => nil, :exist? => nil)
      expect { ::ActiveRemote::Cached.cache(cache) }.to raise_error(RuntimeError, /respond_to.*write/i)
    end
  end
end
