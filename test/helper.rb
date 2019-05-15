# set default_env to nil
ENV.delete('RAILS_ENV')
ENV.delete('RACK_ENV')

require 'bundler/setup'
require 'maxitest/autorun'
require 'mocha/setup'
require 'webmock/minitest'
require 'byebug'
require 'cgi'
require 'i18n'
require 'recaptcha'

I18n.enforce_available_locales = false

Minitest::Test.send(:prepend, Module.new do
  def setup
    super
    Recaptcha.configure do |config|
      config.site_key = '0000000000000000000000000000000000000000'
      config.secret_key = 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
    end
  end
end)
