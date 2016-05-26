require 'bundler/setup'
require 'maxitest/autorun'
require 'mocha/setup'
require 'webmock/minitest'
require 'cgi'
require 'recaptcha'
require 'i18n'

ENV.delete('RAILS_ENV')
ENV.delete('RACK_ENV')

I18n.enforce_available_locales = false

Minitest::Test.send(:prepend, Module.new do
  def setup
    super
    Recaptcha.configure do |config|
      config.public_key = '0000000000000000000000000000000000000000'
      config.private_key = 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
    end
  end
end)
