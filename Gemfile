source 'https://rubygems.org'
ruby '2.0.0'
gem 'rails', '4.2.4'
gem 'sass-rails', '~> 5.0'
gem 'uglifier', '>= 1.3.0'
gem 'coffee-rails', '~> 4.1.0'
gem 'jquery-rails'
gem 'turbolinks'
gem 'jbuilder', '~> 2.0'
gem 'activerecord-session_store'
## Performance Boosting Gems
gem 'ox'         # For faster XML Parsing, use Ox or Nokogiri. Ox has highest priority if available.
gem 'nokogiri'   # For faster XML Parsing. If neither Ox nor Nokogiri available, we'll fall back to REXML.
gem 'httpclient' # Absolutely necessary for soap4r-ng. Net::HTTP Fallback is quite broken, so don't let that happen.
#
gem 'soap4r-ng', :git=>'https://github.com/rubyjedi/soap4r.git', :branch=>"master"
gem 'wash_out'

group :development, :test do
  gem 'byebug'
end
group :development do
  gem 'web-console', '~> 2.0'
  gem 'spring'
end
gem 'bootstrap-sass'
gem 'devise'
gem 'high_voltage'
gem 'pg'
gem 'thin'
gem 'savon', '~> 2.0'
group :development do
  gem 'better_errors'
  gem 'binding_of_caller', :platforms=>[:mri_20]
  gem 'hub', :require=>nil
  gem 'quiet_assets'
  gem 'rails_layout'
end
