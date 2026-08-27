# ActiveRemote::Cached

[![CI](https://github.com/skunkworker/active_remote-cached/actions/workflows/ci.yml/badge.svg)](https://github.com/skunkworker/active_remote-cached/actions/workflows/ci.yml)

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

```ruby
class Customer < ::ActiveRemote::Base
  include ::ActiveRemote::Cached
end
```

_*This is already done for you in Rails_

Then declare some cache finder methods. Cached finders can be defined for individual fields or defined as composites for mulitple fields

```ruby
class Customer < ::ActiveRemote::Base
  # Create a cached finder for id
  cached_finders_for :id

  # Create a composite cached finder for name and email
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

### Configuring the cache provider

ActiveRemote::Cached relies on an ActiveSupport::Cache-compatible cache provider. The cache is initialized with a simple memory store (defaults to 32MB), but can be overridden via `ActiveRemote::Cached.cache`:

```ruby
ActiveRemote::Cached.cache(Your::ActiveSupport::Cache::Compatible::Provider.new)
```

In Rails apps, the memory store is replaced the whatever Rails is using as it's cache store.

#### Default options

The default cache options used when interacting with the cache can be specified via `ActiveRemote::Cached.default_options`:

```ruby
ActiveRemote::Cached.default_options(:expires_in => 1.hour)
```

In Rails apps, the :race_condition_ttl option defaults to 5 seconds.

#### Local overrides

Each finder as takes an optional options hash that will override the options passed to the caching provider (override from the global defaults setup for ActiveRemote::Cached)

```ruby
customer = ::Customer.cached_find_by_id(1, :expires_in => 15.minutes)
```

## Development

Install the dependencies:

```shell
bundle install
```

Run the specs against the default gemfile:

```shell
bundle exec rspec
```

Run RuboCop:

```shell
bundle exec rubocop
```

### Test matrix

This gem uses [appraisal](https://github.com/thoughtbot/appraisal) to test against
several `active_remote` versions. The `Appraisals` file defines each version.

Generate the gemfiles. They are not committed:

```shell
bundle exec appraisal generate
```

Install every appraisal:

```shell
bundle exec appraisal install
```

Run the specs against every appraisal:

```shell
bundle exec appraisal rspec
```

Run the specs against one appraisal:

```shell
bundle exec appraisal active_remote-8.0 rspec
```

Remove the generated gemfiles:

```shell
bundle exec appraisal clean
```

CI runs this matrix on Ruby 3.1, Ruby 3.4, JRuby 9.4, and JRuby 10.0.
`active_remote` 8.0 requires Ruby 3.2 or later. CI does not run that
version on Ruby 3.1 or JRuby 9.4.

## Known behavior

Two behaviors are recorded in the specs. Neither is fixed. Read
`spec/active_remote/cached_spec.rb` for the specs that describe them.

### Finder name matching is not anchored

`_method_missing_name` matches a finder name inside a longer method name. A
method named `not_cached_find_by_guid` resolves to `cached_find_by_guid`.

### A subclass has its own empty cached_methods list

A subclass inherits the finder methods its parent defined. It does not inherit
the `cached_methods` list. The parent accepts the finder arguments in any
order. The subclass accepts them only in the order the method was defined.

```ruby
Parent.cached_find_by_beta_and_alpha('B', 'A')  # works
Child.cached_find_by_beta_and_alpha('B', 'A')   # raises NoMethodError
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
