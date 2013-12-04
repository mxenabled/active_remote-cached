# ActiveRemote::Cached

Provides cached finders for ActiveRemote models that allow a caching provider to cache the result of a query.

## Installation

Add this line to your application's Gemfile:

    gem 'active_remote-cached'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install active_remote-cached

## Usage

include `::ActiveRemote::Cached` into your ActiveRemote models that can support cached finders

```ruby
  class Customer < ::ActiveRemote::Base
    include ::ActiveRemote::Cached

    # Declare the cached finder methods that will be supported
    cached_finders_for :id
    cached_finders_for [:name, :email]
  end
```

Now that you have a model that has cached finders on it you can use the `cached_search`, `cached_find`, or dynamic cached finder methods on the model to use the cache before you issue the AR search/find method.

```ruby
  customer = ::Customer.cached_find_by_id(1) # => <Customer id=1>
  customer = ::Customer.cached_find(:id => 1) # => <Customer id=1>
  customer = ::Customer.cached_search_by_id(1) # => [ <Customer id=1> ]
  customer = ::Customer.cached_search(:id => 1) # => [ <Customer id=1> ]
```

```ruby
  # All permutations of "complex" dynamic finders are defined
  customer = ::Customer.cached_find_by_name_and_email("name", "email") # => <Customer id=1>
  customer = ::Customer.cached_find_by_email_and_name("email", "name") # => <Customer id=1>

  # Only declared finders are defined
  customer = ::Customer.cached_find_by_name("name") # => NoMethodError
```

Each finder as takes an optional options hash that will override the options passed to the caching provider (override from the global defaults setup for ActiveRemote::Cached)

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
