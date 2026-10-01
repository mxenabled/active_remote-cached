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

In Rails apps, the railtie sets `:expires_in` to 5 minutes and `:race_condition_ttl` to 5 seconds. Change them with `config.active_remote_cached.expires_in` and `config.active_remote_cached.race_condition_ttl`.

`default_options` merges the given options into the current options. An initializer that adds one option keeps the railtie's TTL:

```ruby
# config/initializers/active_remote_cached.rb
ActiveRemote::Cached.default_options(:active_remote_cached_replace_characters => true)
ActiveRemote::Cached.default_options
# => { :expires_in => 5.minutes, :race_condition_ttl => 5.seconds, :active_remote_cached_replace_characters => true }
```

To replace all the options, use `default_options_overwrite`. Pass an empty hash to clear them:

```ruby
ActiveRemote::Cached.default_options_overwrite(:expires_in => 1.hour)
ActiveRemote::Cached.default_options_overwrite({})
```

Without `:expires_in`, a cached finder writes an entry that never expires.

#### Cache errors

By default, an error from the cache provider goes to the caller. To make a
cache error act as a cache miss, set `:handle_cache_error`. A cache outage then
does not stop the finders: each call goes to the remote service. This
increases the load on that service until the cache comes back.

```ruby
# config/initializers/active_remote_cached.rb
ActiveRemote::Cached.default_options(
  :handle_cache_error => true,
  :cache_error_proc => lambda { |error| Rails.logger.error(error) }
)
```

| Option | Default | Description |
|---|---|---|
| `:handle_cache_error` | not set (off) | When true, a cache error does not go to the caller. `read` and `write` return nil, `exist?` returns false, `delete` returns nil, and `fetch` calls the block without the cache. |
| `:cache_error_proc` | not set | A callable that receives the cache error. It runs only when `:handle_cache_error` is true. If the proc raises, the library writes a warning to stderr, and the call continues. |

These two options apply only in `ActiveRemote::Cached.default_options`. A value
in a finder declaration or in a finder call has no effect, and the library does
not pass it to the cache provider.

With nested caching, the nested cache and the cache provider each handle their
own errors. An error in the nested cache does not skip the cache provider.

An error from the `fetch` block (for example,
`ActiveRemote::RemoteRecordNotFound` from a bang finder, or an RPC error) always
goes to the caller, and the library never caches it. The block runs at most
once for each `fetch`.

`ActiveSupport::Cache::RedisCacheStore` already catches Redis connection errors
and sends them to its own `:error_handler`. These options also catch the errors
that the store does not catch, for example an entry that fails to deserialize.

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

## Upgrading to 1.4.0

### Cache error handling

1.4.0 adds `:handle_cache_error` and `:cache_error_proc` (see "Cache errors").
Both are off by default.

### The cleanup delete in fetch no longer raises

When `fetch` gets a nil or empty value (without `:allow_nil` or
`:allow_empty`), it deletes the entry. Before 1.4.0, an error from that delete
went to the caller, and the caller lost the value from the remote service.
In 1.4.0, `fetch` ignores that error and returns the value. The nil or empty
entry stays in the cache until its TTL ends. This applies with or without
`:handle_cache_error`.

An app on the internal `0.3.0.rc2` release can move to 1.4.0 and keep its
initializer. 1.4.0 does not add the rest of that release:

- `0.3.0.rc2` `fetch` called `read`, then `write`. 1.4.0 keeps the provider
  `fetch`, so `:race_condition_ttl` now works. Redis keeps each entry for
  5 more minutes.
- `0.3.0.rc2` passed only known options to the cache provider. 1.4.0 passes
  every option except the two error options, as 1.3.0 does.
- Every cache key changes (see "Upgrading to 1.2.0").

## Upgrading to 1.3.0

### default_options merges

Before 1.3.0, each call to `default_options` replaced the options. In a
Rails app, the railtie sets `:expires_in` and `:race_condition_ttl` before the
app initializers run. An initializer that called `default_options` with other
options removed the TTL, and every cached finder call with no `:expires_in`
wrote an entry that never expired:

```ruby
# railtie:      { :expires_in => 5.minutes, :race_condition_ttl => 5.seconds }
ActiveRemote::Cached.default_options(:active_remote_cached_replace_characters => true)
# before:       { :active_remote_cached_replace_characters => true }
# now:          { :expires_in => 5.minutes, :race_condition_ttl => 5.seconds, :active_remote_cached_replace_characters => true }
```

After the upgrade, an app like this gets a TTL again. Its finders call the
remote service more often, because entries now expire.

`default_options({})` no longer clears the options. Use
`default_options_overwrite({})`. Use `default_options_overwrite` to keep the
old replace behavior.

## Upgrading to 1.2.0

### Every cache key changes

Before 1.2.0 the cache key held only the argument values, joined with no
separator. Three different finders shared one cache entry:

```ruby
Customer.cached_find_by_name_and_email("x", "y")  # key: "xy"
Customer.cached_find_by_city_and_state("x", "y")  # key: "xy"  same entry
Customer.cached_find_by_id("xy")                  # key: "xy"  same entry
```

The key now names each field, so each finder gets its own entry:

```ruby
Customer.cached_find_by_name_and_email("x", "y")  # key: "email.y/name.x"
```

Every existing cache entry becomes a miss after the upgrade. Expect one cold
period. The gem already causes this on an ActiveSupport upgrade, through
`RUBY_AND_ACTIVE_SUPPORT_VERSION`.

### A bad call now raises

A dynamic finder called with too few arguments used to pass `nil` for the
missing field and cache the result. It now raises `ArgumentError`:

```ruby
Customer.cached_find_by_email_and_name("only_one")  # => ArgumentError
```

### The cache provider validator raises a new class

`ActiveRemote::Cached::Cache::InvalidCacheProvider` replaces the bare
`RuntimeError` that `ActiveRemote::Cached.cache` raised for a provider that is
missing a method.

## Known behavior

Two behaviors are recorded in the specs. Neither is fixed. Read
`spec/active_remote/cached_spec.rb` for the specs that describe them.

### Finder name matching is not anchored

`_method_missing_name` matches a finder name inside a longer method name. A
method named `not_cached_find_by_guid` resolves to `cached_find_by_guid`.

### A subclass has its own empty cached_methods list

A subclass inherits the finder methods its parent defined, and the options
those finders were declared with. It does not inherit the `cached_methods`
list. The parent accepts the finder arguments in any order. The subclass
accepts them only in the order the method was defined.

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
