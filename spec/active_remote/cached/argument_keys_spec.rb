# frozen_string_literal: true

require 'spec_helper'

describe ::ActiveRemote::Cached::ArgumentKeys do
  it 'does not mutate a string by default' do
    expect(::ActiveRemote::Cached::ArgumentKeys.new('hello', {}).cache_key).to eq('hello')
  end

  it 'returns a string of a symbol by default' do
    expect(::ActiveRemote::Cached::ArgumentKeys.new(:hello, {}).cache_key).to eq('hello')
  end

  it 'does not mutate a string with special characters by default' do
    expect(::ActiveRemote::Cached::ArgumentKeys.new('hello {}', {}).cache_key).to eq('hello {}')
  end

  it 'removes special characters from string with special characters when :active_remote_cached_remove_characters' do
    options = { :active_remote_cached_remove_characters => true }
    expect(::ActiveRemote::Cached::ArgumentKeys.new('hello {}', options).cache_key).to eq('hello')
  end

  it 'replaces special characters from string with special characters when :active_remote_cached_replace_characters' do
    options = { :active_remote_cached_replace_characters => true }
    expect(::ActiveRemote::Cached::ArgumentKeys.new('hello {}', options).cache_key).to eq('helloSPLBRB')
  end

  it 'joins multiple arguments into one key' do
    expect(::ActiveRemote::Cached::ArgumentKeys.new('hello', 'world', {}).cache_key).to eq('helloworld')
  end

  it 'removes nil arguments from the key' do
    expect(::ActiveRemote::Cached::ArgumentKeys.new('hello', nil, 'world', {}).cache_key).to eq('helloworld')
  end

  it 'flattens nested array arguments into the key' do
    expect(::ActiveRemote::Cached::ArgumentKeys.new(['hello', ['world']], {}).cache_key).to eq('helloworld')
  end

  it 'returns an empty key when no arguments are given' do
    expect(::ActiveRemote::Cached::ArgumentKeys.new({}).cache_key).to eq('')
  end

  it 'returns the cache key from #to_s' do
    expect(::ActiveRemote::Cached::ArgumentKeys.new('hello', {}).to_s).to eq('hello')
  end

  it 'removes characters when both the remove and the replace option are given' do
    options = {
      :active_remote_cached_remove_characters => true,
      :active_remote_cached_replace_characters => true
    }
    expect(::ActiveRemote::Cached::ArgumentKeys.new('hello {}', options).cache_key).to eq('hello')
  end

  describe '.for_fields' do
    it 'names each field in the key' do
      argument_keys = ::ActiveRemote::Cached::ArgumentKeys.for_fields(%i[alpha beta], %w[x y], {})

      expect(argument_keys.cache_key).to eq('alpha.x/beta.y')
    end

    it 'gives two finders with the same values two different keys' do
      alpha_beta = ::ActiveRemote::Cached::ArgumentKeys.for_fields(%i[alpha beta], %w[x y], {})
      gamma_delta = ::ActiveRemote::Cached::ArgumentKeys.for_fields(%i[gamma delta], %w[x y], {})

      expect(alpha_beta.cache_key).not_to eq(gamma_delta.cache_key)
    end

    it 'gives a single field a different key than two fields with the same characters' do
      one_field = ::ActiveRemote::Cached::ArgumentKeys.for_fields(%i[guid], %w[xy], {})
      two_fields = ::ActiveRemote::Cached::ArgumentKeys.for_fields(%i[alpha beta], %w[x y], {})

      expect(one_field.cache_key).not_to eq(two_fields.cache_key)
    end

    it 'joins an array value with a comma' do
      argument_keys = ::ActiveRemote::Cached::ArgumentKeys.for_fields(%i[guid], [%w[a b]], {})

      expect(argument_keys.cache_key).to eq('guid.a.b')
    end

    it 'removes a nil inside an array value' do
      argument_keys = ::ActiveRemote::Cached::ArgumentKeys.for_fields(%i[guid], [['a', nil, 'b']], {})

      expect(argument_keys.cache_key).to eq('guid.a.b')
    end

    it 'gives an empty value for a nil argument' do
      argument_keys = ::ActiveRemote::Cached::ArgumentKeys.for_fields(%i[alpha beta], ['x', nil], {})

      expect(argument_keys.cache_key).to eq('alpha.x/beta.')
    end

    it 'escapes a separator inside a value' do
      argument_keys = ::ActiveRemote::Cached::ArgumentKeys.for_fields(%i[guid], ['a/b.c%d'], {})

      expect(argument_keys.cache_key).to eq('guid.a%2Fb%2Ec%25d')
    end

    it 'keeps the separators when the remove option is given' do
      options = { :active_remote_cached_remove_characters => true }
      argument_keys = ::ActiveRemote::Cached::ArgumentKeys.for_fields(%i[alpha beta], ['hello {}', 'y'], options)

      expect(argument_keys.cache_key).to eq('alpha.hello/beta.y')
    end

    it 'keeps the separators when the replace option is given' do
      options = { :active_remote_cached_replace_characters => true }
      argument_keys = ::ActiveRemote::Cached::ArgumentKeys.for_fields(%i[alpha beta], ['hello {}', 'y'], options)

      expect(argument_keys.cache_key).to eq('alpha.helloSPLBRB/beta.y')
    end
  end

  # #cache_key calls gsub! on an instance variable, so a second call must not
  # replace the characters of the first result again.
  it 'returns the same key when :active_remote_cached_replace_characters is called twice' do
    options = { :active_remote_cached_replace_characters => true }
    argument_keys = ::ActiveRemote::Cached::ArgumentKeys.new('hello {}', options)

    expect(argument_keys.cache_key).to eq('helloSPLBRB')
    expect(argument_keys.cache_key).to eq('helloSPLBRB')
  end
end
