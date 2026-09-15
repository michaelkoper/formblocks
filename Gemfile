# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

# json 3.0 takes JSON.parse options as keywords only; Rails 8.1's
# ActiveSupport::JSON.decode still passes a hash, so every JSON column read
# would raise. Rails itself pins json < 3 (rails/rails#58683). Development
# only — the gemspec leaves it to the host.
gem 'json', '< 3'

group :development, :test do
  gem 'capybara'
  gem 'cgi' # Capybara still requires it; Ruby 4.0 dropped it from the default gems
  gem 'debug'
  gem 'puma'
  gem 'rack-test'
  gem 'rubocop', '~> 1.91.0', require: false
  gem 'rubocop-minitest', require: false
  gem 'rubocop-rails', require: false
  gem 'selenium-webdriver'
  gem 'sqlite3'
end
