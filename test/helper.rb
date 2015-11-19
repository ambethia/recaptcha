require 'bundler/setup'
require 'maxitest/autorun'
require 'mocha/setup'
require 'cgi'
require 'recaptcha'

Minitest::Test.send(:prepend, Module.new do
  def setup
    super
    Recaptcha.configure do |config|
      config.public_key = '0000000000000000000000000000000000000000'
      config.private_key = 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
      config.use_ssl_by_default = Recaptcha::USE_SSL_BY_DEFAULT
      config.api_version = Recaptcha::RECAPTCHA_API_VERSION
    end
  end
end)
