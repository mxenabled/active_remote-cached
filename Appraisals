# frozen_string_literal: true

appraise 'active_remote-6.1' do
  gem 'active_remote', '~> 6.1.0'
  # activesupport 6.1 is not compatible with concurrent-ruby 1.3.5 and later
  gem 'concurrent-ruby', '< 1.3.5'
  # ruby 3.4 removed these from the default gems, activesupport 6.1 still needs them
  gem 'base64'
  gem 'bigdecimal'
  gem 'mutex_m'
end

appraise 'active_remote-7.0' do
  gem 'active_remote', '~> 7.0.0'
end

appraise 'active_remote-7.1' do
  gem 'active_remote', '~> 7.1.0'
end

appraise 'active_remote-7.2' do
  gem 'active_remote', '~> 7.2.0'
end

appraise 'active_remote-8.0' do
  gem 'active_remote', '~> 8.0.0'
end
