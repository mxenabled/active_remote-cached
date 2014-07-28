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

### Defining cache finders

Include `::ActiveRemote::Cached` into your ActiveRemote models that can support cached finders*

```Ruby
class Customer < ::ActiveRemote::Base
  include ::ActiveRemote::Cached
end
```

_*This is already done for you in Rails_

Then declare some cache finder methods. Cached finders can be defined for individual fields or defined as composites for mulitple fields

```Ruby
class Customer < ::ActiveRemote::Base
  # Create a cached finder for id
  cached_finders_for :id

  # Create a composite cached finder for name and email
  cached_finders_for [:name, :email]
end
```

Now that you have a model that has cached finders on it you can use the `cached_search`, `cached_find`, or dynamic cached finder methods on the model to use the cache before you issue the AR search/find method.

```Ruby
customer = ::Customer.cached_find_by_id(1) # => <Customer id=1>
customer = ::Customer.cached_find(:id => 1) # => <Customer id=1>
customer = ::Customer.cached_search_by_id(1) # => [ <Customer id=1> ]
customer = ::Customer.cached_search(:id => 1) # => [ <Customer id=1> ]
```

```Ruby
# All permutations of "complex" dynamic finders are defined
customer = ::Customer.cached_find_by_name_and_email("name", "email") # => <Customer id=1>
customer = ::Customer.cached_find_by_email_and_name("email", "name") # => <Customer id=1>

# Only declared finders are defined
customer = ::Customer.cached_find_by_name("name") # => NoMethodError
```

### Configuring the cache provider

ActiveRemote::Cached relies on an ActiveSupport::Cache-compatible cache provider. The cache is initialized with a simple memory store (defaults to 32MB), but can be overridden via `ActiveRemote::Cached.cache`:

```Ruby
ActiveRemote::Cached.cache(Your::ActiveSupport::Cache::Compatible::Provider.new)
```

In Rails apps, the memory store is replaced the whatever Rails is using as it's cache store.

#### Default options

The default cache options used when interacting with the cache can be specified via `ActiveRemote::Cached.default_options`:

```Ruby
ActiveRemote::Cached.default_options(:expires_in => 1.hour)
```

In Rails apps, the :race_condition_ttl option defaults to 5 seconds.

#### Local overrides

Each finder as takes an optional options hash that will override the options passed to the caching provider (override from the global defaults setup for ActiveRemote::Cached)

```Ruby
customer = ::Customer.cached_find_by_id(1, :expires_in => 15.minutes)
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
